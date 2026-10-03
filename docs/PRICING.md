# Pricing sources and conversion factors

_Owner: C — Task 24. Last researched **2026-10-03**. Every number below comes from a cited source or from our own
calculation on cited data (script + commit given). If a number isn't here, the app doesn't show it._

**Where Noor is.** Ondera is fictional. We price for **Tanzania (TZS)** because Swahili is the everyday language there,
and Tanzanian smallholders sell **parchment** at the farm gate. That matches the brief's "sells her parchment to
whichever middleman…". USDA FAS confirms that the farm-gate sale is "the main coffee marketing channel… coffee is
traded in form of parchment for washed coffees" ([USDA FAS, Coffee Annual Tanzania TZ2024-0002](https://apps.fas.usda.gov/newgainapi/api/Report/DownloadReportByFileName?fileName=Coffee+Annual_Dar+Es+Salaam_Tanzania_TZ2024-0002.pdf)).

Data files: `backend/app/price_data/` (`SNAPSHOT_2026-10-03.json`, `grades_TZ.json`, `sources/`). Rebuild with
`python fetch_sources.py && python build_snapshot.py YYYY-MM-DD`; check with `pytest backend/app/price_data`.

## 1. Sources

| # | What | Source | Series / unit | Latest value used | Date of value | Licence / terms | Accessed |
|---|---|---|---|---|---|---|---|
| S1 | **World reference price** | [World Bank Commodity Price Data (Pink Sheet), monthly xlsx](https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/related/CMO-Historical-Data-Monthly.xlsx). File "Updated on October 02, 2026" | "Coffee, Arabica": ICO indicator price, other mild Arabicas, avg New York + Bremen/Hamburg, ex-dock. **USD/kg green**, monthly | **7.26 USD/kg** | Sep 2026 | CC BY 4.0 ([WB Data Catalog, GEM Commodities](https://datacatalog.worldbank.org/search/dataset/0037798/global-economic-monitor-commodities)). Cite "World Bank Commodity Price Data (The Pink Sheet)". | 2026-10-03 |
| S2 | **Tanzanian auction prices by grade** | [Tanzania Coffee Board, "Matokeo Mnada 2026/2027"](https://www.coffee.go.tz/publications/auction-results-2026-2027): Moshi auctions TCB/M/1 (10 Sep), M/2 (17 Sep), M/3 (24 Sep), M/4 (1 Oct 2026) | Per lot: grade, net kg, **USD per 50 kg clean coffee** | 313 lots, 287 sold, 775,588 kg; all-grade kg-weighted mean **6.002 USD/kg** | 10 Sep – 1 Oct 2026 | Public government document; no licence stated. We republish only extracted lot rows, with the source. | 2026-10-03 |
| S3 | TCB headline auction price (cross-check only) | [TCB "Bei za minada"](https://www.coffee.go.tz/auction_prices) | "Arabica – Kahawa Safi ($/Kg)" | 6.5 USD/kg clean | 30 Sep 2026 | as S2 | 2026-10-03 |
| S4 | **Exchange rate** | [Bank of Tanzania](https://www.bot.go.tz/), indicative rates | USD → TZS buy / sell | 2,626.1188 / 2,652.38 → **mid 2,639.2494** | 3 Oct 2026 | Public | 2026-10-03 |
| S5 | **Parchment → green factor** | International Coffee Agreement 2001, Art. 2(1)(c) ([text](https://m.likumi.lv/ta/id/209279-international-coffee-agreement-2001)); same factor in ICA 2007 Art. 2 | "multiply the net weight of the parchment coffee by 0.80" | **0.80** | Treaty (2001; 2007) | Treaty text | 2026-10-03 |
| S6 | **Farm-gate parchment prices, Tanzania** | [FAO MAFAP, "Analysis of incentives and disincentives for coffee in the United Republic of Tanzania", Jan 2013](https://openknowledge.fao.org/3/a-at479e.pdf), Table 6, row "TCB [ARABICA PARCHMENT] (USD/MT)", data from the Tanzania Coffee Board | USD per tonne parchment | 797, 959, 1205, 1254, 1137, 1277 | 2005–2010 | FAO publication, cited | 2026-10-03 |
| S7 | **Grade definitions** | [EAS 130:1999 "Green coffee beans — Specification"](https://law.resource.org/pub/eac/ibr/eas.130.1999.pdf) (East African Community; Tanzania is a member) | Table 1 sizes; cl. 4.2.1 moisture; cl. 4.2.3 damage classes; Annex B defects | see §4 | 1999 | Published via law.resource.org | 2026-10-03 |

**Not used, and why:** WFP food prices on HDX (named in the brief) has no coffee series. Uganda's MAAIF farm-gate
quotes are for the wrong country. A Tanzanian **current** official farm-gate parchment price was **not found**. TCB
publishes auction (clean-coffee) prices, not farm-gate prices. This gap is why we need the share in §2.

## 2. Conversion factors

| Factor | Value | Source | Note |
|---|---|---|---|
| lb → kg | not needed | — | S1 is already USD/kg |
| Parchment → green | × 0.80 | S5 | 1 kg parchment ≈ 0.80 kg green (clean) coffee |
| USD → TZS | 2,639.2494 | S4, mid of buy/sell, 3 Oct 2026 | |
| **Farm-gate share** of the reference price | **0.3695 – 0.5529** | Our calculation on S6 + S1 (`build_snapshot.py`) | share = farm-gate USD/t ÷ (Pink Sheet annual mean × 1000 × 0.80) |
| Grade price ratio | 0.713 – 1.055 | Our calculation on S2 | grade kg-weighted price ÷ all-sold kg-weighted price |

Farm-gate share by year (S6 ÷ S1 parchment equivalent): 2005 0.393 · 2006 0.475 · 2007 0.553 · 2008 0.509 ·
2009 0.448 · 2010 0.370. We use the **min–max** as the range. FAO MAFAP itself says "even in the best years farmers
only get 46 percent of the export price" (S6, summary; their basis is the export price, not ours).

## 3. Worked example (the one the app and the tests use)

```
reference (S1)              7.26 USD/kg green                         Sep 2026
× parchment factor (S5)     × 0.80                → 5.808 USD per kg parchment-equivalent
× FX mid (S4)               × 2,639.2494          → 15,328.8 TZS per kg parchment-equivalent
× farm-gate share (§2)      × 0.3695 … 0.5529     → 5,664 … 8,476 TZS
round to 100 TZS                                   → 5,700 – 8,500 TZS per kg parchment
```
`test_worked_example_from_pricing_md` asserts these values.

Panel text (template from `docs/WORKFLOW.md` §10):
> **sw:** Bei ya marejeo duniani: 7.26 USD/kg — World Bank Pink Sheet, Septemba 2026.
> Makadirio ya bei shambani: TZS 5,700–8,500 kwa kilo ya {form}. Makadirio tu — si bei ya mnunuzi. Imesasishwa: 3 Okt 2026.
>
> **en:** World reference price: 7.26 USD/kg — World Bank Pink Sheet, September 2026.
> Rough farm-gate estimate: TZS 5,700–8,500 per kg of parchment. Estimate only — not a buyer's offer. Updated: 3 Oct 2026.

`{form}`: the Swahili word for parchment coffee is **not yet confirmed**. Needs native/extension review (add it to `SWAHILI_REVIEW.md`).

## 4. Grades (for the Price Check bean photo)

**Size bands. EAS 130:1999 Table 1** (flat beans on round-hole screens; screen N = N/64 inch):

| Photo size class | Bean width | EAS text |
|---|---|---|
| E | ≥ 8.3 mm | retained on screen 21 |
| AA | 7.2 – 8.3 mm | through 21, retained on 18 |
| AB | 6.35 – 7.2 mm | through 18, retained on 16 |
| C | 3.96 – 6.35 mm | through 16, retained on 10 |
| T | < 3.96 mm | brokens; EAS gives "through 7 (2.9 mm)". We put the 2.9–3.96 mm gap into T. |
| PB | peaberry (round, single bean) | through 17 on slotted screen 12. Detected by **shape**, not width. |

- "A minimum 95 % of the beans shall fall in that grade category" (EAS 130 §5.1). A farmer's sample is a **mix**, so we
  report the **mix** and a grade **range**, never one grade.
- Moisture max **10.5 %** (§4.2.1). **The photo can't measure it.** Tap questions only produce a "dry more" warning.
- Damage classes (§4.2.3): classes 1–6 no damage; class 7 ≤ 5 %; class 8 ≤ 15 %; class 9 ≤ 25 %; class 10 ≤ 60 % of beans.
- Tanzanian auctions also sell **A** and **B**. We found **no primary source** for their screen sizes; secondary sources
  disagree. So the photo uses EAS classes, and for price we pool AB+A+B (see below).

**Auction price by grade (S2; sold lots, kg-weighted, USD/kg clean coffee):**

| Grade | USD/kg | Ratio | Lots sold | kg |
|---|---|---|---|---|
| AA | 6.332 | 1.055 | 44 | 138,259 |
| A | 6.289 | 1.048 | 41 | 177,494 |
| PB | 6.280 | 1.046 | 37 | 90,710 |
| AB | 6.203 | 1.033 | 11 | 19,649 |
| B | 6.129 | 1.021 | 48 | 234,181 |
| C | 5.158 | 0.859 | 29 | 43,038 |
| E | 4.700 | 0.783 | **4** | **371** (too few lots; treat as unreliable) |
| AF | 4.569 | 0.761 | 16 | 15,650 |
| TT | 4.351 | 0.725 | 19 | 18,131 |
| F | 4.277 | 0.713 | 27 | 26,570 |
| UG | 4.223 | 0.704 | 11 | 11,535 |
| **All sold** | **6.002** | 1.000 | 287 | 775,588 |

**Photo class → price ratio (our mapping, `grades_TZ.json`):** AA → AA (1.055) · AB → AB+A+B pooled (1.033) ·
C → C (0.859) · PB → PB (1.046) · E → E (0.783, low n) · T and **defective** beans → F+AF+TT+UG pooled (0.725).
Rationale: at the curing mill, small, broken and defective beans end up in the low grades; TT (light density) can't be
seen in a photo, so it is pooled rather than detected.

**Grade mix → price (how Price Check uses this):** `mix_ratio = Σ (share of beans in class × class ratio)`, then
`farm-gate estimate = §3 range × mix_ratio`. Example (illustrative only, not measured): 30 % AA, 40 % AB, 15 % C,
10 % PB, 5 % defective → 0.999 → about TZS 5,700–8,500. A poorer sample of 10 % AA, 30 % AB, 35 % C, 25 % defective
→ 0.897 → about TZS 5,100–7,600.

## 5. Limitations (shown or summarised in the app)

1. **Not a buyer's offer.** Every price is labelled "Makadirio / Estimate", always with source and date.
2. **The farm-gate share comes from 2005–2010.** Market structure and margins may have changed since. A current
   official Tanzanian farm-gate parchment price would replace it. **Not found yet.**
3. **Grade premiums are auction-level.** Middlemen at the farm gate often pay one price for all parchment (FAO MAFAP:
   "buyers tend to offer only one price for all beans"). Grade information helps Noor *ask* or go to the cooperative;
   it doesn't guarantee a higher price.
4. **Season-start sample.** S2 covers only the first 4 auctions of 2026/27, mostly Mbeya/Songwe and Moshi lots. Ratios
   will move during the season.
5. **Quality the photo can't see:** moisture, cup quality, density (TT), smell. Local premiums (certified, specialty,
   direct trade) aren't included.
6. **Two different reference prices.** The Pink Sheet (7.26, Sep 2026, NY/Bremen ex-dock) is higher than the Moshi
   auction (6.0–6.5, Sep 2026). The share in §2 was computed against the Pink Sheet, so the two stay consistent.
   Don't mix them.
7. **Exchange rate** is from one day; parchment volume/moisture deductions by buyers are not modelled.

## 6. Refresh

`fetch_sources.py` (Pink Sheet + TCB PDFs) → update `sources/manual_inputs.json` FX by hand (with date) →
`build_snapshot.py <today>` → `pytest` → commit the new `SNAPSHOT_<date>.json`. The app shows "price is N days old"
after 45 days (`docs/WORKFLOW.md` §10).
