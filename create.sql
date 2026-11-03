PRAGMA defer_foreign_keys=TRUE;
CREATE TABLE IF NOT EXISTS "Function" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "function_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Seniority" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "seniority_name" TEXT NOT NULL,
  "seniority_experience_average" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Experience_level" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "experience_level" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Contact_type" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "contact_type_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Skill_type" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "skill_type_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Skill" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "skill_name" TEXT NOT NULL,
  "skill_type_id" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("skill_type_id") REFERENCES "Skill_type"("id")
);
CREATE TABLE IF NOT EXISTS "Skill_proficiency_level" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "proficiency_level_name" TEXT NOT NULL,
  "proficiency_level_rank" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Certification_type" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "certification_type_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Issuing_organization" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "organization_name" TEXT NOT NULL,
  "organization_url" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Certification" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "certification_name" TEXT NOT NULL,
  "certification_type_id" INTEGER,
  "issuing_organization_id" INTEGER,
  "certification_url" TEXT,
  "typical_validity_years" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("certification_type_id") REFERENCES "Certification_type"("id"),
  FOREIGN KEY ("issuing_organization_id") REFERENCES "Issuing_organization"("id")
);
CREATE TABLE IF NOT EXISTS "Country" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "country_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Region" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "region_name" TEXT NOT NULL,
  "country_id" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("country_id") REFERENCES "Country"("id")
);
CREATE TABLE IF NOT EXISTS "State" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "state_name" TEXT NOT NULL,
  "state_code" TEXT,
  "region_id" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("region_id") REFERENCES "Region"("id")
);
CREATE TABLE IF NOT EXISTS "City" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "city_name" TEXT NOT NULL,
  "state_id" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("state_id") REFERENCES "State"("id")
);
CREATE TABLE IF NOT EXISTS "Timezone" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "timezone_name" TEXT NOT NULL,
  "utc_offset" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Location" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "country_id" INTEGER,
  "region_id" INTEGER,
  "state_id" INTEGER,
  "city_id" INTEGER,
  "timezone_id" INTEGER,
  "zipcode" TEXT,
  "created_at" TEXT,
  "updated_at" TEXT,
  FOREIGN KEY ("country_id") REFERENCES "Country"("id"),
  FOREIGN KEY ("region_id") REFERENCES "Region"("id"),
  FOREIGN KEY ("state_id") REFERENCES "State"("id"),
  FOREIGN KEY ("city_id") REFERENCES "City"("id"),
  FOREIGN KEY ("timezone_id") REFERENCES "Timezone"("id")
);
CREATE TABLE IF NOT EXISTS "Degree" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "degree_name" TEXT NOT NULL,
  "degree_level_rank" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Field_study" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "field_study_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Major" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "major_name" TEXT NOT NULL,
  "field_study_id" INTEGER,
  "is_stem" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("field_study_id") REFERENCES "Field_study"("id")
);
CREATE TABLE IF NOT EXISTS "School" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "school_name" TEXT NOT NULL,
  "school_url" TEXT,
  "school_type" TEXT,
  "school_category" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Education" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "degree_id" INTEGER,
  "school_id" INTEGER NOT NULL,
  "field_study_id" INTEGER,
  "major_id" INTEGER,
  "is_current" INTEGER,
  "education_start_date" TEXT,
  "education_end_date" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL, "raw_school_name" TEXT, "raw_degree_name" TEXT, "raw_field_study_name" TEXT, "raw_major_name" TEXT, "gpa" TEXT, "education_description" TEXT,
  FOREIGN KEY ("degree_id") REFERENCES "Degree"("id"),
  FOREIGN KEY ("school_id") REFERENCES "School"("id"),
  FOREIGN KEY ("field_study_id") REFERENCES "Field_study"("id"),
  FOREIGN KEY ("major_id") REFERENCES "Major"("id")
);
CREATE TABLE IF NOT EXISTS "School_location" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "school_id" INTEGER NOT NULL,
  "location_id" INTEGER NOT NULL,
  "campus_name" TEXT,
  "is_main_campus" INTEGER,
  "created_at" TEXT,
  "updated_at" TEXT,
  FOREIGN KEY ("school_id") REFERENCES "School"("id"),
  FOREIGN KEY ("location_id") REFERENCES "Location"("id")
);
CREATE TABLE IF NOT EXISTS "Company_industry_code" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "industry_code" INTEGER NOT NULL,
  "industry_name" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Company" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_name" TEXT NOT NULL,
  "company_website_url" TEXT,
  "company_domain" TEXT,
  "industry_id" INTEGER,
  "company_linkedin_url" TEXT,
  "company_facebook_url" TEXT,
  "company_twitter_url" TEXT,
  "company_logo_url" TEXT,
  "company_size_min" INTEGER,
  "company_size_max" INTEGER,
  "company_found_year" INTEGER,
  "company_total_funding_amount_cents" INTEGER,
  "company_latest_funding_amount_cents" INTEGER,
  "company_latest_funding_type" TEXT,
  "company_latest_funding_date" TEXT,
  "company_annual_revenue_amount_cents" INTEGER,
  "company_description" TEXT,
  "company_keywords" TEXT,
  "company_review_rating" REAL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("industry_id") REFERENCES "Company_industry_code"("id")
);
CREATE TABLE IF NOT EXISTS "Company_name_aliases" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_id" INTEGER NOT NULL,
  "company_name_alias" TEXT NOT NULL,
  "alias_type" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("company_id") REFERENCES "Company"("id")
);
CREATE TABLE IF NOT EXISTS "Company_location" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_id" INTEGER NOT NULL,
  "location_id" INTEGER NOT NULL,
  "location_type" TEXT,
  "location_name" TEXT,
  "is_hq" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("company_id") REFERENCES "Company"("id"),
  FOREIGN KEY ("location_id") REFERENCES "Location"("id")
);
CREATE TABLE IF NOT EXISTS "Company_contact_info" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_id" INTEGER NOT NULL,
  "contact_position_type" TEXT,
  "contact_name" TEXT,
  "contact_email" TEXT,
  "contact_phone" TEXT,
  "contact_url" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("company_id") REFERENCES "Company"("id")
);
CREATE TABLE IF NOT EXISTS "Company_work_mode" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_id" INTEGER NOT NULL,
  "work_mode_name" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("company_id") REFERENCES "Company"("id")
);
CREATE TABLE IF NOT EXISTS "Position_employment_type" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "employment_type_name" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Position_occupational_type" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "occupational_code" TEXT,
  "occupational_type_name" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Position" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "company_id" INTEGER NOT NULL,
  "position_name" TEXT NOT NULL,
  "position_jd" TEXT NOT NULL,
  "occupational_type_id" INTEGER,
  "employment_type_id" INTEGER,
  "min_required_duration" TEXT,
  "function_id" INTEGER NOT NULL,
  "seniority_id" INTEGER,
  "experience_level_id" INTEGER,
  "location_id" INTEGER,
  "position_status" TEXT,
  "openings_count" INTEGER,
  "posted_date" TEXT,
  "offers_relocation_assistance" INTEGER,
  "local_candidates_only" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("company_id") REFERENCES "Company"("id"),
  FOREIGN KEY ("function_id") REFERENCES "Function"("id"),
  FOREIGN KEY ("seniority_id") REFERENCES "Seniority"("id"),
  FOREIGN KEY ("experience_level_id") REFERENCES "Experience_level"("id"),
  FOREIGN KEY ("location_id") REFERENCES "Location"("id"),
  FOREIGN KEY ("occupational_type_id") REFERENCES "Position_occupational_type"("id"),
  FOREIGN KEY ("employment_type_id") REFERENCES "Position_employment_type"("id")
);
CREATE TABLE IF NOT EXISTS "Position_salary_range" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_id" INTEGER NOT NULL,
  "salary_min_cents" INTEGER,
  "salary_max_cents" INTEGER,
  "currency" TEXT,
  "salary_type" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("position_id") REFERENCES "Position"("id")
);
CREATE TABLE IF NOT EXISTS "Position_skill" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_id" INTEGER NOT NULL,
  "skill_id" INTEGER NOT NULL,
  "skill_requirement_type" TEXT,
  "min_proficiency_level_id" INTEGER,
  "onet_importance_score" REAL,
  "onet_dependence_score" REAL,
  "onet_preparation_score" REAL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("min_proficiency_level_id") REFERENCES "Skill_proficiency_level"("id"),
  FOREIGN KEY ("position_id") REFERENCES "Position"("id"),
  FOREIGN KEY ("skill_id") REFERENCES "Skill"("id")
);
CREATE TABLE IF NOT EXISTS "Position_education_requirement" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_id" INTEGER NOT NULL,
  "degree_id" INTEGER NOT NULL,
  "field_study_id" INTEGER,
  "is_required" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("position_id") REFERENCES "Position"("id"),
  FOREIGN KEY ("degree_id") REFERENCES "Degree"("id"),
  FOREIGN KEY ("field_study_id") REFERENCES "Field_study"("id")
);
CREATE TABLE IF NOT EXISTS "Position_certification_requirement" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_id" INTEGER NOT NULL,
  "certification_id" INTEGER NOT NULL,
  "is_required" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("position_id") REFERENCES "Position"("id"),
  FOREIGN KEY ("certification_id") REFERENCES "Certification"("id")
);
CREATE TABLE IF NOT EXISTS "Application_cluster" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_cycle_id" INTEGER NOT NULL UNIQUE,
  "cluster_code" TEXT NOT NULL,
  "display_name" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("application_cycle_id") REFERENCES "Position_application_cycle"("id")
);
CREATE TABLE IF NOT EXISTS "Hiring_pipeline" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "hiring_pipeline_name" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Pipeline_stage" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "pipeline_id" INTEGER NOT NULL,
  "pipeline_stage_name" TEXT NOT NULL,
  "stage_type" TEXT NOT NULL,
  "sequence_no" INTEGER NOT NULL,
  "is_initial" INTEGER NOT NULL,
  "is_terminal" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("pipeline_id") REFERENCES "Hiring_pipeline"("id")
);
CREATE TABLE IF NOT EXISTS "Application" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "application_cluster_id" INTEGER NOT NULL,
  "application_status" TEXT NOT NULL,
  "hiring_pipeline_id" INTEGER NOT NULL,
  "current_stage_id" INTEGER,
  "current_stage_entered_at" TEXT,
  "applied_at" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL, "company_id" INTEGER NOT NULL REFERENCES "Company"("id"), "position_id" INTEGER NOT NULL REFERENCES "Position"("id"), "applied_company_name" TEXT, "applied_position_name" TEXT, "application_cluster_display_name" TEXT,
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("application_cluster_id") REFERENCES "Application_cluster"("id"),
  FOREIGN KEY ("hiring_pipeline_id") REFERENCES "Hiring_pipeline"("id"),
  FOREIGN KEY ("current_stage_id") REFERENCES "Pipeline_stage"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_snapshot" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_id" INTEGER NOT NULL UNIQUE,
  "application_date" TEXT NOT NULL,
  "salary_expectation_min_cents" INTEGER,
  "salary_expectation_max_cents" INTEGER,
  "salary_expectation_currency" TEXT,
  "work_authorization_type" TEXT,
  "work_type" TEXT,
  "available_start_date" TEXT,
  "notice_period_days" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL, "expected_end_date" TEXT, "work_duration" TEXT, "raw_person_name" TEXT, "normalized_person_name" TEXT, "normalized_first_name" TEXT, "normalized_middle_name" TEXT, "normalized_last_name" TEXT, "raw_email_address" TEXT, "normalized_email_address" TEXT, "raw_phone" TEXT, "normalized_phone" TEXT, "raw_linkedin_url" TEXT, "normalized_linkedin_url" TEXT, "raw_github_url" TEXT, "normalized_github_url" TEXT, "raw_resume_text" TEXT,
  FOREIGN KEY ("application_id") REFERENCES "Application"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Education" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "education_id" INTEGER NOT NULL,
  "recorded_at" TEXT,
  "is_current" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("education_id") REFERENCES "Education"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Position" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "company_id" INTEGER,
  "position_id" INTEGER,
  "function_id" INTEGER,
  "seniority_id" INTEGER,
  "experience_level_id" INTEGER,
  "location_id" INTEGER,
  "position_start_date" TEXT,
  "position_end_date" TEXT,
  "experience_type" TEXT,
  "is_current" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"), "raw_company_name" TEXT, "normalized_company_name" TEXT, "raw_position_name" TEXT, "normalized_position_name" TEXT, "position_description" TEXT,
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("company_id") REFERENCES "Company"("id"),
  FOREIGN KEY ("position_id") REFERENCES "Position"("id"),
  FOREIGN KEY ("seniority_id") REFERENCES "Seniority"("id"),
  FOREIGN KEY ("experience_level_id") REFERENCES "Experience_level"("id"),
  FOREIGN KEY ("location_id") REFERENCES "Location"("id")
);
CREATE TABLE IF NOT EXISTS "Person" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_first_name" TEXT NOT NULL,
  "person_last_name" TEXT NOT NULL,
  "date_of_birth" TEXT,
  "email" TEXT,
  "phone" TEXT,
  "location_id" INTEGER,
  "highest_education_id" INTEGER,
  "current_position_id" INTEGER,
  "latest_candidate_id" INTEGER,
  "talent_pool_status" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("location_id") REFERENCES "Location"("id"),
  FOREIGN KEY ("highest_education_id") REFERENCES "Person_Education"("id"),
  FOREIGN KEY ("current_position_id") REFERENCES "Person_Position"("id"),
  FOREIGN KEY ("latest_candidate_id") REFERENCES "Candidate_snapshot"("id")
);
CREATE TABLE IF NOT EXISTS "Specific_open_window" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_application_cycle_id" INTEGER NOT NULL,
  "open_window_name" TEXT,
  "open_date" TEXT NOT NULL,
  "close_date" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("position_application_cycle_id") REFERENCES "Position_application_cycle"("id")
);
CREATE TABLE IF NOT EXISTS "raw_submission" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "ingestion_batch_id" INTEGER NOT NULL,
  "source_record_number" INTEGER NOT NULL,
  "source_record_id" TEXT,
  "raw_record_jsonb" TEXT NOT NULL,
  "raw_record_jsonb_sha256" TEXT NOT NULL,
  "processing_status" TEXT NOT NULL,
  "processing_error" TEXT,
  "landed_at" TEXT NOT NULL, raw_record_null_flags_utf_8 TEXT,
  FOREIGN KEY ("ingestion_batch_id") REFERENCES "Ingestion_batch"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_normalized" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "raw_submission_id" INTEGER NOT NULL,
  "application_cluster_id" INTEGER,
  "open_window_id" INTEGER,
  "company_id" INTEGER NOT NULL,
  "position_id" INTEGER NOT NULL,
  "application_cycle_id" INTEGER NOT NULL,
  "raw_person_name" TEXT,
  "raw_person_email_address" TEXT NOT NULL,
  "raw_person_phone" TEXT,
  "person_name_aliases" TEXT,
  "normalized_person_name" TEXT,
  "normalized_first_name" TEXT,
  "normalized_middle_name" TEXT,
  "normalized_last_name" TEXT,
  "normalized_email_prefix" TEXT,
  "normalized_email_domain" TEXT,
  "normalized_person_phone" TEXT,
  "normalized_phone_country_code" TEXT,
  "normalized_phone_region_code" TEXT,
  "normalized_phone_number" TEXT,
  "work_type" TEXT,
  "work_duration" TEXT,
  "start_working_date" TEXT,
  "end_working_date" TEXT,
  "normalization_status" TEXT,
  "normalized_at" TEXT,
  "warnings" TEXT,
  "submitted_at" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT, "normalized_company_name" TEXT, "normalized_position_name" TEXT, "normalized_application_cycle_name" TEXT,
  FOREIGN KEY ("raw_submission_id") REFERENCES "raw_submission"("id"),
  FOREIGN KEY ("application_cluster_id") REFERENCES "Application_cluster"("id"),
  FOREIGN KEY ("open_window_id") REFERENCES "Specific_open_window"("id"),
  FOREIGN KEY ("company_id") REFERENCES "Company"("id"),
  FOREIGN KEY ("position_id") REFERENCES "Position"("id"),
  FOREIGN KEY ("application_cycle_id") REFERENCES "Position_application_cycle"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Name" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "name_value" TEXT NOT NULL,
  "is_primary" INTEGER NOT NULL,
  "source_submission_id" INTEGER,
  "first_seen_at" TEXT NOT NULL,
  "last_seen_at" TEXT NOT NULL, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("source_submission_id") REFERENCES "Submission_normalized"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Contact" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "contact_type_id" INTEGER NOT NULL,
  "contact_value" TEXT NOT NULL,
  "is_primary" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("contact_type_id") REFERENCES "Contact_type"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Link" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "link_type" TEXT,
  "url" TEXT NOT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Skill" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "skill_id" INTEGER NOT NULL,
  "proficiency_level" TEXT,
  "proficiency_level_id" INTEGER,
  "years_experience" REAL,
  "recorded_at" TEXT,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("proficiency_level_id") REFERENCES "Skill_proficiency_level"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("skill_id") REFERENCES "Skill"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Certification" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "certification_id" INTEGER NOT NULL,
  "issue_date" TEXT,
  "expiration_date" TEXT,
  "certificate_number" TEXT,
  "is_verified" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT,
  FOREIGN KEY ("certification_id") REFERENCES "Certification"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Relocation_Preference" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "is_open_to_relocation" INTEGER,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("person_id") REFERENCES "Person"("id")
);
CREATE TABLE IF NOT EXISTS "Person_Project" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "project_name" TEXT NOT NULL,
  "project_role" TEXT,
  "project_description" TEXT,
  "project_url" TEXT,
  "start_date" TEXT,
  "end_date" TEXT,
  "created_at" TEXT NOT NULL, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_processing_run" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "submission_id" INTEGER NOT NULL,
  "process_type" TEXT NOT NULL,
  "run_number" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "decision" TEXT,
  "started_at" TEXT NOT NULL,
  "completed_at" TEXT,
  "error_code" TEXT,
  "error_detail" TEXT,
  "rule_version" TEXT,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("submission_id") REFERENCES "Submission_normalized"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_identity_feature" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "submission_normalized_id" INTEGER NOT NULL,
  "feature_type" TEXT NOT NULL,
  "normalized_value" TEXT,
  "value_hash" TEXT,
  "feature_strength" TEXT NOT NULL,
  "is_usable" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("submission_normalized_id") REFERENCES "Submission_normalized"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_attachment" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "submission_normalized_id" INTEGER NOT NULL,
  "attachment_type" TEXT NOT NULL,
  "original_file_name" TEXT,
  "object_key" TEXT,
  "source_url" TEXT,
  "mime_type" TEXT,
  "file_size_bytes" INTEGER,
  "file_sha256" TEXT,
  "is_primary" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("submission_normalized_id") REFERENCES "Submission_normalized"("id")
);
CREATE TABLE IF NOT EXISTS "Resume_education" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "resume_extraction_id" INTEGER NOT NULL,
  "splitted_raw_education_text" TEXT,
  "education_description" TEXT,
  "normalized_school_name" TEXT,
  "normalized_degree" TEXT,
  "normalized_field_of_study" TEXT,
  "is_current" INTEGER,
  "start_year" INTEGER,
  "start_month" INTEGER,
  "end_year" INTEGER,
  "end_month" INTEGER,
  "extraction_confidence" REAL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("resume_extraction_id") REFERENCES "Resume_extraction"("id")
);
CREATE TABLE IF NOT EXISTS "Resume_employment" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "resume_extraction_id" INTEGER NOT NULL,
  "splitted_raw_employment_text" TEXT,
  "employment_description" TEXT,
  "normalized_company_name" TEXT,
  "normalized_job_title" TEXT,
  "is_current" INTEGER,
  "start_year" INTEGER,
  "start_month" INTEGER,
  "end_year" INTEGER,
  "end_month" INTEGER,
  "extraction_confidence" REAL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("resume_extraction_id") REFERENCES "Resume_extraction"("id")
);
CREATE TABLE IF NOT EXISTS "Resume_external_identifier" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "resume_extraction_id" INTEGER NOT NULL,
  "identity_type" TEXT NOT NULL,
  "normalized_url" TEXT NOT NULL,
  "account_handle" TEXT,
  "extraction_confidence" REAL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("resume_extraction_id") REFERENCES "Resume_extraction"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_dedup_run" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "submission_normalized_id" INTEGER NOT NULL,
  "application_cluster_id" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "decision" TEXT,
  "matched_application_id" INTEGER,
  "strong_match_score" REAL,
  "resume_match_score" REAL,
  "final_match_score" REAL,
  "rule_version" TEXT,
  "started_at" TEXT NOT NULL,
  "completed_at" TEXT,
  "reviewed_by" INTEGER,
  "reviewed_at" TEXT,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("submission_normalized_id") REFERENCES "Submission_normalized"("id"),
  FOREIGN KEY ("application_cluster_id") REFERENCES "Application_cluster"("id"),
  FOREIGN KEY ("matched_application_id") REFERENCES "Application"("id")
);
CREATE TABLE IF NOT EXISTS "Identity_identifier" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "identifier_type" TEXT NOT NULL,
  "normalized_value" TEXT NOT NULL,
  "uniqueness_policy" TEXT NOT NULL,
  "created_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Person_identifier_claim" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "person_id" INTEGER NOT NULL,
  "identifier_id" INTEGER NOT NULL,
  "confidence" REAL,
  "verification_status" TEXT,
  "source_submission_id" INTEGER,
  "first_seen_at" TEXT NOT NULL,
  "last_seen_at" TEXT NOT NULL, "source_candidate_id" INTEGER REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_id") REFERENCES "Person"("id"),
  FOREIGN KEY ("identifier_id") REFERENCES "Identity_identifier"("id"),
  FOREIGN KEY ("source_submission_id") REFERENCES "Submission_normalized"("id")
);
CREATE TABLE IF NOT EXISTS "Submission_match_evidence" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "dedup_run_id" INTEGER NOT NULL,
  "matched_application_id" INTEGER,
  "evidence_type" TEXT NOT NULL,
  "evidence_strength" TEXT NOT NULL,
  "is_match" INTEGER NOT NULL,
  "score" REAL,
  "matched_person_identifier_claim_id" INTEGER,
  "source_reference_type" TEXT,
  "source_reference_id" INTEGER,
  "evidence_metadata" TEXT,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("dedup_run_id") REFERENCES "Submission_dedup_run"("id"),
  FOREIGN KEY ("matched_application_id") REFERENCES "Application"("id"),
  FOREIGN KEY ("matched_person_identifier_claim_id") REFERENCES "Person_identifier_claim"("id")
);
CREATE TABLE IF NOT EXISTS "Application_submission" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_id" INTEGER NOT NULL,
  "submission_normalized_id" INTEGER NOT NULL,
  "relation_type" TEXT NOT NULL,
  "dedup_run_id" INTEGER,
  "attached_at" TEXT NOT NULL,
  "created_by" INTEGER,
  FOREIGN KEY ("application_id") REFERENCES "Application"("id"),
  FOREIGN KEY ("submission_normalized_id") REFERENCES "Submission_normalized"("id"),
  FOREIGN KEY ("dedup_run_id") REFERENCES "Submission_dedup_run"("id")
);
CREATE TABLE IF NOT EXISTS "Application_document" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_id" INTEGER NOT NULL,
  "source_attachment_id" INTEGER NOT NULL,
  "document_type" TEXT NOT NULL,
  "is_primary" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("application_id") REFERENCES "Application"("id"),
  FOREIGN KEY ("source_attachment_id") REFERENCES "Submission_attachment"("id")
);
CREATE TABLE IF NOT EXISTS "Pipeline_stage_transition" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "pipeline_id" INTEGER NOT NULL,
  "from_stage_id" INTEGER NOT NULL,
  "to_stage_id" INTEGER NOT NULL,
  "is_allowed" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("pipeline_id") REFERENCES "Hiring_pipeline"("id"),
  FOREIGN KEY ("from_stage_id") REFERENCES "Pipeline_stage"("id"),
  FOREIGN KEY ("to_stage_id") REFERENCES "Pipeline_stage"("id")
);
CREATE TABLE IF NOT EXISTS "Application_stage_history" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_id" INTEGER NOT NULL,
  "from_stage_id" INTEGER,
  "to_stage_id" INTEGER NOT NULL,
  "changed_by" INTEGER,
  "entered_at" TEXT NOT NULL,
  "exited_at" TEXT,
  "reason_code" TEXT,
  "note" TEXT,
  FOREIGN KEY ("application_id") REFERENCES "Application"("id"),
  FOREIGN KEY ("from_stage_id") REFERENCES "Pipeline_stage"("id"),
  FOREIGN KEY ("to_stage_id") REFERENCES "Pipeline_stage"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_Education" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "candidate_id" INTEGER NOT NULL,
  "person_education_id" INTEGER NOT NULL,
  "is_highest_degree" INTEGER,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_education_id") REFERENCES "Person_Education"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_Skill" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "candidate_id" INTEGER NOT NULL,
  "person_skill_id" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_skill_id") REFERENCES "Person_Skill"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_Certification" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "candidate_id" INTEGER NOT NULL,
  "person_certification_id" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_certification_id") REFERENCES "Person_Certification"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_Position" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "candidate_id" INTEGER NOT NULL,
  "person_position_id" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id"),
  FOREIGN KEY ("person_position_id") REFERENCES "Person_Position"("id")
);
CREATE TABLE IF NOT EXISTS "Candidate_Reference" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "candidate_id" INTEGER NOT NULL,
  "reference_first_name" TEXT,
  "reference_last_name" TEXT,
  "reference_title" TEXT,
  "reference_company" TEXT,
  "reference_email" TEXT,
  "reference_phone" TEXT,
  "relationship_to_candidate" TEXT,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id")
);
CREATE TABLE IF NOT EXISTS "Offer" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "application_id" INTEGER NOT NULL UNIQUE,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL,
  FOREIGN KEY ("application_id") REFERENCES "Application"("id")
);
CREATE TABLE IF NOT EXISTS "Offer_version" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "offer_id" INTEGER NOT NULL,
  "version_no" INTEGER NOT NULL,
  "offer_title" TEXT,
  "offer_amount_cents" INTEGER,
  "offer_currency" TEXT,
  "start_date" TEXT NOT NULL,
  "generated_document_url" TEXT,
  "created_at" TEXT NOT NULL,
  FOREIGN KEY ("offer_id") REFERENCES "Offer"("id")
);
CREATE TABLE IF NOT EXISTS "Offer_status_history" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "offer_id" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "changed_at" TEXT NOT NULL,
  "changed_by" INTEGER,
  "note" TEXT,
  FOREIGN KEY ("offer_id") REFERENCES "Offer"("id")
);
CREATE TABLE IF NOT EXISTS "Ingestion_batch" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "source_system" TEXT NOT NULL,
  "dataset_type" TEXT NOT NULL,
  "source_schema_version" TEXT NOT NULL,
  "normalization_version" TEXT,
  "source_file_name" TEXT NOT NULL,
  "source_object_key" TEXT,
  "imported_at" TEXT NOT NULL,
  "import_status" TEXT NOT NULL,
  "total_row_count" INTEGER,
  "successful_row_count" INTEGER,
  "failed_row_count" INTEGER,
  "skipped_row_count" INTEGER,
  "file_sha256" TEXT,
  "error_summary" TEXT,
  "created_at" TEXT NOT NULL,

  FOREIGN KEY ("dataset_type")
    REFERENCES "Dataset_type"("type_code")
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS "Dataset_type" (
  "type_code" TEXT PRIMARY KEY,
  "display_type_name" TEXT NOT NULL,
  "type_description" TEXT,
  "contains_pii" INTEGER,
  "is_active" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "Position_application_cycle" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "position_id" INTEGER NOT NULL,
  "cycle_name" TEXT NOT NULL,

  -- 不知道真实 application cycle 开始月份时允许存 SQL NULL。
  "cycle_start_month" TEXT,

  -- 不知道真实 application cycle 结束月份时允许存 SQL NULL。
  "cycle_end_month" TEXT,

  "duration_months" INTEGER,
  "created_at" TEXT NOT NULL,

  -- 新建 record 时，updated_at 应该与 created_at 相同。
  "updated_at" TEXT NOT NULL,

  FOREIGN KEY ("position_id")
    REFERENCES "Position"("id")
);
CREATE TABLE IF NOT EXISTS "Resume_extraction" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "submission_normalized_id" INTEGER NOT NULL UNIQUE,
      "extracted_raw_resume_text" TEXT,
      "cleaned_resume_text" TEXT,
      "resume_text_sha256" TEXT,
      "resume_simhash" TEXT,
      "text_length" INTEGER,
      "extraction_status" TEXT NOT NULL,
      "extraction_error" TEXT,
      "warnings" TEXT,
      "extracted_at" TEXT NOT NULL,
      "created_at" TEXT NOT NULL,
      "updated_at" TEXT NOT NULL,
      "resume_emails" TEXT,
      "resume_phones" TEXT,
      FOREIGN KEY ("submission_normalized_id")
        REFERENCES "Submission_normalized"("id")
    );
