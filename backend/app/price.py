"""Price endpoint — owned by workstream C (Task 25). Stub until then."""
from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter()


@router.get("/price/latest")
def price_latest():
    return JSONResponse(status_code=501, content={"detail": "not implemented — task 25"})
