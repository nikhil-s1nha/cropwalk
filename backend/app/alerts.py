"""Cooperative alerts — owned by workstream D (Task 27, stretch). Stub until then."""
from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter()


@router.get("/alerts")
def alerts():
    return JSONResponse(status_code=501, content={"detail": "not implemented — task 27"})