CREATE TABLE IF NOT EXISTS "Candidate_Project" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "candidate_id" INTEGER NOT NULL, "person_project_id" INTEGER NOT NULL, "created_at" TEXT NOT NULL, FOREIGN KEY ("candidate_id") REFERENCES "Candidate_snapshot"("id"), FOREIGN KEY ("person_project_id") REFERENCES "Person_Project"("id"));
CREATE TABLE IF NOT EXISTS "Application_stage_run" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "application_id" INTEGER NOT NULL,
      "pipeline_stage_id" INTEGER NOT NULL,
      "attempt_no" INTEGER NOT NULL,
      "run_status" TEXT NOT NULL,
      "stage_decision" TEXT,
      "scheduled_at" TEXT,
      "started_at" TEXT,
      "completed_at" TEXT,
      "score" REAL,
      "maximum_score" REAL,
      "passed_threshold" INTEGER,
      "executed_by" INTEGER,
      "result_summary" TEXT,
      "result_metadata" TEXT,
      "created_at" TEXT NOT NULL,
      "updated_at" TEXT NOT NULL,
      FOREIGN KEY ("application_id") REFERENCES "Application"("id"),
      FOREIGN KEY ("pipeline_stage_id") REFERENCES "Pipeline_stage"("id"),
      UNIQUE ("application_id", "pipeline_stage_id", "attempt_no")
    );
