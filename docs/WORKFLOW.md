# Ondera Leaf Walk — Workflow spec

This is the single source of truth for screens, fixed messages, rules and templates. Code must match it; if code needs to differ, update this file in the same PR (additive changes only, see `CLAUDE.md`).

> ⚠ **All Swahili text in this file is a DRAFT written by non-native speakers/AI and must be reviewed by a native Swahili speaker** (track in `docs/SWAHILI_REVIEW.md`). Agronomic wording (thresholds, keywords, disease names) must also be checked by someone with coffee extension knowledge. Items marked **[verify]** are unconfirmed.

---

## 1. Users and context

- **Noor** — coffee smallholder, 2 ha, Swahili at home. Uses her daughter's iPhone **on weekends**; her own basic phone (calls/SMS/mobile money) on weekdays. No Wi-Fi; buys 3G bundles occasionally. Out on the slope most of the day.
- **Cooperative officer** — receives walk-report SMS in the coop inbox (backend web page).
- **Extension officer** — visits rarely; gets flagged trees by SMS and looks at the photos **on Noor's phone** when visiting.

## 2. Screens

### Setup (first time, or "new field")
| ID | Screen | Content | Rules |
|---|---|---|---|
| S0 | Home | Start new walk · Continue walk (if in progress) · Past walks · Outbox · Settings | Big buttons, icons + text + audio. |
| S1 | Language | Kiswahili (default) / English | Saved; changes app immediately. |
| S2 | Consent | Text §8.1, audio button, **Ninakubali / Si sasa** | Walk impossible without consent. Withdraw in Settings. |
| S3 | Field boundary | "Walk around the edge of your coffee field." Start / Finish. Live track, GPS accuracy, area (ha). | Accuracy ≤ 15 m kept; polygon closed + simplified; self-intersecting or < 0.02 ha → fixed retry message. Simulate mode loads `SYNTHETIC_sample_field.geojson`. |
| S4 | Problem spots (optional) | "Mark places where you have seen sick trees." Mark here (GPS) / tap on map / Skip. | Default radius 10 m. 0–3 spots typical. |
| S5 | Route preview | Field + W route + 10 numbered stops. "Start walk". | Re-plan button (new random offset). Seed stored in session. |

