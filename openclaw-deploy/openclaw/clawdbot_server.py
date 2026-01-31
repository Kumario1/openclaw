"""
Clawdbot Server (EC2)

This FastAPI server runs alongside OpenClaw on EC2.
It provides endpoints for the frontend to communicate with Clawdbot,
which then uses the backend API to access the database.

Architecture:
    Frontend → Clawdbot Server (EC2) → Backend API → Database
"""

import os
import sys
import logging
from typing import Any, Dict, Optional
from contextlib import asynccontextmanager

# Add parent directory to path to import backend modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Import the backend client
from openclaw.clawdbot_backend_client import TransitionOSClient, backend_client

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ==================== Pydantic Models ====================

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = "default"
    user_id: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class ChatResponse(BaseModel):
    response: str
    session_id: str
    actions_taken: list[str] = []
    data: Optional[Dict] = None


class WorkflowCreateRequest(BaseModel):
    workflow_type: str
    advisor_id: str
    metadata: Optional[Dict] = None


class TaskCompleteRequest(BaseModel):
    task_id: int
    note: Optional[str] = None


class QueryRequest(BaseModel):
    query_type: str  # "households", "tasks", "documents", "dashboard"
    filters: Optional[Dict] = None


# ==================== FastAPI App ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    logger.info("Starting Clawdbot Server on EC2...")
    logger.info(f"Backend URL: {backend_client.base_url}")
    yield
    logger.info("Shutting down Clawdbot Server...")


app = FastAPI(
    title="Clawdbot Server (EC2)",
    description="AI Assistant for Transition OS - runs on EC2",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS - Allow frontend to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== Health & Status ====================

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "clawdbot-server",
        "backend_connected": backend_client.base_url,
    }


# ==================== Chat / Natural Language Interface ====================

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint for the frontend.
    Processes natural language requests and interacts with the backend.
    """
    message = request.message.lower()
    actions = []
    data = None
    response_text = ""

    try:
        # Intent detection and routing
        if "what's left" in message or "status" in message or "dashboard" in message:
            # Get dashboard/overview
            households = await backend_client.list_households()
            data = {"households": households}
            response_text = format_dashboard_response(households)
            actions.append("listed_households")

        elif "household" in message or "client" in message:
            # Try to extract household ID or name
            # For now, list all households
            households = await backend_client.list_households()
            data = {"households": households}
            response_text = format_households_list(households)
            actions.append("listed_households")

        elif "complete" in message or "done" in message and "task" in message:
            # Task completion would need task ID extraction
            response_text = "To complete a task, please provide the task ID or use the /tasks/complete endpoint."
            actions.append("requested_task_id")

        elif "document" in message or "validate" in message:
            response_text = "I can validate documents for NIGO issues. Please provide the document ID."
            actions.append("ready_to_validate_document")

        elif "meeting" in message or "pack" in message:
            response_text = "I can prepare a meeting pack. Which household/client is the meeting for?"
            actions.append("requested_household_for_meeting")

        elif "eta" in message or "when" in message or "timeline" in message:
            response_text = "I can predict completion times. Which workflow are you asking about?"
            actions.append("requested_workflow_for_eta")

        else:
            response_text = (
                "I'm Clawdbot, your Transition OS assistant. I can help you with:\n"
                "• View dashboard and status\n"
                "• List households and clients\n"
                "• Complete tasks\n"
                "• Validate documents\n"
                "• Generate meeting packs\n"
                "• Check ETAs and predictions\n\n"
                "What would you like to do?"
            )
            actions.append("provided_help")

        return ChatResponse(
            response=response_text,
            session_id=request.session_id,
            actions_taken=actions,
            data=data,
        )

    except Exception as e:
        logger.error(f"Error processing chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Direct API Endpoints ====================

@app.post("/workflows/create")
async def create_workflow(request: WorkflowCreateRequest):
    """Create a new workflow."""
    result = await backend_client.create_workflow(
        workflow_type=request.workflow_type,
        advisor_id=request.advisor_id,
        metadata=request.metadata,
    )
    return result


@app.get("/workflows/{workflow_id}")
async def get_workflow(workflow_id: str):
    """Get workflow details."""
    return await backend_client.get_workflow(workflow_id)


@app.get("/households")
async def list_households(advisor_id: Optional[str] = None, status: Optional[str] = None):
    """List all households."""
    return await backend_client.list_households(advisor_id=advisor_id, status=status)


@app.get("/households/{household_id}")
async def get_household(household_id: int):
    """Get household details."""
    return await backend_client.get_household(household_id)


@app.post("/tasks/{task_id}/complete")
async def complete_task(task_id: int, request: TaskCompleteRequest):
    """Complete a task."""
    return await backend_client.complete_task(task_id=task_id, note=request.note)


@app.post("/documents/validate")
async def validate_document(payload: Dict):
    """Validate a document."""
    return await backend_client.validate_document(
        document_id=payload.get("document_id"),
        document_url=payload.get("document_url"),
    )


@app.get("/households/{household_id}/meeting-pack")
async def get_meeting_pack(household_id: int):
    """Generate meeting pack."""
    return await backend_client.get_meeting_pack(household_id)


@app.get("/predictions/eta/{workflow_id}")
async def get_eta(workflow_id: str):
    """Get ETA prediction."""
    return await backend_client.get_eta_prediction(workflow_id)


# ==================== Helper Functions ====================

def format_dashboard_response(households: list) -> str:
    """Format dashboard data as a readable response."""
    total = len(households)
    at_risk = sum(1 for h in households if h.get("status") == "AT_RISK")
    in_progress = sum(1 for h in households if h.get("status") == "IN_PROGRESS")
    
    total_tasks = sum(h.get("open_tasks_count", 0) for h in households)
    total_nigo = sum(h.get("nigo_issues_count", 0) for h in households)

    return (
        f"📊 Transition OS Dashboard\n\n"
        f"Total Households: {total}\n"
        f"  • In Progress: {in_progress}\n"
        f"  • At Risk: {at_risk}\n\n"
        f"Open Tasks: {total_tasks}\n"
        f"NIGO Issues: {total_nigo}\n\n"
        f"Use /households to see the full list."
    )


def format_households_list(households: list) -> str:
    """Format households list as a readable response."""
    if not households:
        return "No households found."

    lines = ["🏠 Households:\n"]
    for h in households[:10]:  # Limit to 10
        status_icon = "🔴" if h.get("status") == "AT_RISK" else "🟢"
        lines.append(
            f"{status_icon} {h.get('name')} (ID: {h.get('id')})\n"
            f"   Advisor: {h.get('advisor_name')} | Tasks: {h.get('open_tasks_count')} | NIGO: {h.get('nigo_issues_count')}\n"
        )
    
    if len(households) > 10:
        lines.append(f"\n... and {len(households) - 10} more")

    return "\n".join(lines)


# ==================== Main ====================

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("CLAWDBOT_PORT", "8080"))
    host = os.getenv("CLAWDBOT_HOST", "0.0.0.0")
    
    print(f"""
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   🤖 Clawdbot Server (EC2)                                ║
    ║                                                           ║
    ║   Backend: {backend_client.base_url:<45} ║
    ║   Port:    {port:<45} ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """)
    
    uvicorn.run(app, host=host, port=port)
