"""Ondera Leaf Walk backend: cooperative inbox + mock SMS gateway (Task 5).

Only counts/labels arrive here, as SMS text. There are no photo or audio endpoints, ever
(CLAUDE.md hard rule 7); multipart uploads are rejected outright.
"""
from __future__ import annotations

import html
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, Field, field_validator

from . import alerts, db, price
from .sms_parse import MAX_SMS_CHARS, is_gsm7, parse_sms


class SendSMS(BaseModel):
    recipient: str = Field(min_length=1, max_length=40)
    body: str = Field(min_length=1)
    client_message_id: str | None = Field(default=None, max_length=100)
    synthetic: bool = False  # set by the app in simulate/demo mode

    @field_validator("body")
    @classmethod
    def body_is_valid_sms(cls, v: str) -> str:
        if len(v) > MAX_SMS_CHARS:
            raise ValueError(f"body is {len(v)} chars; max {MAX_SMS_CHARS}")
        if not is_gsm7(v):
            bad = sorted({c for c in v if not is_gsm7(c)})
            raise ValueError(f"body has non-GSM-7 characters: {bad}")
        return v


def _with_parsed(row: dict) -> dict:
    return {**row, "synthetic": bool(row["synthetic"]), "parsed": parse_sms(row["body"])}


def create_app(db_file: Path | str | None = None) -> FastAPI:
    app = FastAPI(title="Ondera Leaf Walk backend", version="0.1.0")
    app.state.db = Path(db_file) if db_file else db.db_path()
    db.init_db(app.state.db)

    @app.middleware("http")
    async def reject_uploads(request: Request, call_next):
        if request.headers.get("content-type", "").startswith("multipart/"):
            return JSONResponse(status_code=415,
                                content={"detail": "file uploads are not accepted; photos stay on the phone"})
        return await call_next(request)

    @app.get("/health")
    def health():
        return {"status": "ok"}

    @app.post("/sms/send")
    def sms_send(msg: SendSMS):
        row, created = db.insert_message(msg.recipient, msg.body, msg.client_message_id,
                                         msg.synthetic, app.state.db)
        return JSONResponse(
            status_code=201 if created else 200,
            content={"id": row["id"], "status": "received", "received_at": row["received_at"]},
        )

    @app.get("/coop/inbox.json")
    def inbox_json():
        return [_with_parsed(r) for r in db.list_messages(app.state.db)]

    @app.get("/coop/inbox", response_class=HTMLResponse)
    def inbox_html():
        return _render_inbox([_with_parsed(r) for r in db.list_messages(app.state.db)])

    app.include_router(price.router)
    app.include_router(alerts.router)
    return app


def _render_inbox(rows: list[dict]) -> str:
    e = html.escape
    trs = []
    for r in rows:
        p = r["parsed"]
        badge = '<span class="syn">SYNTHETIC</span> ' if r["synthetic"] else ""
        if p and p["kind"] == "walk_report":
            dis = ", ".join(f"{k} {v}" for k, v in p["diseases"].items()) or "—"
            cells = [
                "Walk report", p["farmer_id"], p["date"],
                f'{p["spotted_leaves"]}/{p["leaves_checked"]}',
                f'{p["incidence_pct"]}% ({p["ci_low_pct"]}–{p["ci_high_pct"]}%)',
                f'{p["recommendation"]} · {p["recommendation_label"]}',
                str(p["unsure_trees"]), f'{p["stops_checked"]}/10', dis,
            ]
        elif p and p["kind"] == "officer_request":
            cells = [
                "Ask officer", p["farmer_id"], p["date"],
                f'{p["spotted_leaves"]}/{p["leaves_checked"]}', "—", "—",
                str(p["unsure_trees"]), "stops " + ",".join(map(str, p["stops"])), "—",
            ]
        else:
            cells = ["Unparsed", "—", "—", "—", "—", "—", "—", "—", "—"]
        tds = "".join(f"<td>{e(c)}</td>" for c in cells)
        trs.append(
            f"<tr><td>{badge}{e(r['received_at'])}</td>{tds}"
            f"<td class=raw>{e(r['recipient'])}: {e(r['body'])}</td></tr>"
        )
    body = "\n".join(trs) or '<tr><td colspan="11">No messages yet.</td></tr>'
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="10">
<title>Coop Inbox</title>
<style>
 body {{ font-family: -apple-system, system-ui, sans-serif; margin: 16px; background: #fafaf7; color: #1d1d1b; }}
 h1 {{ font-size: 1.3rem; }} p.note {{ color: #555; font-size: .9rem; }}
 .wrap {{ overflow-x: auto; }}
 table {{ border-collapse: collapse; width: 100%; font-size: .85rem; background: #fff; }}
 th, td {{ border: 1px solid #ddd; padding: 6px 8px; text-align: left; vertical-align: top; }}
 th {{ background: #eef2ea; }}
 td.raw {{ font-family: ui-monospace, monospace; font-size: .75rem; color: #555; }}
 .syn {{ background: #f5c542; color: #000; font-weight: 600; font-size: .7rem; padding: 1px 4px; border-radius: 3px; }}
</style></head><body>
<h1>Ondera Coffee Cooperative — walk report inbox</h1>
<p class="note">Mock SMS gateway. Messages contain counts only; photos never leave the farmer's phone.
Rows marked SYNTHETIC are demo data. Auto-refreshes every 10 s.</p>
<div class="wrap"><table>
<tr><th>Received (UTC)</th><th>Type</th><th>Farmer</th><th>Walk date</th><th>Spotted leaves</th>
<th>Incidence (95% CI)</th><th>Recommendation</th><th>Unsure trees</th><th>Stops</th><th>Diseases</th><th>Raw SMS</th></tr>
{body}
</table></div>
</body></html>"""


app = create_app()
