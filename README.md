# Recruiting Data Pipeline (Cloudflare D1)

Built during my data science internship at HireBeat: an applicant-tracking backend on Cloudflare D1 (SQLite). The pipeline turns raw application-form exports and resume PDFs into a normalized candidate database. On top of that it runs ML scoring and a configurable recruitment-stage pipeline, from application through offer.

## Notebooks

| # | Notebook | Purpose |
|---|---|---|
| 1 | `01_scrape_linkedin_jobs.ipynb` | Selenium scraper for LinkedIn's public job search (1,402 postings). Fills the Company and Position reference tables. |
| 2 | `02_extract_resume_text.ipynb` | Downloads each applicant's resume PDF from the form export and extracts its text with PyMuPDF. |
| 3 | `03_merge_submissions.ipynb` | Normalizes the form's emoji headers and joins the export with the resume text to form a raw submission batch. |
| 4 | `04_d1_recruiting_pipeline.ipynb` | The main pipeline on D1; its stages are listed below. |

### Stages in notebook 4

1. **Schema**: drop and create the full schema from `create.sql` / `drop.sql` through the D1 HTTP API.
2. **Reference data**:
   - LinkedIn jobs go into `Company`, `Position` and `Position_salary_range`. Salary is parsed from the JD and stored in integer cents.
   - About 14k skills from three dictionaries go into `Skill`, typed as Language, Technology or Function.
3. **Raw ingestion**: each `Ingestion_batch` stores rows verbatim, with a SHA-256 of each record for audit and replay.
4. **Normalization**:
   - Field cleaning and email validation (including a DNS MX lookup).
   - Rank-based matching of the free-text company and position fields against reference positions.
5. **Resume parsing**: a rule-based parser extracts education, employment, links, emails, phones and skills matched to the `Skill` table.
6. **Duplicate detection**: identity features and match evidence group repeat submissions into application clusters.
7. **Candidate / Person layer**:
   - `Application` and `Candidate_snapshot` rows, with a `Person` table that points at its latest snapshot.
   - Name, contact and link history for each person.
   - Education, employment, skill and project tables, with a highest-degree audit.
8. **ML**: an application feature table drives four steps:
   - candidate-profile clustering
   - a rule-based scorecard
   - anomaly detection
   - sentence-embedding similarity ranking of each candidate against the JD

   Offers are then selected per position group.
9. **Recruitment workflow**: a 13-stage pipeline (received → screening → ML recommendation → assessments → interviews → offer → hired/rejected/withdrawn) with 87 allowed transitions.
10. **ML results import**: ML outputs are written back into the workflow.

Database size after the full load:

| Table | Rows |
|---|---|
| Application | 1,049 |
| Person | 1,030 |
| Candidate_Skill | 3,170 |
| Candidate_Education | 1,332 |
| Person_Project | 965 |

## Configuration

Notebook 4 runs in Google Colab. Add these Colab Secrets: `CLOUDFLARE_KEY` (API token), `CLOUDFLARE_ACCOUNT_ID` and `D1_DATABASE_ID`.

The repository mirrors the Google Drive project folder. Copy it to `/content/drive/MyDrive/recruiting-pipeline/` and add your own data under `datasets/`:

```
recruiting-pipeline/
├── create.sql                          # full schema (81 tables + indexes)
├── drop.sql                            # drops every table (irreversible)
├── alter_dataset_type_contains_pii.sql # one-off migration run before raw ingestion
├── code/
│   ├── resume_text_parser.py           # rule-based resume section parser
│   ├── resume_skill_matcher.py         # matches resume text to the Skill table
│   └── fetch_successful_submission_from_db.py
├── datasets/
│   ├── Language_Skills.csv             # skill dictionaries (committed)
│   ├── Technical_Skills.csv
│   ├── Function_Skills.csv
│   ├── linkedin_jobs_english.csv       # from notebook 1 (not committed)
│   └── <raw submission batch>.csv      # from notebook 3 (not committed)
└── notebooks/
```

## Data and privacy

Only the three skill dictionaries are committed. Application exports, resumes and every derived table contain real applicants' personal information, so cell outputs that showed candidate records have been cleared. Only aggregate outputs (counts, run summaries) remain.

Inline comments in notebook 4 are in Chinese.
