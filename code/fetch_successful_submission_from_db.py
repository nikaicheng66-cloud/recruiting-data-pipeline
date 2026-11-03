"""
fetch_successful_submission_from_db.py（Google Colab 版）

不依赖 Colab 内存里的 successful_submission_dataframe（重启 runtime
后这个变量就没了），改成直接从 D1 数据库里把等价的数据查出来重建。

原理：
  raw_submission.raw_record_jsonb 这一列本身就完整保留了当初那一整行
  CSV 原始内容（按"字段名: 值"一行一个的格式打包，参见
  raw_submission_loader.py 的 _row_to_utf8_text），resume_text 就在
  这段文本里——只需要把它反向拆解回去，取出 resume_text 这一个字段
  就够了（build_resume_extraction_dataframes() 本来也只需要
  raw_submission_id 和 resume_text 这两列）。

  "successful"（等价于 InitialSubmissionCleaner 筛选出来的那批）这个
  范围，通过 JOIN Submission_normalized 天然限定——能在
  Submission_normalized 里查到对应记录的 raw_submission，
  就是当初通过了初步清洗、被标准化过的那些，口径和
  successful_submission_dataframe 一致。

已知的一处局限（和 raw_record_jsonb 这个存储格式本身的局限一致，
之前讨论过）：如果 resume_text 内容本身有一行恰好长得像
"字段名: 值"这种格式（比如简历里写了"Reference name: John Doe"这种
内容），反向拆解可能会误判成一个新字段的开始。这是"字段名: 值"
这种打包格式本身的固有风险，不是这次新写的代码引入的新问题。

用法（Colab cell 里直接调用）：
    successful_submission_dataframe = fetch_successful_submission_dataframe_from_db(loader)
"""

import pandas as pd


# 原始 CSV 的字段名（不含 resume 这一列，当初导入时就已经排除掉了），
# 用来判断"这一行是不是某个字段的开头"，而不是上一个字段值的延续
KNOWN_RAW_SUBMISSION_FIELDS = {
    "name", "resume_text", "contact_email", "company",
    "position", "mode", "duration", "start_date", "end_date", "created_at",
}


def _parse_raw_record_text(raw_record_text: str, known_fields: set = KNOWN_RAW_SUBMISSION_FIELDS) -> dict:
    """
    把 raw_submission_loader.py 里 _row_to_utf8_text() 打包出来的
    "字段名: 值"文本，反向拆解回一个 dict——是 _row_to_utf8_text()
    的逆操作。
    """
    result = {}
    current_field = None
    current_value_lines = []

    for line in (raw_record_text or "").split("\n"):
        matched_field = None
        for field in known_fields:
            prefix = f"{field}: "
            if line.startswith(prefix):
                matched_field = field
                matched_value_start = line[len(prefix):]
                break

        if matched_field is not None:
            # 遇到新字段的开头，先把上一个字段收尾存好
            if current_field is not None:
                result[current_field] = "\n".join(current_value_lines)
            current_field = matched_field
            current_value_lines = [matched_value_start]
        else:
            # 不像任何已知字段的开头，当成上一个字段值的延续行
            if current_field is not None:
                current_value_lines.append(line)

    if current_field is not None:
        result[current_field] = "\n".join(current_value_lines)

    return result


def fetch_successful_submission_dataframe_from_db(d1_client, ingestion_batch_id: int = None) -> pd.DataFrame:
    """
    直接从数据库查询，重建出等价于 successful_submission_dataframe
    的最小数据集（只有 raw_submission_id / resume_text 两列，这也是
    build_resume_extraction_dataframes() 唯一需要的两列）。

    ingestion_batch_id 可选：不传的话，取全部已经标准化过的
    raw_submission；传了的话，只取这一批的。
    """
    if ingestion_batch_id is not None:
        sql = """
            SELECT rs."id" AS raw_submission_id, rs."raw_record_jsonb"
            FROM "raw_submission" AS rs
            INNER JOIN "Submission_normalized" AS sn
              ON sn."raw_submission_id" = rs."id"
            WHERE rs."ingestion_batch_id" = ?
            ORDER BY rs."id";
        """
        params = [int(ingestion_batch_id)]
    else:
        sql = """
            SELECT rs."id" AS raw_submission_id, rs."raw_record_jsonb"
            FROM "raw_submission" AS rs
            INNER JOIN "Submission_normalized" AS sn
              ON sn."raw_submission_id" = rs."id"
            ORDER BY rs."id";
        """
        params = None

    ok, result = d1_client._execute(sql, params)
    if not ok:
        raise RuntimeError(f"Query raw_submission/Submission_normalized failed: {result}")

    rows = result[0].get("results", []) if result else []

    records = []
    for row in rows:
        parsed = _parse_raw_record_text(row["raw_record_jsonb"])
        records.append({
            "raw_submission_id": row["raw_submission_id"],
            "resume_text": parsed.get("resume_text"),
        })

    df = pd.DataFrame(records)
    print(f"Rebuilt successful_submission_dataframe from database: {len(df)} rows")
    return df
