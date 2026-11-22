# CareLoop Clinics — No-Show Guard

**Submission repository URL:** `https://github.com/balajiramaswami59-star/CareLoop-NoShow-Guard`

## Four-part summary

1. **Python:** Cleaned **1,020** original appointment records into **990** unique valid bookings; rejected **32** rows in the separate csv-module type-check exercise.
2. **SQL:** **218/990 (22.0%)** appointments were missed. The highest observed clinic rate was **33.3% (30/90)** at Gomti Nagar Care Point, while Hadapsar Care Centre recorded **27.3% (39/143)**.
3. **Machine learning:** Training-fold CV selected **Logistic regression** (CV ROC-AUC **0.774**). At the training-selected threshold **0.35**, held-out ROC-AUC was **0.789**, precision **57.1%**, recall **57.1%**, with **49** flagged bookings.
4. **GenAI:** Of 30 source notes, Gemini returned **6 valid classifications**. One blank note (N004) was skipped, 3 requests failed, and 20 notes remain unprocessed. API execution stopped after HTTP 402 confirmed that prepaid credits were depleted. The available classifications were joined to the appointment data with **0 missing matches**.

## Business recommendation

CareLoop should pilot targeted follow-up for patients
with longer appointment lead times. The validated SQL
results show a no-show rate of **34.46% (102/296)**
for appointments booked **15+ days** in advance,
compared with **10.39% (8/77)** for appointments
booked **0–2 days** in advance.

Prioritize a capacity-limited pilot at Gomti Nagar Care
Point (**30/90, 33.33%**) and Hadapsar Care Centre
(**39/143, 27.27%**).

The selected Logistic Regression model achieved
**ROC-AUC 0.789**, precision **57.14%**, and recall
**57.14%** at threshold **0.35**. It flagged 49 test
appointments and identified 28 of 49 test no-shows.

Among the six valid Gemini classifications, distance
or transport appeared twice; forgetting/reminders,
cost, illness/emergency, and work/scheduling appeared
once each. Four of these six appointments had received
reminders. These small counts are illustrative and
should not be generalized to all patients.

Evaluate any intervention prospectively using staff
capacity, completed appointments, rebooking rates,
and recovered appointment slots.

## Model selection and reproducibility

The full cleaned table is sorted by `appointment_id` before the exact `train_test_split(test_size=0.2, random_state=42)` operation. All model and threshold choices are based on training-only 5-fold validation, never test results. Training CV ROC-AUC: logistic **0.774**, depth-3 tree **0.678**, random forest **0.747**, tuned forest **0.767**. The threshold **0.35** was selected by higher out-of-fold F1. Test evaluation was performed once. `test_risk_scores.csv` contains the held-out predictions.

## Limitations

- The 30 source notes are not necessarily representative of all no-show reasons. Only six valid Gemini classifications were obtained. All classifications require human review before operational use.
- Gemini API processing was interrupted by HTTP 402 (depleted prepaid credits). Three requests failed and 20 notes remain pending. No results were invented.
- Median imputation and IQR caps were computed on all 990 rows before the train/test split, causing minor test-to-train preprocessing leakage. In production, fit these transformations only on training data.
- A random split can place the same patient in both partitions and does not simulate training on past appointments to predict future ones. Use patient-grouped, time-forward validation before deployment.
- Reminder associations in observational data do not prove reminders cause lower no-show rates. A production threshold should be calibrated to actual call capacity.

## Repository structure

- Original assignment datasets are included in `data/`: `appointments.csv`, `clinics.csv`, and `followup_notes.csv`. These files are included in this repository for reproducibility.
- `01_ingest_clean.ipynb` — Tasks 1.1–1.6, including Open-Meteo requests.
- `rejected_rows.json`, `appointments_clean.csv`, `clinics_enriched.csv`, `load_data.sql` — Part 1 handoffs.
- `02_queries.sql` — MySQL 8 schema and Tasks 2.1–2.5.
- `03_model.ipynb`, `test_risk_scores.csv`, `model_metrics.json` — Part 3.
- `04_genai.ipynb` — Part 4 execution notebook.
- `notes_analysed_status.csv` — 30-row status tracker preserving valid, failed, skipped, and pending records.
- `genai_analysis_summary.json` — verified partial GenAI analysis summary.
- `notes_analysed.csv` — first 10 notes: 6 valid Gemini classifications, 1 blank note skipped, and 3 API-blocked records. This is a partial AI result, not 10 successful classifications.

## How to reproduce

1. Install the required Python packages:
   `pandas numpy scikit-learn requests google-genai pydantic`.

2. Run `01_ingest_clean.ipynb` to reproduce the cleaned
   appointment and clinic datasets. The supplied
   `appointments_clean.csv` contains 990 records.
   The included offline SQL load file uses NULL
   temperatures where live weather measurements
   were unavailable.

3. Load `load_data.sql` into the MySQL `noshowguard`
   database, then run `02_queries.sql`.
   The reporting queries were executed successfully
   against MySQL with no reported SQL errors.
   Refer to `sql_validation_output.txt` for results.

4. Run `03_model.ipynb` to reproduce model selection,
   training-fold cross-validation and held-out metrics.
   The selected model is Logistic Regression.

5. `04_genai.ipynb` contains the actual Gemini API
   execution history. Of 30 notes, six were classified
   successfully, one was skipped, three failed,
   and 20 remain pending. HTTP 402 stopped further
   processing because prepaid credits were depleted.
   See `notes_analysed_status.csv` and
   `genai_analysis_summary.json`.
   Do not represent pending notes as classified.

6. Review notebook outputs and remove credentials,
   tokens and sensitive information before publishing.
   The public GitHub repository URL is
   actual public repository URL.

**Privacy:** Example data is supplied by the assignment. Never commit Gemini API keys. In real clinical deployments, remove direct identifiers and obtain appropriate approvals before sending patient notes to an external model.
