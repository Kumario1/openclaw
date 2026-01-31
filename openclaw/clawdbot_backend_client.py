"""
Backend API Client for Clawdbot (EC2)

This module allows Clawdbot running on EC2 to communicate with the
Transition OS backend. It provides a clean interface for all backend operations.
"""

import os
import logging
from typing import Any, Dict, List, Optional
import httpx

logger = logging.getLogger(__name__)


class TransitionOSClient:
    """
    Client for interacting with the Transition OS backend API.
    This is used by Clawdbot to read/write data through the backend (not directly to DB).
    """

    def __init__(self, base_url: Optional[str] = None, api_key: Optional[str] = None):
        """
        Initialize the client.
        
        Args:
            base_url: The backend API URL (e.g., "http://localhost:8000" or "http://54.221.139.68:8000")
            api_key: Optional API key for authentication
        """
        self.base_url = base_url or os.getenv("BACKEND_URL", "http://localhost:8000")
        self.api_key = api_key or os.getenv("BACKEND_API_KEY")
        self.api_v1 = f"{self.base_url}/api"
        
        logger.info(f"TransitionOSClient initialized with backend: {self.base_url}")

    def _headers(self) -> Dict[str, str]:
        """Get request headers."""
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers

    # ==================== Workflows ====================

    async def create_workflow(self, workflow_type: str, advisor_id: str, metadata: Optional[Dict] = None) -> Dict:
        """Create a new workflow for an advisor."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/workflows",
                json={"workflow_type": workflow_type, "advisor_id": advisor_id, "metadata": metadata or {}},
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    async def get_workflow(self, workflow_id: str) -> Dict:
        """Get workflow dashboard/status."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/workflows/{workflow_id}",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Households / Transitions ====================

    async def list_households(
        self, advisor_id: Optional[str] = None, status: Optional[str] = None
    ) -> List[Dict]:
        """List all households (transitions) with optional filters."""
        params = {}
        if advisor_id:
            params["advisor_id"] = advisor_id
        if status:
            params["status"] = status

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.api_v1}/transitions",
                params=params,
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    async def get_household(self, household_id: int) -> Dict:
        """Get detailed information about a specific household."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.api_v1}/transitions/{household_id}",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Tasks ====================

    async def complete_task(self, task_id: int, note: Optional[str] = None) -> Dict:
        """Mark a task as completed."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_v1}/tasks/{task_id}/complete",
                json={"status": "COMPLETED", "note": note},
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Documents ====================

    async def validate_document(self, document_id: str, document_url: Optional[str] = None) -> Dict:
        """Validate a document for NIGO issues."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/documents/validate",
                json={"document_id": document_id, "document_url": document_url},
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Predictions ====================

    async def get_eta_prediction(self, workflow_id: str) -> Dict:
        """Get ETA prediction for a workflow."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/predictions/eta/{workflow_id}",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Entity Resolution ====================

    async def run_entity_match(self, source_data: Dict) -> Dict:
        """Run entity resolution on source data."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/entity/match",
                json=source_data,
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Communications ====================

    async def draft_communication(
        self, template_type: str, recipient: str, context: Dict
    ) -> Dict:
        """Draft a communication message."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/communications/draft",
                json={
                    "template_type": template_type,
                    "recipient": recipient,
                    "context": context,
                },
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()

    # ==================== Meeting Pack ====================

    async def get_meeting_pack(self, household_id: int) -> Dict:
        """Generate a meeting pack for a household."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/households/{household_id}/meeting-pack",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()


# Singleton instance for easy import
backend_client = TransitionOSClient()
