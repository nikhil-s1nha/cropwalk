"""Pure parsers for the fixed SMS templates in docs/WORKFLOW.md §7, plus GSM-7 validation."""
from __future__ import annotations

import re

MAX_SMS_CHARS = 160

# GSM 03.38 basic character set + extension table. Length is checked in characters;
# our fixed templates never use extension characters.
_GSM7_BASIC = (
    "@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?"
    "¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà"
)
_GSM7_EXT = "^{}\\[~]|€\f"
GSM7_CHARS = frozenset(_GSM7_BASIC + _GSM7_EXT)


def is_gsm7(text: str) -> bool:
    return all(ch in GSM7_CHARS for ch in text)


_NUM = r"\d+(?:\.\d+)?"

# §7.1 Walk report to cooperative
WALK_REPORT_RE = re.compile(
    rf"^OLW (?P<farmer_id>\S+) (?P<date>\d{{2}}/\d{{2}}/\d{{2}}) "
    rf"Madoa (?P<x>\d+)/(?P<n>\d+)=(?P<p>{_NUM})% \((?P<lo>{_NUM})-(?P<hi>{_NUM})%\) "
    rf"(?P<rec>CHINI|KARIBU|JUU|HAIJULIKANI) "
    rf"Shaka:(?P<amber>\d+) Vituo:(?P<checked>\d+)/10"
    rf"(?: (?P<diseases>\S+:\d+(?: \S+:\d+)?))?$"
)

# §7.2 Ask extension officer
OFFICER_RE = re.compile(
    r"^OLW (?P<farmer_id>\S+) (?P<date>\d{2}/\d{2}/\d{2}) "
    r"AFISA: miti (?P<k>\d+) ina shaka, vituo (?P<stops>\d+(?:,\d+)*)\. "
    r"Madoa (?P<x>\d+)/(?P<n>\d+)\. Tafadhali tembelea shamba\.$"
)

REC_LABELS = {
    "CHINI": "low",
    "KARIBU": "close to treatment level",
    "JUU": "above treatment level",
    "HAIJULIKANI": "not enough data",
}


def _num(s: str) -> float | int:
    return float(s) if "." in s else int(s)


def parse_sms(body: str) -> dict | None:
    """Return parsed fields with 'kind' ('walk_report' | 'officer_request'), or None if unparsable."""
    text = body.strip()
    m = WALK_REPORT_RE.match(text)
    if m:
        d = m.groupdict()
        diseases: dict[str, int] = {}
        if d["diseases"]:
            for pair in d["diseases"].split(" "):
                name, count = pair.rsplit(":", 1)
                diseases[name] = int(count)
        return {
            "kind": "walk_report",
            "farmer_id": d["farmer_id"],
            "date": d["date"],
            "spotted_leaves": int(d["x"]),
            "leaves_checked": int(d["n"]),
            "incidence_pct": _num(d["p"]),
            "ci_low_pct": _num(d["lo"]),
            "ci_high_pct": _num(d["hi"]),
            "recommendation": d["rec"],
            "recommendation_label": REC_LABELS[d["rec"]],
            "unsure_trees": int(d["amber"]),
            "stops_checked": int(d["checked"]),
            "diseases": diseases,
        }
    m = OFFICER_RE.match(text)
    if m:
        d = m.groupdict()
        return {
            "kind": "officer_request",
            "farmer_id": d["farmer_id"],
            "date": d["date"],
            "unsure_trees": int(d["k"]),
            "stops": [int(s) for s in d["stops"].split(",")],
            "spotted_leaves": int(d["x"]),
            "leaves_checked": int(d["n"]),
        }
    return None
