WALK = "OLW F0123 03/10/26 Madoa 12/100=12% (7-20%) JUU Shaka:2 Vituo:10/10 Kutu:3 Mchimbaji:1"


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_send_appears_in_inbox_json_and_html(client):
    r = client.post("/sms/send", json={"recipient": "COOP", "body": WALK})
    assert r.status_code == 201
    assert r.json()["status"] == "received"
    rows = client.get("/coop/inbox.json").json()
    assert len(rows) == 1
    assert rows[0]["body"] == WALK and rows[0]["synthetic"] is False
    assert rows[0]["parsed"]["farmer_id"] == "F0123"
    page = client.get("/coop/inbox").text
    assert "F0123" in page and "above treatment level" in page and "Kutu 3" in page


def test_inbox_newest_first_and_unparsed_shown_raw(client):
    client.post("/sms/send", json={"recipient": "COOP", "body": WALK})
    client.post("/sms/send", json={"recipient": "COOP", "body": "habari <b>"})
    rows = client.get("/coop/inbox.json").json()
    assert rows[0]["body"] == "habari <b>" and rows[0]["parsed"] is None
    page = client.get("/coop/inbox").text
    assert "Unparsed" in page and "habari &lt;b&gt;" in page


def test_synthetic_badge(client):
    client.post("/sms/send", json={"recipient": "COOP", "body": WALK, "synthetic": True})
    assert "SYNTHETIC</span>" in client.get("/coop/inbox").text


def test_over_160_rejected(client):
    r = client.post("/sms/send", json={"recipient": "COOP", "body": "a" * 161})
    assert r.status_code == 422
    assert client.post("/sms/send", json={"recipient": "COOP", "body": "a" * 160}).status_code == 201


def test_non_gsm7_rejected(client):
    r = client.post("/sms/send", json={"recipient": "COOP", "body": "Bei 10–20"})
    assert r.status_code == 422


def test_missing_or_empty_fields_rejected(client):
    assert client.post("/sms/send", json={"body": WALK}).status_code == 422
    assert client.post("/sms/send", json={"recipient": "COOP"}).status_code == 422
    assert client.post("/sms/send", json={"recipient": "", "body": WALK}).status_code == 422
    assert client.post("/sms/send", json={"recipient": "COOP", "body": ""}).status_code == 422


def test_idempotent_on_client_message_id(client):
    payload = {"recipient": "COOP", "body": WALK, "client_message_id": "abc-1"}
    first = client.post("/sms/send", json=payload)
    second = client.post("/sms/send", json=payload)
    assert first.status_code == 201 and second.status_code == 200
    assert first.json()["id"] == second.json()["id"]
    assert len(client.get("/coop/inbox.json").json()) == 1


def test_multipart_uploads_rejected(client):
    r = client.post("/sms/send", files={"photo": ("leaf.jpg", b"\xff\xd8", "image/jpeg")})
    assert r.status_code == 415


def test_price_and_alerts_stubs(client):
    r = client.get("/price/latest")
    assert r.status_code == 501 and "task 25" in r.json()["detail"]
    r = client.get("/alerts")
    assert r.status_code == 501 and "task 27" in r.json()["detail"]


def test_persists_across_app_instances(tmp_path):
    from fastapi.testclient import TestClient

    from app.main import create_app
    db = tmp_path / "persist.db"
    TestClient(create_app(db)).post("/sms/send", json={"recipient": "COOP", "body": WALK})
    assert len(TestClient(create_app(db)).get("/coop/inbox.json").json()) == 1


def test_seed_script(tmp_path, monkeypatch):
    monkeypatch.setenv("ONDERA_DB", str(tmp_path / "seed.db"))
    from scripts import seed
    seed.main()
    seed.main()  # idempotent
    from fastapi.testclient import TestClient

    from app.main import create_app
    rows = TestClient(create_app(tmp_path / "seed.db")).get("/coop/inbox.json").json()
    assert len(rows) == len(seed.SYNTHETIC_MESSAGES)
    assert all(r["synthetic"] and "SYN" in r["body"] for r in rows)
    assert all(r["parsed"] is not None for r in rows)
