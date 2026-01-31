#!/usr/bin/env python3
"""
Backend API Client for OpenClaw Integration

This script allows OpenClaw to call the Transition OS backend API.
Usage from OpenClaw: backend_client.py <command> [args]

Environment:
    BACKEND_URL: The backend API URL (default: http://localhost:8000)
    BACKEND_API_KEY: Optional API key for authentication
"""

import os
import sys
import json
import httpx

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")
API_KEY = os.getenv("BACKEND_API_KEY")


class TransitionOSClient:
    """Client for Transition OS Backend API"""
    
    def __init__(self, base_url: str = None, api_key: str = None):
        self.base_url = base_url or BACKEND_URL
        self.api_key = api_key or API_KEY
        self.api_v1 = f"{self.base_url}/api"
    
    def _headers(self) -> dict:
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers
    
    def list_households(self, advisor_id: str = None, status: str = None):
        """GET /api/transitions"""
        params = {}
        if advisor_id:
            params["advisor_id"] = advisor_id
        if status:
            params["status"] = status
        
        response = httpx.get(f"{self.api_v1}/transitions", params=params, headers=self._headers())
        response.raise_for_status()
        return response.json()
    
    def get_household(self, household_id: int):
        """GET /api/transitions/{id}"""
        response = httpx.get(f"{self.api_v1}/transitions/{household_id}", headers=self._headers())
        response.raise_for_status()
        return response.json()
    
    def complete_task(self, task_id: int, note: str = None):
        """POST /api/tasks/{id}/complete"""
        data = {"status": "COMPLETED"}
        if note:
            data["note"] = note
        
        response = httpx.post(
            f"{self.api_v1}/tasks/{task_id}/complete",
            json=data,
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()
    
    def validate_document(self, document_id: str, document_url: str = None):
        """POST /documents/validate"""
        data = {"document_id": document_id}
        if document_url:
            data["document_url"] = document_url
        
        response = httpx.post(f"{self.base_url}/documents/validate", json=data, headers=self._headers())
        response.raise_for_status()
        return response.json()
    
    def get_meeting_pack(self, household_id: int):
        """GET /households/{id}/meeting-pack"""
        response = httpx.get(f"{self.base_url}/households/{household_id}/meeting-pack", headers=self._headers())
        response.raise_for_status()
        return response.json()
    
    def get_eta(self, workflow_id: str):
        """GET /predictions/eta/{workflow_id}"""
        response = httpx.get(f"{self.base_url}/predictions/eta/{workflow_id}", headers=self._headers())
        response.raise_for_status()
        return response.json()


def main():
    """CLI interface"""
    if len(sys.argv) < 2:
        print("Usage: backend_client.py <command> [args]")
        print("")
        print("Commands:")
        print("  list [advisor_id] [status]   List households")
        print("  get <household_id>           Get household details")
        print("  complete <task_id> [note]    Complete a task")
        print("  validate <doc_id> [url]      Validate document")
        print("  meeting <household_id>       Get meeting pack")
        print("  eta <workflow_id>            Get ETA prediction")
        print("")
        print(f"Backend URL: {BACKEND_URL}")
        sys.exit(1)
    
    client = TransitionOSClient()
    command = sys.argv[1]
    
    try:
        if command == "list":
            advisor_id = sys.argv[2] if len(sys.argv) > 2 else None
            status = sys.argv[3] if len(sys.argv) > 3 else None
            result = client.list_households(advisor_id, status)
        
        elif command == "get":
            if len(sys.argv) < 3:
                print("Error: household_id required")
                sys.exit(1)
            result = client.get_household(int(sys.argv[2]))
        
        elif command == "complete":
            if len(sys.argv) < 3:
                print("Error: task_id required")
                sys.exit(1)
            note = sys.argv[3] if len(sys.argv) > 3 else None
            result = client.complete_task(int(sys.argv[2]), note)
        
        elif command == "validate":
            if len(sys.argv) < 3:
                print("Error: document_id required")
                sys.exit(1)
            doc_url = sys.argv[3] if len(sys.argv) > 3 else None
            result = client.validate_document(sys.argv[2], doc_url)
        
        elif command == "meeting":
            if len(sys.argv) < 3:
                print("Error: household_id required")
                sys.exit(1)
            result = client.get_meeting_pack(int(sys.argv[2]))
        
        elif command == "eta":
            if len(sys.argv) < 3:
                print("Error: workflow_id required")
                sys.exit(1)
            result = client.get_eta(sys.argv[2])
        
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
        
        print(json.dumps(result, indent=2, default=str))
    
    except httpx.HTTPError as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
