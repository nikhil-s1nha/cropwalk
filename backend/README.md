# Ondera Leaf Walk — backend

FastAPI + SQLite. Used **only** for the cooperative inbox, the mock SMS gateway, price data and alerts.
The app's core flow never needs it (airplane mode). **No photo or audio endpoints, ever** — multipart uploads get `415`.

## Setup and run

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m scripts.seed                      # optional: 5 SYNTHETIC demo messages (farmer IDs SYN…)
uvicorn app.main:app --reload --port 8000   # http://localhost:8000/coop/inbox
pytest                                      # tests
```

- The iOS **simulator** reaches the backend at `http://localhost:8000`. A real iPhone needs your Mac's LAN IP (`uvicorn ... --host 0.0.0.0`) and the backend URL set in app Settings.
- Database: `backend/data/ondera.db` (git-ignored). Override with `ONDERA_DB=/path/to.db`.

## Endpoints

| Method | Path | What | Owner |
|---|---|---|---|
| GET | `/health` | `{"status":"ok"}` | A (Task 5) |
| POST | `/sms/send` | Mock SMS gateway used by the app outbox. JSON `{recipient, body, client_message_id?, synthetic?}`. Body ≤ 160 chars, GSM-7 only, else `422`. Repeating a `client_message_id` returns the original row (`200`) instead of a duplicate (`201`), so outbox retries are safe. | A (Task 5) |
| GET | `/coop/inbox` | HTML inbox for the cooperative officer, newest first, with walk reports (WORKFLOW §7.1) and officer requests (§7.2) parsed into columns. Unparsable SMS shown raw. SYNTHETIC rows badged. | A (Task 5) |
| GET | `/coop/inbox.json` | Same data as JSON (`parsed` is `null` when unparsable). | A (Task 5) |
| GET | `/price/latest` | Stub → `501`. | **C (Task 25)** — `app/price.py` |
| GET | `/alerts` | Stub → `501`. | **D (Task 27)** — `app/alerts.py` |

The weekday check-in mock (Task 6) goes in `app/checkin*` + `templates/phone*`.

## Layout

```
app/main.py       app factory, /health, /sms/send, /coop/inbox(.json)
app/db.py         sqlite3 storage (messages table)
app/sms_parse.py  pure parser for the fixed SMS templates + GSM-7 check
app/price.py      C owns
app/alerts.py     D owns
scripts/seed.py   SYNTHETIC demo messages
tests/            pytest
```
