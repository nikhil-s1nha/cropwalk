"""Download the cited price sources and extract them to small CSVs in sources/.

Run:  python fetch_sources.py            (needs network; see requirements.txt)
Raw downloads go to backend/data/price_raw/ (git-ignored). Only the extracted CSVs
are committed. Every source URL is listed in docs/PRICING.md.
"""
from __future__ import annotations

import csv
import re
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCES = HERE / "sources"
RAW = HERE.parents[1] / "data" / "price_raw"

PINK_SHEET_URL = (
    "https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/"
    "related/CMO-Historical-Data-Monthly.xlsx"
)
# Tanzania Coffee Board, "Matokeo Mnada 2026/2027" (auction results), Moshi auction.
TCB_AUCTIONS = {
    "TCB/M/1": "https://www.coffee.go.tz/uploads/documents/sw-1789362996-CLAR_2026_09_000002.pdf",
    "TCB/M/2": "https://www.coffee.go.tz/uploads/documents/sw-1789652704-CLAR_2026_09_000003%20(1).pdf",
    "TCB/M/3": "https://www.coffee.go.tz/uploads/documents/sw-1790239496-TCB%20M%203%20Results.pdf",
    "TCB/M/4": "https://www.coffee.go.tz/uploads/documents/sw-1790861440-CLAR_2026_10_000005.pdf",
}

# One lot: ".../<outturn no>  GRADE  BAGS  POCKETS  N/KGS  <warehouse>  PRICE sold | no bid | ..."
LOT_RE = re.compile(
    r"/\d{2,5}\s+([A-Z]{1,4})\s+(\d+)\s+(\d+)\s+([\d,]+)\s+(.+?)\s+"
    r"(?:(\d+\.\d+)\s+sold|(no bid)|(withdrawn)|(unsold))",
    re.S,
)
STATUS_RE = re.compile(r"(?:sold|no bid|withdrawn|unsold)\s")
PAGE_FOOTER_RE = re.compile(r"Page \d+ of \d+ \| Auction : \S+ Printed On : [\d\- :]+")
AUCTION_HDR_RE = re.compile(r"Auction No : (\S+) Auction Date : (\S+)")


def download(url: str, dest: Path) -> Path:
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            dest.write_bytes(r.read())
    return dest


def parse_auction_text(text: str) -> tuple[str, str, list[dict]]:
    """Parse the text of one TCB auction-results PDF into lots."""
    m = AUCTION_HDR_RE.search(text)
    if not m:
        raise ValueError("auction header not found")
    auction_no, auction_date = m.groups()
    text = PAGE_FOOTER_RE.sub("", text)
    lots = []
    for grade, bags, pockets, kg, _wh, price, no_bid, withdrawn, unsold in LOT_RE.findall(text):
        status = "sold" if price else ("no bid" if no_bid else ("withdrawn" if withdrawn else "unsold"))
        lots.append(
            {
                "auction": auction_no,
                "auction_date": auction_date,
                "grade": grade,
                "net_kg": int(kg.replace(",", "")),
                "price_usd_per_50kg": price or "",
                "status": status,
            }
        )
    n_status = len(STATUS_RE.findall(text))
    if n_status != len(lots):
        raise ValueError(f"{auction_no}: parsed {len(lots)} lots but found {n_status} status words")
    return auction_no, auction_date, lots


def fetch_auctions() -> None:
    from pypdf import PdfReader

    rows: list[dict] = []
    for name, url in TCB_AUCTIONS.items():
        pdf = download(url, RAW / (name.replace("/", "_") + ".pdf"))
        text = "\n".join((p.extract_text() or "") for p in PdfReader(str(pdf)).pages)
        auction_no, _, lots = parse_auction_text(text)
        assert auction_no == name, (auction_no, name)
        rows += lots
        print(f"{name}: {len(lots)} lots")
    out = SOURCES / "tcb_auction_lots_2026-27.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print("wrote", out.relative_to(HERE))


def fetch_pink_sheet() -> None:
    import openpyxl

    xlsx = download(PINK_SHEET_URL, RAW / "CMO-Historical-Data-Monthly.xlsx")
    ws = openpyxl.load_workbook(xlsx, read_only=True, data_only=True)["Monthly Prices"]
    rows = list(ws.iter_rows(values_only=True))
    updated = next(r[0] for r in rows[:6] if r[0] and str(r[0]).startswith("Updated on"))
    header, units = rows[4], rows[5]
    col = header.index("Coffee, Arabica")
    out = SOURCES / "pink_sheet_coffee_arabica_monthly.csv"
    with out.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["month", "usd_per_kg", "unit", "file_note"])
        for r in rows[6:]:
            if r[0] and r[0] >= "2000M01" and isinstance(r[col], (int, float)):
                w.writerow([r[0], r[col], units[col], updated])
    print("wrote", out.relative_to(HERE), "|", updated)


if __name__ == "__main__":
    SOURCES.mkdir(exist_ok=True)
    what = sys.argv[1:] or ["pink", "auctions"]
    if "pink" in what:
        fetch_pink_sheet()
    if "auctions" in what:
        fetch_auctions()