### Walk
| ID | Screen | Content | Rules |
|---|---|---|---|
| S6 | Walk map | Map (MapKit or offline drawing), "Kituo 3 kati ya 10", distance + arrow to next stop. | Arrival = within max(5 m, GPS accuracy) → **vibrate** + audio + open S7. Simulate mode moves position automatically. |
| S7 | Stop instructions | Illustration + audio: nearest tree, **lower third**, **3rd–4th leaf pair**, check **10 leaves** (UH CTAHR pd-125 protocol). | "Skip this stop" → reason (no tree / can't reach / other) recorded. |
| S8 | Leaf count | "How many of the 10 leaves have spots?" Buttons 0–10 (≥ 60 pt). Confirm. | Count stored exactly as tapped; AI never changes it. 0 → stop GREEN, next stop. > 0 → S9. |
| S9 | Camera | Live camera with leaf outline. "Put the worst leaf inside the outline." | Simulator: pick fixture image. |
| S10 | Photo check | GREEN "Picha nzuri" or RED "Piga tena: <reason>" (§4). | Max 3 retakes, then "Continue without a good photo" (→ AMBER via fusion F2). |
| S11 | Voice note (optional) | Hold to record (≤ 15 s): "Describe what you see". Detected words shown as chips she can remove; or tap chips manually. | Audio stays on phone. Skip allowed. |
| S12 | Stop result | GREEN: "<disease> (the app can be wrong)" / healthy. AMBER: "Sina uhakika — mti umewekwa alama kwa afisa ugani." | From fusion rules §5. "Next stop" button. Saved after every stop. |

### End
| ID | Screen | Content | Rules |
|---|---|---|---|
| S13 | Summary | Incidence ("12 of 100 leaves had spots — 12%"), 95% interval in words + bar with 5% line, coloured stop map, recommendation (§6) with audio, flagged trees list, pricing panel (§10), "Demo data" badge if synthetic. | Skipped stops reduce n; shown as grey. |
| S14 | Send to cooperative | Exact SMS text (§7.1), char count, recipient. **Confirm / Cancel.** | Only on confirm → outbox. Status: "Waiting for signal" / "Sent". |
| S15 | Check again next Saturday | "Remind you on Saturday <date> at 08:00?" Confirm / Cancel. | Notification permission requested only here. |
| S16 | Ask extension officer | Officer SMS preview (§7.2) + Confirm/Cancel; list of flagged trees with photos **to show in person**. | Photos never sent. |
| S17 | Outbox | Queued / Sent / Failed, retry, cancel. | |
| S18 | Settings | Language, simulate walk, backend URL, withdraw consent, delete all data. | |

### Weekday (basic phone, mock)
| ID | Channel | Content |
|---|---|---|
| W1 | SMS to Noor's basic phone (mock web page) | Check-in §7.3. Replies 1/2/3 parsed by fixed rules → coop inbox. Labelled MOCK. |

### Stretch (cooperative)
| ID | Channel | Content |
|---|---|---|
| X1 | Coop inbox page | Variogram-based neighbour alerts on **SYNTHETIC** multi-farm data, fixed alert text §9. Officer decides whether to send. |

## 3. Route rules (Task 13)

1. Project boundary to local metres (equirectangular around centroid).
2. Long axis = orientation of the minimum-area bounding rectangle (PCA acceptable).
3. **Skip edge rows**: inset the polygon by `edgeBuffer = edgeRows × rowSpacing` (defaults: 2 rows × 2.5 m **[verify typical spacing]**). If the inset polygon is empty/too small, halve the buffer (down to 0) and record a warning.
4. W polyline: 5 vertices at 0, ¼, ½, ¾, 1 of the long-axis length, alternating between the two long sides of the inset rectangle, clipped to the inset polygon.
5. **10 stops** spaced evenly along the W by arc length, with a **random start offset** `u ∈ [0, spacing)` from a seeded RNG (seed stored in the session).
6. Every **problem spot** must contain ≥ 1 stop: for each spot with none, move the nearest not-yet-assigned stop to the spot centre. Then re-order stops by their projection onto the W path.
7. All stops inside the field polygon. Output is deterministic for a given (boundary, spots, seed).

## 4. Photo quality gate (Tasks 17–18)

Computed on the outline crop. First failing check wins, in this order:

| Order | Check | Metric | Default threshold (until Task 17 tunes) | RED message key |
|---|---|---|---|---|
| 1 | Leaf fills outline | fraction of outline mask that is leaf-coloured (green + yellow/brown tissue) | ≥ 0.55 | `quality.leafNotFilling` |
| 2 | Sharp | variance of Laplacian (grayscale, downscaled to 512 px long side) | ≥ 100 **[tune]** | `quality.blurry` |
| 3 | Not too dark | mean luma; % pixels < 10 | mean ≥ 60 and dark% < 20% | `quality.tooDark` |
| 4 | Not too bright | mean luma; % pixels > 245 | mean ≤ 200 and bright% < 15% | `quality.tooBright` |

Pass → GREEN `quality.good`. Thresholds live in `Resources/thresholds.json` (written by Task 17).

## 5. Fusion rules (Task 20)

Inputs: **C** = Noor's count (0–10) · **Q** = photo quality (good / none-after-retakes) · **K, p** = classifier top class and confidence · **V** = set of classes hinted by voice keywords (generic words like *madoa* add no class; empty = no voice or no class words).
Defaults: `T_high = 0.80`, `T_low = 0.60` **[replace with Task 11 tuned values]**.
Evaluate top to bottom; **first match wins**. Noor's count is never changed.

| # | Condition | Verdict | Reason key | Flag for officer |
|---|---|---|---|---|
| F1 | C = 0 and V empty | GREEN — healthy, no photo | `verdict.noSpots` | no |
| F2 | C = 0 and V not empty | AMBER | `verdict.countVoiceDisagree` | yes |
| F3 | C > 0 and no good photo after 3 tries | AMBER | `verdict.photoUnclear` | yes |
| F4 | C > 0 and (K = unknown or p < T_low) | AMBER | `verdict.lowConfidence` | yes |
| F5 | C > 0 and K = healthy | AMBER | `verdict.countPhotoDisagree` | yes |
| F6 | V not empty and K ∉ V | AMBER | `verdict.photoVoiceDisagree` | yes |
| F7 | p ≥ T_high (V empty or K ∈ V) | GREEN — label K | `verdict.confident` | no |
| F8 | T_low ≤ p < T_high and K ∈ V | GREEN — label K | `verdict.voiceConfirms` | no |
| F9 | T_low ≤ p < T_high and V empty | AMBER | `verdict.mediumConfidence` | yes |

AMBER always shows: **"Sina uhakika — mti umewekwa alama kwa afisa ugani."** / "Not sure — tree flagged for the extension officer."

### Classes
`healthy`, `rust` (coffee leaf rust, *Hemileia vastatrix*), `leafMiner` (*Leucoptera* spp.), `cercospora` (brown eye spot), `phoma` (Phoma leaf spot **[verify mapping from BRACOL "brown leaf spot"]**), `unknown`.

### Keywords (~10, Task 9) — ⚠ native + agronomist review
| Keyword (sw) | Meaning | Class hint |
|---|---|---|
| kutu | rust | rust |
| unga | powder | rust |
| chungwa | orange (colour) | rust |
| njano | yellow | rust |
| jicho | eye (eye-spot) | cercospora |
| duara | circle / round | cercospora |
| mistari | lines / trails | leafMiner |
| funza | larva / grub | leafMiner |
| nyeusi | black | phoma |
| kavu | dry | phoma |
| madoa | spots | — (generic) |
| kahawia | brown | — (generic) |

## 6. Summary and fixed recommendations (Tasks 21–22)

- **Incidence** `p̂ = x / n`, x = Σ leaves with spots, n = Σ leaves checked (10 × checked stops).
- **95% Wilson interval**, z = 1.959964.
- **Treatment threshold** `T = 5%` leaf incidence — example threshold from UH CTAHR pd-125 **[verify exact value and wording in pd-125 before demo]**.
- Consequence to know (not a bug): with n = 100, **0/100 → LOW, 1–9/100 → CLOSE (interval straddles 5%), ≥ 10/100 → ABOVE**.

Rules, first match wins:

| ID | Condition | Swahili (draft) | English |
|---|---|---|---|
| `rec.notEnough` | fewer than 6 stops checked (n < 60) | Vituo vichache sana vimeangaliwa. Hatuwezi kusema kwa uhakika. Rudia matembezi au muulize afisa ugani. | Too few stops were checked to be sure. Repeat the walk or ask the extension officer. |
| `rec.above` | Wilson lower bound ≥ T | Madoa yako yako juu ya kiwango cha kutibu ({p}%). Ongea na afisa ugani au chama cha ushirika kuhusu matibabu wiki hii. | Spots are above treatment level ({p}%). Talk to the extension officer or cooperative about treatment this week. |
| `rec.close` | lower < T ≤ upper | Madoa yako yako karibu na kiwango cha kutibu ({p}%, huenda kati ya {lo}% na {hi}%). Angalia tena Jumamosi ijayo na muulize afisa ugani. | Spots are close to treatment level ({p}%, probably between {lo}% and {hi}%). Check again next Saturday and ask the extension officer. |
| `rec.low` | upper bound < T | Madoa ni machache ({p}%). Hakuna haja ya kutibu sasa. Angalia tena Jumamosi ijayo. | Few spots ({p}%). Below treatment level for now. Check again next Saturday. |

Add-ons (appended, fixed text):
| ID | Condition | Swahili (draft) | English |
|---|---|---|---|
| `rec.addUnsure` | ≥ 3 AMBER trees | Miti {k} ina shaka — afisa ugani aiangalie. | {k} trees are uncertain — ask the extension officer to look at them. |
| `rec.addDisease` | ≥ 2 GREEN stops share the same disease label | Madoa mengi yanaonekana kama {disease}. Programu inaweza kukosea. | Most spots look like {disease}. The app can be wrong. |

### Stop colours (map + list)
grey = not checked/skipped · green = 0 spotted leaves · red = ≥ 1 spotted leaf (darker for higher counts) · amber ring = flagged "not sure" (combines with red).

## 7. SMS templates (≤ 160 chars, GSM-7 only, farmer ID never name)

### 7.1 Walk report to cooperative (Task 23)
```
OLW {farmerId} {dd/mm/yy} Madoa {x}/{n}={p}% ({lo}-{hi}%) {REC} Shaka:{amber} Vituo:{checked}/10 {top2Diseases}
```
- `{REC}` ∈ `CHINI` (low) · `KARIBU` (close) · `JUU` (above) · `HAIJULIKANI` (not enough).
- `{top2Diseases}` = up to two `Name:count` pairs from GREEN stops (e.g. `Kutu:3 Mchimbaji:1`); dropped first if over 160.
- Example (86 chars): `OLW F0123 03/10/26 Madoa 12/100=12% (7-20%) JUU Shaka:2 Vituo:10/10 Kutu:3 Mchimbaji:1`
- Worst case measured at 101 chars.

### 7.2 Ask extension officer (Task 23)
```
OLW {farmerId} {dd/mm/yy} AFISA: miti {k} ina shaka, vituo {stopList}. Madoa {x}/{n}. Tafadhali tembelea shamba.
```
Worst case (k = 10) = 114 chars.

### 7.3 Weekday check-in to Noor's basic phone (Task 6, MOCK)
```
Ondera: Habari. Jumamosi shamba lako lilikuwa na madoa {p}%. Miti {k} inasubiri afisa ugani. Jibu 1=Madoa mapya 2=Hali sawa 3=Nipigie simu
```
Worst case = 137 chars. Replies: `1` → "new spots" (coop sees flag), `2` → "same", `3` → "call me"; anything else → fixed reply "Samahani, hatukuelewa. Jibu 1, 2 au 3." (Sorry, we didn't understand. Reply 1, 2 or 3.)

## 8. Swahili prompts (spoken + on-screen) — ⚠ DRAFT, native review required

### 8.1 Consent (`consent.body`)
> **sw:** Programu hii inakusaidia kuangalia majani ya kahawa. Picha na sauti zako zinabaki kwenye simu hii tu — hazitumwi popote. Hakuna ujumbe utakaotumwa bila wewe kubonyeza "Thibitisha". Programu inaweza kukosea; ikiwa haina uhakika itasema "Sina uhakika" na kupendekeza afisa ugani. Unaweza kufuta data yako wakati wowote. Unakubali?
> **en:** This app helps you check coffee leaves. Your photos and voice stay on this phone only — they are never sent anywhere. No message is sent unless you press "Confirm". The app can be wrong; when it is not sure it will say "Not sure" and suggest the extension officer. You can delete your data at any time. Do you agree?

### 8.2 Prompts
| Key | English | Swahili (draft) | Audio |
|---|---|---|---|
| `lang.choose` | Choose language | Chagua lugha | yes |
| `consent.agree` / `consent.notNow` | I agree / Not now | Ninakubali / Si sasa | yes |
| `boundary.instruction` | Walk around the edge of your coffee field. | Tembea kuzunguka mpaka wa shamba lako la kahawa. | yes |
| `boundary.start` / `boundary.finish` | Start / Finish | Anza / Maliza | — |
| `boundary.retry` | The field shape is not clear. Please walk the edge again. | Umbo la shamba halijaeleweka. Tafadhali tembea mpakani tena. | yes |
| `spots.instruction` | Mark places where you have seen sick trees. | Weka alama mahali ulipoona miti yenye ugonjwa. | yes |
| `spots.markHere` / `spots.skip` | Mark here / Skip | Weka alama hapa / Ruka | — |
| `route.start` | Start walk | Anza matembezi | yes |
| `walk.stopOf` | Stop {k} of 10 | Kituo {k} kati ya 10 | — |
| `walk.arrived` | You have arrived at stop {k}. | Umefika kituo cha {k}. | yes |
| `stop.instruction` | Choose the nearest tree. Look at the lower third of the tree. Check 10 leaves from the 3rd or 4th pair. | Chagua mti ulio karibu. Angalia sehemu ya chini ya mti. Kagua majani 10 ya jozi ya tatu au ya nne. | yes |
| `stop.skip` | Skip this stop | Ruka kituo hiki | — |
| `count.question` | How many of the 10 leaves have spots? | Majani mangapi kati ya 10 yana madoa? | yes |
| `camera.instruction` | Put the worst leaf inside the outline. | Weka jani lililoathirika zaidi ndani ya mstari. | yes |
| `quality.good` | Good photo | Picha nzuri | yes |
| `quality.blurry` | Retake: the photo is blurry. Hold the phone still. | Piga tena: picha haiko wazi. Shika simu bila kutikisika. | yes |
| `quality.tooDark` | Retake: too dark. Move into the light. | Piga tena: kuna giza sana. Sogea kwenye mwanga. | yes |
| `quality.tooBright` | Retake: too bright. Shade the leaf. | Piga tena: kuna mwanga mwingi. Weka kivuli juu ya jani. | yes |
| `quality.leafNotFilling` | Retake: bring the leaf closer so it fills the outline. | Piga tena: sogeza jani karibu lijaze mstari. | yes |
| `quality.continueAnyway` | Continue without a good photo | Endelea bila picha nzuri | — |
| `voice.instruction` | Optional: hold and describe what you see. | Si lazima: bonyeza na ueleze unachokiona. | yes |
| `verdict.notSure` | Not sure — tree flagged for the extension officer. | Sina uhakika — mti umewekwa alama kwa afisa ugani. | yes |
| `verdict.mayBeWrong` | {disease}. The app can be wrong. | {disease}. Programu inaweza kukosea. | yes |
| `verdict.healthy` | No spots. | Hakuna madoa. | yes |
| `next.stop` | Next stop | Kituo kinachofuata | — |
| `end.incidence` | {x} of {n} leaves had spots ({p}%). | Majani {x} kati ya {n} yalikuwa na madoa ({p}%). | yes |
| `end.interval` | Probably between {lo}% and {hi}%. | Huenda ni kati ya {lo}% na {hi}%. | yes |
| `next.sendCoop` | Send to cooperative | Tuma kwa chama cha ushirika | yes |
| `next.checkSaturday` | Check again next Saturday | Angalia tena Jumamosi ijayo | yes |
| `next.askOfficer` | Ask extension officer | Muulize afisa ugani | yes |
| `sms.confirm` / `sms.cancel` | Confirm / Cancel | Thibitisha / Ghairi | yes |
| `outbox.waiting` | Waiting for signal — will send when there is network. | Inasubiri mtandao — itatumwa mtandao ukipatikana. | yes |
| `outbox.sent` | Sent | Imetumwa | yes |
| `demo.badge` | Demo data | Data ya mfano | — |
| `price.estimate` | Estimate | Makadirio | — |

### Disease display names — ⚠ review
| Class | Swahili (draft) | SMS short |
|---|---|---|
| healthy | Jani zima | Zima |
| rust | Kutu ya majani | Kutu |
| leafMiner | Mchimbaji wa majani | Mchimbaji |
| cercospora | Doa la jicho (Cercospora) | Jicho |
| phoma | Phoma | Phoma |
| unknown | Haijulikani | Haijul |

## 9. Cooperative alerts (stretch, Task 27) — SYNTHETIC data only
| ID | Condition | Text (sw draft / en) |
|---|---|---|
| `alert.neighbours` | ≥ 2 farms within fitted variogram range above T | Kutu inaongezeka karibu nawe — angalia shamba lako Jumamosi hii. / Rust is rising near you — check your field this Saturday. |
Officer must confirm before any alert is sent.

## 10. Pricing panel (Tasks 24–26)

Values come only from `docs/PRICING.md` (cited). If the farm-gate conversion factors are not cited, show only the reference line.

```
sw: Bei ya marejeo duniani: {value} {unit} — {source}, {month year}.
    Makadirio ya bei shambani: {currency} {low}–{high} kwa kilo ya {form}.
    Makadirio tu — si bei ya mnunuzi. Imesasishwa: {fetchedDate}.
en: World reference price: {value} {unit} — {source}, {month year}.
    Rough farm-gate estimate: {currency} {low}–{high} per kg of {form}.
    Estimate only — not a buyer's offer. Updated: {fetchedDate}.
stale (> 45 days): sw: Bei hii ina siku {d}. / en: This price is {d} days old.
```
Source and date are always visible; the word "Makadirio / Estimate" is always visible.
