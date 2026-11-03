"""
resume_skill_matcher.py（Google Colab 版）

把 ResumeTextParser 切出来的"原始技能提及文本"，拿去和 Skill 参考表
做真实匹配，只有匹配上的才算数、才有 skill_id。不是靠字符串长得
像不像技能来猜，是真的去查表核对——这样 "Languages"/"Interests"
这类子标题词，因为在 Skill 参考表里根本不存在，会被自然过滤掉，
不需要额外写规则去排除它们。

设计上刻意把"文本切分"（resume_text_parser.py 负责）和"对照参考表
匹配"（这个文件负责）分成两个独立模块：前者不连数据库、纯文本处理，
后者专门做匹配这一件事，Skill_lookup 只在处理一整批简历之前加载
一次（14000+条参考数据，每条简历都单独查库效率太差）。

用法（Colab cell 里直接调用）：
    matcher = ResumeSkillMatcher(ACCOUNT_ID, DATABASE_ID, API_TOKEN)
    matcher.load_skill_lookup()          # 只需要加载一次
    matched = matcher.match(raw_skill_tokens)
    # matched 是 list[dict]，每条 {"skill_id", "skill_name", "skill_type_id",
    #                          "matched_raw_text"}
"""

import requests


class ResumeSkillMatcher:
    def __init__(self, account_id: str, database_id: str, api_token: str):
        self.api_url = (
            f"https://api.cloudflare.com/client/v4/accounts/{account_id}"
            f"/d1/database/{database_id}/query"
        )
        self.headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json",
        }
        # skill_name（小写）-> {"skill_id", "skill_name", "skill_type_id"}
        # 的查找表，load_skill_lookup() 调用一次之后常驻内存复用
        self._skill_lookup = {}

    def _execute(self, sql: str, params: list = None, timeout: int = 30):
        payload = {"sql": sql}
        if params is not None:
            payload["params"] = params
        resp = requests.post(self.api_url, headers=self.headers, json=payload, timeout=timeout)
        try:
            data = resp.json()
        except ValueError:
            return False, f"HTTP {resp.status_code}, response is not valid JSON: {resp.text[:300]}"
        if resp.status_code != 200 or not data.get("success", False):
            return False, data.get("errors", [])
        return True, data.get("result", [])

    def load_skill_lookup(self):
        """
        把整张 Skill 参考表一次性拉下来，建成内存里的查找字典。
        这样匹配 10000+ 条简历技能提及时，不需要每一条都单独发一次
        SQL 查询，只需要查一次表，之后全部在内存里比对。
        """
        ok, result = self._execute('SELECT "id", "skill_name", "skill_type_id" FROM "Skill";')
        if not ok:
            raise RuntimeError(f"Query Skill failed: {result}")

        rows = result[0].get("results", []) if result else []
        self._skill_lookup = {}
        for row in rows:
            key = row["skill_name"].strip().lower()
            # 如果同一个小写名字对应多条记录（比如同名跨 skill_type
            # 各自独立存了一份），这里只登记第一条命中的——
            # 这是当前版本的简化处理，之后如果需要保留"多重匹配"
            # 的情况（比如同时匹配到 Technology 和 Function 两个类型），
            # 需要把 value 改成 list，这里先取最简单的单一匹配版本
            if key not in self._skill_lookup:
                self._skill_lookup[key] = {
                    "skill_id": row["id"],
                    "skill_name": row["skill_name"],
                    "skill_type_id": row["skill_type_id"],
                }

        print(f"Loaded {len(rows)} Skill rows, {len(self._skill_lookup)} unique names in lookup table")
        return self._skill_lookup

    def match(self, raw_skill_tokens: list) -> list:
        """
        把切分出来的原始技能提及文本，逐条去查 skill_lookup。
        只有查到的才会出现在返回结果里——查不到的（比如"Languages"
        这种子标题词，或者拼写和参考表对不上的技能名）会被直接丢弃，
        不会带着 skill_id=None 这种半成品进入下一步。

        matched_raw_text 保留原始的那份提及文本（未必和参考表里的
        skill_name 大小写完全一致），方便以后排查"这条是从简历里
        哪个词匹配上的"。
        """
        if not self._skill_lookup:
            raise RuntimeError("skill_lookup 是空的，请先调用 load_skill_lookup()")

        matched = []
        seen_skill_ids = set()
        for raw_text in raw_skill_tokens:
            key = raw_text.strip().lower()
            hit = self._skill_lookup.get(key)
            if hit is None:
                continue
            # 同一条简历里，同一个 skill_id 只记一次（比如"Python"在
            # 技能段落里因为格式原因被切出来两次，不重复计入）
            if hit["skill_id"] in seen_skill_ids:
                continue
            seen_skill_ids.add(hit["skill_id"])
            matched.append({
                "skill_id": hit["skill_id"],
                "skill_name": hit["skill_name"],
                "skill_type_id": hit["skill_type_id"],
                "matched_raw_text": raw_text,
            })
        return matched
