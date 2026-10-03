"""SQLite storage for received SMS (stdlib sqlite3, one connection per call)."""
from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_DB = Path(__file__).resolve().parent.parent / "data" / "ondera.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_message_id TEXT UNIQUE,
    recipient TEXT NOT NULL,
    body TEXT NOT NULL,
    received_at TEXT NOT NULL,
    synthetic INTEGER NOT NULL DEFAULT 0
);
"""


def db_path() -> Path:
    return Path(os.environ.get("ONDERA_DB", DEFAULT_DB))


@contextmanager
def connect(path: Path | None = None):
    path = Path(path or db_path())
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db(path: Path | None = None) -> None:
    with connect(path) as conn:
        conn.executescript(SCHEMA)


def insert_message(recipient: str, body: str, client_message_id: str | None = None,
                   synthetic: bool = False, path: Path | None = None) -> tuple[dict, bool]:
    """Insert a message. Returns (row, created). A repeated client_message_id returns the
    existing row with created=False, so outbox retries are idempotent."""
    with connect(path) as conn:
        if client_message_id:
            row = conn.execute(
                "SELECT * FROM messages WHERE client_message_id = ?", (client_message_id,)
            ).fetchone()
            if row:
                return dict(row), False
        received_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
        cur = conn.execute(
            "INSERT INTO messages (client_message_id, recipient, body, received_at, synthetic)"
            " VALUES (?, ?, ?, ?, ?)",
            (client_message_id, recipient, body, received_at, int(synthetic)),
        )
        row = conn.execute("SELECT * FROM messages WHERE id = ?", (cur.lastrowid,)).fetchone()
        return dict(row), True


def list_messages(path: Path | None = None) -> list[dict]:
    with connect(path) as conn:
        rows = conn.execute("SELECT * FROM messages ORDER BY id DESC").fetchall()
        return [dict(r) for r in rows]
