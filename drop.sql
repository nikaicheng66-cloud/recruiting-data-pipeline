-- ============================================================================
-- delete_all_tables_2026-08-04.sql
--
-- 依据：Create_schema_2026-08-04.sql
-- 目标：彻底删除当前 D1 数据库中的全部 81 张用户业务表。
--
-- !!! 极度危险、不可逆操作 !!!
--
-- 执行本文件后：
--   1. 所有业务数据都会被永久删除；
--   2. 所有业务表都会被删除；
--   3. 随表建立的 indexes 和 triggers 也会随表自动删除；
--   4. 数据库只会保留 SQLite / Cloudflare 自己管理的内部对象；
--   5. 除非事先保存完整备份，否则无法恢复。
--
-- 强烈建议执行前先运行：
--
--   npx wrangler d1 export dse_jd_cv \
--     --remote \
--     --output="/Users/shiyili/Desktop/dse_jd_cv_full_backup_before_delete.sql"
--
-- 推荐执行方式：
--
--   npx wrangler d1 execute dse_jd_cv \
--     --remote \
--     --file="/absolute/path/delete_all_tables_2026-08-04.sql"
--
-- 为什么启用 defer_foreign_keys：
-- 当前 schema 中存在循环外键，例如 Person、Candidate_snapshot、Application、
-- Person_Education 和 Person_Position 之间能够形成循环依赖。仅靠手工调整
-- DROP TABLE 顺序无法在所有有数据的情况下彻底消除这些循环。把外键检查延迟到
-- 当前 D1 batch 结束，可以在同一个原子 batch 中删除完整依赖图；如果中途失败，
-- D1 应回滚该 batch，而不是留下半套 schema。
-- ============================================================================

-- 将当前 batch 中的外键验证延迟到 batch 结束。
PRAGMA defer_foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- 招聘流程执行、Offer 和 Candidate 关联层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Application_stage_run";
DROP TABLE IF EXISTS "Candidate_Project";
DROP TABLE IF EXISTS "Offer_status_history";
DROP TABLE IF EXISTS "Offer_version";
DROP TABLE IF EXISTS "Offer";
DROP TABLE IF EXISTS "Candidate_Reference";
DROP TABLE IF EXISTS "Candidate_Position";
DROP TABLE IF EXISTS "Candidate_Certification";
DROP TABLE IF EXISTS "Candidate_Skill";
DROP TABLE IF EXISTS "Candidate_Education";
DROP TABLE IF EXISTS "Application_stage_history";
DROP TABLE IF EXISTS "Pipeline_stage_transition";
DROP TABLE IF EXISTS "Application_document";
DROP TABLE IF EXISTS "Application_submission";

-- ----------------------------------------------------------------------------
-- Submission 查重、身份和简历提取层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Submission_match_evidence";
DROP TABLE IF EXISTS "Person_identifier_claim";
DROP TABLE IF EXISTS "Identity_identifier";
DROP TABLE IF EXISTS "Submission_dedup_run";
DROP TABLE IF EXISTS "Resume_external_identifier";
DROP TABLE IF EXISTS "Resume_employment";
DROP TABLE IF EXISTS "Resume_education";
DROP TABLE IF EXISTS "Resume_extraction";
DROP TABLE IF EXISTS "Submission_attachment";
DROP TABLE IF EXISTS "Submission_identity_feature";
DROP TABLE IF EXISTS "Submission_processing_run";

-- ----------------------------------------------------------------------------
-- Person 子表、Candidate snapshot 和 Application 层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Person_Project";
DROP TABLE IF EXISTS "Person_Relocation_Preference";
DROP TABLE IF EXISTS "Person_Certification";
DROP TABLE IF EXISTS "Person_Skill";
DROP TABLE IF EXISTS "Person_Link";
DROP TABLE IF EXISTS "Person_Contact";
DROP TABLE IF EXISTS "Person_Name";
DROP TABLE IF EXISTS "Submission_normalized";
DROP TABLE IF EXISTS "raw_submission";
DROP TABLE IF EXISTS "Specific_open_window";
DROP TABLE IF EXISTS "Person";
DROP TABLE IF EXISTS "Person_Position";
DROP TABLE IF EXISTS "Person_Education";
DROP TABLE IF EXISTS "Candidate_snapshot";
DROP TABLE IF EXISTS "Application";
DROP TABLE IF EXISTS "Pipeline_stage";
DROP TABLE IF EXISTS "Hiring_pipeline";
DROP TABLE IF EXISTS "Application_cluster";

-- ----------------------------------------------------------------------------
-- Position、application cycle 及岗位要求层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Position_certification_requirement";
DROP TABLE IF EXISTS "Position_education_requirement";
DROP TABLE IF EXISTS "Position_skill";
DROP TABLE IF EXISTS "Position_salary_range";
DROP TABLE IF EXISTS "Position_application_cycle";
DROP TABLE IF EXISTS "Position";
DROP TABLE IF EXISTS "Position_occupational_type";
DROP TABLE IF EXISTS "Position_employment_type";

-- ----------------------------------------------------------------------------
-- Company 层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Company_work_mode";
DROP TABLE IF EXISTS "Company_contact_info";
DROP TABLE IF EXISTS "Company_location";
DROP TABLE IF EXISTS "Company_name_aliases";
DROP TABLE IF EXISTS "Company";
DROP TABLE IF EXISTS "Company_industry_code";

-- ----------------------------------------------------------------------------
-- Education 维度和教育经历层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "School_location";
DROP TABLE IF EXISTS "Education";
DROP TABLE IF EXISTS "School";
DROP TABLE IF EXISTS "Major";
DROP TABLE IF EXISTS "Field_study";
DROP TABLE IF EXISTS "Degree";

-- ----------------------------------------------------------------------------
-- Location 维度层。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Location";
DROP TABLE IF EXISTS "Timezone";
DROP TABLE IF EXISTS "City";
DROP TABLE IF EXISTS "State";
DROP TABLE IF EXISTS "Region";
DROP TABLE IF EXISTS "Country";

-- ----------------------------------------------------------------------------
-- Certification、Skill 和其他 reference dimensions。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Certification";
DROP TABLE IF EXISTS "Issuing_organization";
DROP TABLE IF EXISTS "Certification_type";
DROP TABLE IF EXISTS "Skill_proficiency_level";
DROP TABLE IF EXISTS "Skill";
DROP TABLE IF EXISTS "Skill_type";
DROP TABLE IF EXISTS "Contact_type";
DROP TABLE IF EXISTS "Experience_level";
DROP TABLE IF EXISTS "Seniority";
DROP TABLE IF EXISTS "Function";

-- ----------------------------------------------------------------------------
-- 数据导入批次和数据集类型最后删除。
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS "Ingestion_batch";
DROP TABLE IF EXISTS "Dataset_type";

-- 恢复常规外键设置。D1 在 batch 外本来也会继续执行外键约束。
PRAGMA foreign_keys = ON;

-- 最终只读检查：正常结果应当为空，不应再返回任何用户 table。
SELECT
  "name" AS "remaining_user_table"
FROM "sqlite_master"
WHERE "type" = 'table'
  AND "name" NOT LIKE 'sqlite_%'
  AND "name" NOT LIKE '_cf_%'
ORDER BY "name";

