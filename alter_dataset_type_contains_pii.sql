-- ============================================================
-- alter_dataset_type_contains_pii.sql
-- 放宽 Dataset_type.contains_pii 的 NOT NULL 约束，改成允许为空。
-- 原因：测试阶段暂时不使用这个字段，统一存 NULL。
--
-- SQLite 不支持直接 ALTER COLUMN 改约束，需要用标准的
-- "建新表 -> 搬数据 -> 删旧表 -> 改名" 方式重建这张表。
-- Dataset_type 目前数据量很小（最多几行维度数据），可以放心重建。
--
-- 部署方式（Colab里）：
--   先跑这个文件，再跑 raw_submission_loader.py
-- ============================================================

PRAGMA foreign_keys = OFF;

CREATE TABLE "Dataset_type_new" (
  "type_code" TEXT PRIMARY KEY,
  "display_type_name" TEXT NOT NULL,
  "type_description" TEXT,
  "contains_pii" INTEGER,
  "is_active" INTEGER NOT NULL,
  "created_at" TEXT NOT NULL
);

INSERT INTO "Dataset_type_new" (
  "type_code", "display_type_name", "type_description",
  "contains_pii", "is_active", "created_at"
)
SELECT
  "type_code", "display_type_name", "type_description",
  "contains_pii", "is_active", "created_at"
FROM "Dataset_type";

DROP TABLE "Dataset_type";
ALTER TABLE "Dataset_type_new" RENAME TO "Dataset_type";

PRAGMA foreign_keys = ON;
