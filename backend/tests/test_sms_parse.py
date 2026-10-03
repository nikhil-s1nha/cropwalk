from app.sms_parse import is_gsm7, parse_sms

# Examples from docs/WORKFLOW.md §7
WALK_EXAMPLE = "OLW F0123 03/10/26 Madoa 12/100=12% (7-20%) JUU Shaka:2 Vituo:10/10 Kutu:3 Mchimbaji:1"
WALK_WORST = ("OLW F0123 03/10/26 Madoa 100/100=100% (96-100%) HAIJULIKANI Shaka:10 "
              "Vituo:10/10 Kutu:10 Mchimbaji:10")
OFFICER_WORST = ("OLW F0123 03/10/26 AFISA: miti 10 ina shaka, vituo 1,2,3,4,5,6,7,8,9,10. "
                 "Madoa 100/100. Tafadhali tembelea shamba.")


def test_walk_report_example():
    p = parse_sms(WALK_EXAMPLE)
    assert p == {
        "kind": "walk_report", "farmer_id": "F0123", "date": "03/10/26",
        "spotted_leaves": 12, "leaves_checked": 100, "incidence_pct": 12,
        "ci_low_pct": 7, "ci_high_pct": 20, "recommendation": "JUU",
        "recommendation_label": "above treatment level", "unsure_trees": 2,
        "stops_checked": 10, "diseases": {"Kutu": 3, "Mchimbaji": 1},
    }


def test_walk_report_worst_case_fits_and_parses():
    assert len(WALK_WORST) <= 160
    p = parse_sms(WALK_WORST)
    assert p["recommendation"] == "HAIJULIKANI"
    assert p["ci_high_pct"] == 100 and p["unsure_trees"] == 10
    assert p["diseases"] == {"Kutu": 10, "Mchimbaji": 10}


def test_walk_report_without_diseases_and_decimals():
    p = parse_sms("OLW F9 03/10/26 Madoa 3/100=3% (1.03-8.45%) KARIBU Shaka:0 Vituo:10/10")
    assert p["diseases"] == {}
    assert p["ci_low_pct"] == 1.03 and p["ci_high_pct"] == 8.45
    assert p["recommendation_label"] == "close to treatment level"


def test_officer_worst_case():
    assert len(OFFICER_WORST) <= 160
    p = parse_sms(OFFICER_WORST)
    assert p["kind"] == "officer_request"
    assert p["stops"] == list(range(1, 11))
    assert p["unsure_trees"] == 10 and p["spotted_leaves"] == 100


def test_unparsable_returns_none():
    assert parse_sms("hello cooperative") is None
    assert parse_sms("OLW F1 03/10/26 Madoa 1/100=1% (0-5%) MAYBE Shaka:0 Vituo:10/10") is None


def test_gsm7():
    assert is_gsm7(WALK_EXAMPLE)
    assert not is_gsm7("Bei 10–20")  # en dash is not GSM-7
    assert not is_gsm7("≤160")
