"""Build the price snapshot served by /price/latest (Task 25) and bundled in the app (Task 26).

Inputs (all committed, all cited in docs/PRICING.md):
  sources/pink_sheet_coffee_arabica_monthly.csv   World Bank Pink Sheet (fetch_sources.py)
  sources/tcb_auction_lots_2026-27.csv            Tanzania Coffee Board auction results (fetch_sources.py)
  sources/manual_inputs.json                      FX, ICA parchment factor, MAFAP farm-gate table
  grades_TZ.json                                  EAS 130 size bands + photo-class -> auction-grade map

Run:  python build_snapshot.py [YYYY-MM-DD]   -> SNAPSHOT_<date>.json (deterministic for given inputs)

Maths (worked example in docs/PRICING.md):
  parchment_equivalent_tzs = pink_sheet_usd_per_kg_green * 0.80 * fx_mid
  farm_gate_range          = parchment_equivalent_tzs * [share_low, share_high], rounded to 100 TZS
  share_year               = TCB farm-gate parchment USD/t / (Pink Sheet annual mean USD/kg * 1000 * 0.80)
  grade ratio              = kg-weighted auction price of the grade(s) / kg-weighted price of all sold lots
"""
from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path
from statistics import mean

HERE = Path(__file__).resolve().parent
SRC = HERE / "sources"
ROUND_TZS = 100


def load_pink_sheet() -> list[dict]:
    with (SRC / "pink_sheet_coffee_arabica_monthly.csv").open() as f:
        return [dict(r, usd_per_kg=float(r["usd_per_kg"])) for r in csv.DictReader(f)]


def load_lots() -> list[dict]:
    with (SRC / "tcb_auction_lots_2026-27.csv").open() as f:
        return list(csv.DictReader(f))


def farm_gate_shares(pink: list[dict], manual: dict) -> dict[str, float]:
    factor = manual["parchment_to_green"]["factor"]
    out = {}
    for year, usd_per_t in manual["tz_farm_gate_arabica_parchment_usd_per_t"]["values"].items():
        annual = mean(r["usd_per_kg"] for r in pink if r["month"].startswith(year + "M"))
        out[year] = usd_per_t / (annual * 1000 * factor)
    return out


def grade_prices(lots: list[dict]) -> dict:
    sold = [l for l in lots if l["status"] == "sold"]
    kg = defaultdict(float)
    usd = defaultdict(float)
    n = defaultdict(int)
    for l in sold:
        k, p = float(l["net_kg"]), float(l["price_usd_per_50kg"]) / 50
        kg[l["grade"]] += k
        usd[l["grade"]] += k * p
        n[l["grade"]] += 1
    overall = sum(usd.values()) / sum(kg.values())
    grades = {
        g: {
            "usd_per_kg_clean": round(usd[g] / kg[g], 3),
            "ratio_to_all_sold": round(usd[g] / kg[g] / overall, 3),
            "lots_sold": n[g],
            "kg_sold": int(kg[g]),
        }
        for g in sorted(kg)
    }
    return {"overall_usd_per_kg_clean": round(overall, 3), "lots_total": len(lots),
            "lots_sold": len(sold), "kg_sold": int(sum(kg.values())), "grades": grades,
            "_kg": kg, "_usd": usd}


def photo_class_ratios(gp: dict, grades_cfg: dict) -> dict[str, float]:
    overall = gp["overall_usd_per_kg_clean"]
    out = {}
    for cls, auction_grades in grades_cfg["photo_class_to_auction_grades"].items():
        kg = sum(gp["_kg"][g] for g in auction_grades)
        usd = sum(gp["_usd"][g] for g in auction_grades)
        out[cls] = round(usd / kg / overall, 3)
    return out


def build(built: str) -> dict:
    manual = json.loads((SRC / "manual_inputs.json").read_text())
    grades_cfg = json.loads((HERE / "grades_TZ.json").read_text())
    pink = load_pink_sheet()
    lots = load_lots()

    latest = pink[-1]
    fx = manual["fx_usd_tzs"]
    fx_mid = (fx["buy"] + fx["sell"]) / 2
    factor = manual["parchment_to_green"]["factor"]
    shares = farm_gate_shares(pink, manual)
    lo, hi = min(shares.values()), max(shares.values())
    parchment_eq = latest["usd_per_kg"] * factor * fx_mid
    gp = grade_prices(lots)
    ratios = photo_class_ratios(gp, grades_cfg)
    auctions = sorted({(l["auction"], l["auction_date"]) for l in lots})
    gp_public = {k: v for k, v in gp.items() if not k.startswith("_")}

    y, m = latest["month"].split("M")
    return {
        "schema_version": 1,
        "label": "estimate",
        "is_synthetic": False,
        "country": "TZ",
        "built_on": built,
        "fetched_at": built,
        "source": "World Bank Commodity Price Data (The Pink Sheet)",
        "series": "Coffee, Arabica (ICO other milds, ex-dock)",
        "unit": "USD/kg green coffee",
        "value": latest["usd_per_kg"],
        "observed_date": f"{y}-{m}",
        "source_file_note": latest["file_note"],
        "fx_rate": round(fx_mid, 4),
        "fx_date": fx["date"],
        "fx_source": fx["source"],
        "conversion": {
            "parchment_to_green": factor,
            "parchment_equivalent_tzs_per_kg": round(parchment_eq, 1),
            "farm_gate_share_low": round(lo, 4),
            "farm_gate_share_high": round(hi, 4),
            "farm_gate_share_by_year": {k: round(v, 4) for k, v in shares.items()},
            "farm_gate_share_basis": "TCB arabica parchment farm-gate price / Pink Sheet arabica parchment-equivalent, 2005-2010 (FAO MAFAP 2013, Table 6). OLD DATA - see docs/PRICING.md limitations.",
        },
        "farm_gate_range": {
            "low": int(round(parchment_eq * lo / ROUND_TZS) * ROUND_TZS),
            "high": int(round(parchment_eq * hi / ROUND_TZS) * ROUND_TZS),
            "currency": "TZS",
            "unit": "kg",
            "form": "parchment",
        },
        "grade_prices": {
            "source": "Tanzania Coffee Board, Moshi auction results 2026/2027 (kg-weighted, sold lots only)",
            "auctions": [{"no": a, "date": d} for a, d in auctions],
            **gp_public,
        },
        "photo_class_price_ratio": ratios,
        "cross_check": manual["tcb_headline_auction_price"],
    }


if __name__ == "__main__":
    built = sys.argv[1] if len(sys.argv) > 1 else date.today().isoformat()
    snap = build(built)
    out = HERE / f"SNAPSHOT_{built}.json"
    out.write_text(json.dumps(snap, indent=2, ensure_ascii=False) + "\n")
    print("wrote", out.name)
    print("reference", snap["value"], snap["unit"], snap["observed_date"])
    print("parchment eq TZS/kg", snap["conversion"]["parchment_equivalent_tzs_per_kg"])
    print("farm-gate", snap["farm_gate_range"])
    print("photo-class ratios", snap["photo_class_price_ratio"])
