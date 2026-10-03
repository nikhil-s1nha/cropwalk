"""Checks for the committed price snapshot and its build. Run: pytest backend/app/price_data"""
import json
from pathlib import Path

import pytest

from build_snapshot import build

HERE = Path(__file__).resolve().parent
SNAPSHOT = HERE / "SNAPSHOT_2026-10-03.json"


@pytest.fixture(scope="module")
def snap():
    return build("2026-10-03")


def test_committed_snapshot_matches_build(snap):
    assert json.loads(SNAPSHOT.read_text()) == json.loads(json.dumps(snap))


def test_worked_example_from_pricing_md(snap):
    # docs/PRICING.md "Worked example": 7.26 USD/kg x 0.80 x 2639.2494 TZS/USD
    assert snap["value"] == 7.26
    assert snap["fx_rate"] == pytest.approx(2639.2494, abs=1e-4)
    assert snap["conversion"]["parchment_equivalent_tzs_per_kg"] == pytest.approx(15328.8, abs=0.1)
    assert snap["farm_gate_range"] == {"low": 5700, "high": 8500, "currency": "TZS", "unit": "kg", "form": "parchment"}


def test_every_value_has_source_and_date(snap):
    assert snap["label"] == "estimate"
    assert snap["source"] and snap["observed_date"] == "2026-09"
    assert snap["fx_source"] and snap["fx_date"] == "2026-10-03"
    assert snap["grade_prices"]["source"] and len(snap["grade_prices"]["auctions"]) == 4
    manual = json.loads((HERE / "sources" / "manual_inputs.json").read_text())
    for key, entry in manual.items():
        if key.startswith("_"):
            continue
        assert entry["source"] and entry["url"] and entry["accessed"], key


def test_shares_are_plausible_fractions(snap):
    shares = snap["conversion"]["farm_gate_share_by_year"]
    assert set(shares) == {"2005", "2006", "2007", "2008", "2009", "2010"}
    assert all(0 < s < 1 for s in shares.values())
    assert snap["conversion"]["farm_gate_share_low"] == min(shares.values())


def test_grade_prices_cover_every_mapped_auction_grade(snap):
    grades_cfg = json.loads((HERE / "grades_TZ.json").read_text())
    have = set(snap["grade_prices"]["grades"])
    for cls, auction_grades in grades_cfg["photo_class_to_auction_grades"].items():
        assert set(auction_grades) <= have, cls
        assert cls in snap["photo_class_price_ratio"]
    gp = snap["grade_prices"]
    assert gp["lots_sold"] <= gp["lots_total"]
    assert gp["grades"]["AA"]["usd_per_kg_clean"] > gp["grades"]["C"]["usd_per_kg_clean"]


def test_size_bands_are_contiguous():
    bands = json.loads((HERE / "grades_TZ.json").read_text())["size_bands_mm"]
    ordered = sorted(bands, key=lambda b: b["min_mm"])
    for lower, upper in zip(ordered, ordered[1:]):
        assert lower["max_mm"] == upper["min_mm"]
    assert ordered[-1]["max_mm"] is None and ordered[0]["min_mm"] == 0.0