DELETE FROM sqlite_sequence;
CREATE UNIQUE INDEX "idx_Pipeline_stage_0_pipeline_id_sequence_no" ON "Pipeline_stage" ("pipeline_id", "sequence_no");
CREATE UNIQUE INDEX "idx_Pipeline_stage_1_pipeline_id_id" ON "Pipeline_stage" ("pipeline_id", "id");
CREATE UNIQUE INDEX "idx_Application_0_application_cluster_id_person_id" ON "Application" ("application_cluster_id", "person_id");
CREATE UNIQUE INDEX "idx_raw_submission_0_ingestion_batch_id_source_record_number" ON "raw_submission" ("ingestion_batch_id", "source_record_number");
CREATE UNIQUE INDEX "idx_Person_Name_0_person_id_name_value" ON "Person_Name" ("person_id", "name_value");
CREATE UNIQUE INDEX "idx_Submission_processing_run_0_submission_id_process_type_run_number" ON "Submission_processing_run" ("submission_id", "process_type", "run_number");
CREATE UNIQUE INDEX "idx_Submission_identity_feature_0_submission_normalized_id_feature_type_value_hash" ON "Submission_identity_feature" ("submission_normalized_id", "feature_type", "value_hash");
CREATE UNIQUE INDEX "idx_Resume_external_identifier_0_resume_extraction_id_identity_type_normalized_url" ON "Resume_external_identifier" ("resume_extraction_id", "identity_type", "normalized_url");
CREATE UNIQUE INDEX "idx_Identity_identifier_0_identifier_type_normalized_value" ON "Identity_identifier" ("identifier_type", "normalized_value");
CREATE UNIQUE INDEX "idx_Person_identifier_claim_0_person_id_identifier_id" ON "Person_identifier_claim" ("person_id", "identifier_id");
CREATE UNIQUE INDEX "idx_Application_submission_0_application_id_submission_normalized_id" ON "Application_submission" ("application_id", "submission_normalized_id");
CREATE UNIQUE INDEX "idx_Application_document_0_application_id_source_attachment_id" ON "Application_document" ("application_id", "source_attachment_id");
CREATE UNIQUE INDEX "idx_Pipeline_stage_transition_0_pipeline_id_from_stage_id_to_stage_id" ON "Pipeline_stage_transition" ("pipeline_id", "from_stage_id", "to_stage_id");
CREATE UNIQUE INDEX "idx_Candidate_Education_0_candidate_id_person_education_id" ON "Candidate_Education" ("candidate_id", "person_education_id");
CREATE UNIQUE INDEX "idx_Candidate_Skill_0_candidate_id_person_skill_id" ON "Candidate_Skill" ("candidate_id", "person_skill_id");
CREATE UNIQUE INDEX "idx_Candidate_Certification_0_candidate_id_person_certification_id" ON "Candidate_Certification" ("candidate_id", "person_certification_id");
CREATE UNIQUE INDEX "idx_Candidate_Position_0_candidate_id_person_position_id" ON "Candidate_Position" ("candidate_id", "person_position_id");
CREATE UNIQUE INDEX "idx_Offer_version_0_offer_id_version_no" ON "Offer_version" ("offer_id", "version_no");
CREATE UNIQUE INDEX "idx_Position_application_cycle_position_id_cycle_name"
ON "Position_application_cycle" (
  "position_id",
  LOWER(
    TRIM(
      "cycle_name"
    )
  )
);
CREATE INDEX "idx_application_company_id" ON "Application" ("company_id");
CREATE INDEX "idx_application_position_id" ON "Application" ("position_id");
CREATE INDEX "idx_person_name_source_candidate_id" ON "Person_Name" ("source_candidate_id");
CREATE INDEX "idx_person_contact_source_candidate_id" ON "Person_Contact" ("source_candidate_id");
CREATE INDEX "idx_person_link_source_candidate_id" ON "Person_Link" ("source_candidate_id");
CREATE INDEX "idx_person_identifier_claim_source_candidate_id" ON "Person_identifier_claim" ("source_candidate_id");
CREATE INDEX "idx_person_skill_source_candidate_id" ON "Person_Skill" ("source_candidate_id");
CREATE INDEX "idx_person_position_source_candidate_id" ON "Person_Position" ("source_candidate_id");
CREATE INDEX "idx_person_education_source_candidate_id" ON "Person_Education" ("source_candidate_id");
CREATE INDEX "idx_person_project_source_candidate_id" ON "Person_Project" ("source_candidate_id");
CREATE UNIQUE INDEX "idx_Candidate_Project_0_candidate_id_person_project_id" ON "Candidate_Project" ("candidate_id", "person_project_id");
CREATE UNIQUE INDEX "idx_Person_Skill_0_person_id_skill_id" ON "Person_Skill" ("person_id", "skill_id");
CREATE UNIQUE INDEX "idx_candidate_education_candidate_person_education" ON "Candidate_Education" (   "candidate_id",   "person_education_id" );
CREATE UNIQUE INDEX "idx_person_education_person_education" ON "Person_Education" (   "person_id",   "education_id" );
CREATE INDEX "idx_application_stage_run_application_status"
    ON "Application_stage_run" (
      "application_id",
      "run_status"
    );
CREATE INDEX "idx_application_stage_run_stage_decision"
    ON "Application_stage_run" (
      "pipeline_stage_id",
      "stage_decision"
    );
CREATE UNIQUE INDEX "idx_pipeline_stage_pipeline_name"
    ON "Pipeline_stage" (
      "pipeline_id",
      "pipeline_stage_name"
    );
CREATE UNIQUE INDEX "idx_pipeline_stage_transition_unique_edge"
    ON "Pipeline_stage_transition" (
      "pipeline_id",
      "from_stage_id",
      "to_stage_id"
    );
CREATE UNIQUE INDEX "idx_offer_version_offer_version_no"
    ON "Offer_version" (
      "offer_id",
      "version_no"
    );
CREATE INDEX "idx_application_stage_history_application_entered"
    ON "Application_stage_history" (
      "application_id",
      "entered_at"
    );
CREATE INDEX "idx_offer_status_history_offer_changed"
    ON "Offer_status_history" (
      "offer_id",
      "changed_at"
    );
