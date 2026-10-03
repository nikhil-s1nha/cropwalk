import os
import tempfile
from pathlib import Path

import pytest

# Keep `import app.main` (which builds the default app) away from backend/data during tests.
os.environ.setdefault("ONDERA_DB", str(Path(tempfile.mkdtemp()) / "import.db"))

from fastapi.testclient import TestClient  # noqa: E402

from app.main import create_app  # noqa: E402


@pytest.fixture
def client(tmp_path):
    return TestClient(create_app(tmp_path / "test.db"))
