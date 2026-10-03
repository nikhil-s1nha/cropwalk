"""Seed the inbox with SYNTHETIC demo messages (farmer IDs SYN…, flagged synthetic).

Run from backend/:  python -m scripts.seed
"""
from app import db

SYNTHETIC_MESSAGES = [
    ("COOP", "OLW SYN001 26/09/26 Madoa 0/100=0% (0-4%) CHINI Shaka:0 Vituo:10/10"),
    ("COOP", "OLW SYN002 26/09/26 Madoa 8/100=8% (4-15%) KARIBU Shaka:1 Vituo:10/10 Kutu:2"),
    ("COOP", "OLW SYN003 03/10/26 Madoa 12/100=12% (7-20%) JUU Shaka:2 Vituo:10/10 Kutu:3 Mchimbaji:1"),
    ("OFFICER", "OLW SYN003 03/10/26 AFISA: miti 2 ina shaka, vituo 3,7. Madoa 12/100. Tafadhali tembelea shamba."),
    ("COOP", "OLW SYN004 03/10/26 Madoa 3/50=6% (2-16%) HAIJULIKANI Shaka:0 Vituo:5/10"),
]


def main() -> None:
    db.init_db()
    for i, (recipient, body) in enumerate(SYNTHETIC_MESSAGES):
        db.insert_message(recipient, body, client_message_id=f"SYNTHETIC-seed-{i}", synthetic=True)
    print(f"Seeded {len(SYNTHETIC_MESSAGES)} SYNTHETIC messages into {db.db_path()}")


if __name__ == "__main__":
    main()
