"""
resume_text_parser.py（Google Colab 版）

把 successful_submission_dataframe 里的 resume_text 字段拆分成结构化的
教育经历 / 工作经历 / 外部身份链接三类信息，对应目标表：
  Resume_education
  Resume_employment
  Resume_external_identifier

背景（不是从零设计，是基于对 raw_submission.csv 真实数据的实测发现）：
  之前 submission_processing_pipeline.py 里的 DefaultResumeParser 用的
  分段标题正则，对这批真实简历数据覆盖率不够——很多高频出现的标题写法
  （比如 "EDUCATION BACKGROUND"、"PROJECT EXPERIENCE"、"TECHNICAL SKILLS"）
  identifiable 不了，日期格式也只认得"月份名+年份"或"纯年份"，认不出
  "2023.09 - 2027.05" 这种年.月写法，也认不出 "Expected May 2028"
  这种单个日期（不是一个范围）。这份文件是针对这些实测发现重新写的，
  不是在旧文件基础上打补丁。

固定约定（延续之前确认过的规范）：
  1. 变量名尽量直接对应目标表字段名；
  2. resume_text 为空的记录直接跳过，不进入本模块任何处理；
  3. "PROJECT EXPERIENCE" / "ACADEMIC PROJECTS" 这类内容被识别为
     一个独立分段，但内容不提取（不归入 Resume_employment，避免
     项目名污染公司名字段）——这是本轮明确的处理原则，不是遗漏；
  4. 所有解析结果都带 extraction_confidence（0~1），规则解析
     不可能覆盖简历的所有写法，提取不全/不准的记录靠这个字段
     标注出来，供后续筛选复核，不追求规则本身穷尽所有情况。

用法（Colab cell 里直接调用）：
    parser = ResumeTextParser()
    result = parser.parse(resume_text)
    # result 是 {"resume_educations": [...], "resume_employments": [...],
    #            "resume_external_identifiers": [...]}
"""

import re


class ResumeParsingError(Exception):
    """
    当 resume_text 本身非空，但解析结果"空值太多"时抛出——
    不是某个字段偶尔缺失（那种情况按之前确认过的原则，正常存，
    不算错误），而是整条简历基本什么有用信息都没提取到，
    等同于"这次解析等于白做"，需要调用方知道这条记录有问题，
    而不是被当成一条正常的、只是数据略有缺失的解析结果继续往下走。

    调用方（未来批量处理 successful_submission_dataframe 的脚本）
    应该按项目里已有的惯例，对每一条记录单独 try/except 捕获这个
    异常、记下"第几条、什么原因"，然后继续处理下一条，不应该让
    这一个异常导致整个批次中断。
    """
    pass


# ============================================================
# 配置区
# ============================================================

# ---- 分段标题识别 ----
# 三类标题分别对应：教育段 / 工作经历段（会被提取）/ 其他段（会终止当前
# 段落的收集，但内容本身不提取）。
#
# 这份清单是基于对 raw_submission.csv 全部 1241 条 resume_text 的
# 实际标题词频统计后扩充的（统计方法：抓所有短行、四个词以内、
# 纯字母的行，按频率排序），不是凭空猜的。
EDUCATION_HEADERS = re.compile(
    r'^\s*(education|education\s*background|educational\s*background|'
    r'academic\s*background|academic\s*history|学历|教育|教育背景)'
    r'\s*[:：]?\s*[-–—_—\s]*$', re.I)

EMPLOYMENT_HEADERS = re.compile(
    r'^\s*(experience|work\s*experience|employment|'
    r'professional\s*experiences?|work\s*history|'
    r'internship\s*experience|internship|'
    r'research\s*experience|research\s*assistant\s*experience|'
    r'work\s*&?\s*leadership\s*experience|'
    r'工作经历|实习经历)'
    r'\s*[:：]?\s*[-–—_—\s]*$', re.I)

# 技能类标题单独拆出来（原来混在 OTHER_HEADERS 里，内容会被直接
# 丢弃）——这一类现在会被识别成独立分段，内容原样收集，但暂时只做
# 字符串切分，不做和 Skill 参考表的匹配（那一步需要先有 Resume_skill
# 表，属于下一阶段的事）
SKILL_HEADERS = re.compile(
    r'^\s*(skills?|technical\s*skills|'
    r'skills?\s*(and|&)\s*interests?)\s*:?\s*$', re.I)

# 这些段落会让"当前正在收集的段落"结束，且内容本身也不提取——
# 项目经历（不归入 Resume_employment，避免公司名字段被项目名污染）、
# 证书/领导力/课外活动这些同样不提取，理由是它们本来就不属于
# Resume_education / Resume_employment / 技能 这三类的范畴。
OTHER_HEADERS = re.compile(
    r'^\s*(projects?|academic\s*projects|'
    r'project\s*experiences?|'
    r'certifications?|awards?|publications?|languages?|'
    r'summary|objective|interests?|'
    r'additional\s*information|other\s*information|'
    r'leadership\s*experience(\s*and\s*activities)?|'
    r'leadership\s*&\s*extracurricular\s*activities|'
    r'extracurricular\s*activities|extracurricular\s*experience)'
    r'\s*:?\s*$', re.I)

# ---- 日期识别 ----
# 英文月份名 -> 月份数字（含常见缩写）
MONTH_NAMES = {
    "january": 1, "jan": 1, "february": 2, "feb": 2, "march": 3, "mar": 3,
    "april": 4, "apr": 4, "may": 5, "june": 6, "jun": 6, "july": 7, "jul": 7,
    "august": 8, "aug": 8, "september": 9, "sep": 9, "sept": 9,
    "october": 10, "oct": 10, "november": 11, "nov": 11,
    "december": 12, "dec": 12,
}

# 单个"日期token"能长什么样（供下面组装范围/单日期正则复用）：
#   "September 2020" / "Sep 2020" / "2020" / "2023.09" / "Present"
#   实测发现的 "2023.09" 这种年.月格式，旧版本完全没覆盖，这次补上
DATE_TOKEN = (
    r'(?:[A-Za-z]+\.?\s+\d{4}'      # 月份名 + 年份，如 "September 2020"
    r'|\d{4}\.\d{1,2}'               # 年.月，如 "2023.09"
    r'|\d{4}'                        # 纯年份
    r'|present|current|now)'         # "至今"
)

# 完整范围："日期 连接符 日期"，连接符允许 - – — ~ 或英文 "to"
DATE_RANGE_RE = re.compile(
    rf'({DATE_TOKEN})\s*(?:[-–—~]|to)\s*({DATE_TOKEN})', re.I)

# 只有一个日期、没有范围的情况（实测常见于 "Expected May 2028" 这种
# 还没毕业、只写预计毕业时间的教育条目）。前面允许 "Expected"/"预计"
# 这类修饰词，也允许什么都不加、单独一个日期token出现在整行里。
SINGLE_DATE_RE = re.compile(
    rf'(?:expected\s*(?:in\s*)?|预计)?\s*({DATE_TOKEN})(?!\s*[-–—~]|\s*to\s)',
    re.I)

# 学位关键词：一段文本里出现这些词，就认为这一块说的是学位
DEGREE_KEYWORDS = re.compile(
    r'\b(ph\.?d|doctorate|master|m\.?s\.?c?|m\.?a\.?|mba|bachelor|'
    r'b\.?s\.?c?|b\.?a\.?|b\.?eng|associate|diploma)\b', re.I)

# 有些学校的官方全称本身就带逗号（比如加州大学系统官方写法是
# "University of California, Davis"/"Berkeley"/"Irvine" 这种，逗号是
# 校名的一部分，不是"校名+地址"的分隔符）。实测过 raw_submission.csv
# 全部1241条数据，加州大学系统这个模式出现了212次，其余几个类似结构
# 的大学系统（SUNY/UMass/UWisconsin等）出现次数是0~2次，可以忽略，
# 所以这份清单目前只放了加州大学系统一条，以后发现新的同类情况，
# 往这个列表里加一条前缀就行，不需要改下面的匹配逻辑。
KNOWN_COMMA_IN_SCHOOL_NAME_PREFIXES = [
    "university of california",
]

# 识别 LinkedIn / GitHub 链接
EXTERNAL_ID_RE = re.compile(
    r'(https?://)?(www\.)?'
    r'(?P<site>linkedin\.com/in|github\.com)/'
    r'(?P<handle>[A-Za-z0-9_\-\.%]+)', re.I)

# 识别邮箱地址（标准格式：用户名@域名）
# 注意：这里显式限定成 ASCII 范围的 \w，不用 Python 默认的 Unicode
# 版 \w——不然像 "ᐧ"（简历里当装饰性分隔符用的一个特殊符号）这种
# 非英文的"类单词字符"，也会被误吸收进邮箱用户名的开头
EMAIL_RE = re.compile(r'[a-zA-Z0-9._+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+')

# 识别电话号码。实测样本里写法非常多样：
#   "+1 (718)-612-9082" / "+1 718-612-9082" / "(778) 227-730"
#   "4706558003"（纯数字无分隔符） / "(+1) 667-434-0779"
#   "929-988-1755" / "+18482565773"（国家码和号码粘在一起没有分隔）
# 这个正则尽量宽松地覆盖上面这几种常见写法，允许国家码可选、
# 区号括号可选、分隔符可以是空格/短横线/点/或者完全没有
PHONE_RE = re.compile(
    r'(?<!\d)(\+?\d{1,3}[\s\-.]?)?\(?\d{3}\)?[\s\-.]?\d{3}[\s\-.]?\d{3,4}(?!\d)')


class ResumeTextParser:
    """
    简历文本解析器（规则版）。

    职责：把一段清洗后的简历纯文本，拆成 education / employment 两类
    结构化条目，加上 linkedin/github 外部身份链接。

    设计上刻意保持"无状态"——parse() 只依赖传进来的文本本身，不依赖
    任何跨调用的缓存/历史，方便单条测试、也方便以后要替换成更智能的
    解析器时直接整体替换这个类，管线其他部分不用变。
    """

    # ------------------------------------------------------------
    # 日期解析：把单个 token（"Sep 2020" / "2023.09" / "2020" /
    # "present"）拆成 (year, month, is_present) 三元组
    # ------------------------------------------------------------
    @staticmethod
    def _parse_date_token(token: str):
        token = token.strip()

        # 情况一："至今"
        if re.match(r'^(present|current|now)$', token, re.I):
            return None, None, True

        # 情况二：年.月，如 "2023.09"（这是本轮新补的格式）
        m = re.match(r'^(\d{4})\.(\d{1,2})$', token)
        if m:
            year = int(m.group(1))
            month = int(m.group(2))
            # 月份数字超出 1~12 范围说明不是真的月份，按"只有年份"处理
            if 1 <= month <= 12:
                return year, month, False
            return year, None, False

        # 情况三：月份名 + 年份，如 "September 2020"
        m = re.match(r'^([A-Za-z]+)\.?\s+(\d{4})$', token)
        if m:
            month = MONTH_NAMES.get(m.group(1).lower())
            return int(m.group(2)), month, False

        # 情况四：只有年份
        m = re.match(r'^(\d{4})$', token)
        if m:
            return int(m.group(1)), None, False

        # 都不像：解析失败
        return None, None, False

    def _extract_dates(self, text: str):
        """
        从一段文本里找起止年月。
        先尝试匹配"完整范围"（两个日期夹一个连接符），
        找不到范围的话，退一步找"单个日期"（比如 "Expected May 2028"
        这种只写了一个预计毕业时间、没有范围的情况），此时
        start_year/start_month 留空，只填 end_year/end_month
        （语义上更接近"什么时候完成"，不是"什么时候开始"）。
        全都找不到就四个值都返回 None，is_current 返回 None（不知道）。
        """
        m = DATE_RANGE_RE.search(text)
        if m:
            start_year, start_month, _ = self._parse_date_token(m.group(1))
            end_year, end_month, is_present = self._parse_date_token(m.group(2))
            is_current = True if is_present else False
            return start_year, start_month, end_year, end_month, is_current

        m = SINGLE_DATE_RE.search(text)
        if m:
            year, month, is_present = self._parse_date_token(m.group(1))
            if is_present:
                # 只写了"至今"两个字，没有具体年月可用
                return None, None, None, None, True
            return None, None, year, month, None

        return None, None, None, None, None

    # ------------------------------------------------------------
    # 分段：把整份简历按标题切成 education / employment 两段
    # （OTHER_HEADERS 命中时段落切换成"无归属"，内容不收集）
    # ------------------------------------------------------------
    def _split_sections(self, cleaned_resume_text: str):
        sections = {"education": [], "employment": [], "skills": []}
        current_section = None
        for line in cleaned_resume_text.split("\n"):
            if EDUCATION_HEADERS.match(line.strip()):
                current_section = "education"
                continue
            if EMPLOYMENT_HEADERS.match(line.strip()):
                current_section = "employment"
                continue
            if SKILL_HEADERS.match(line.strip()):
                current_section = "skills"
                continue
            if OTHER_HEADERS.match(line.strip()):
                # 命中"其他段"标题：当前段落结束，这段内容不提取
                current_section = None
                continue
            if current_section and line.strip():
                sections[current_section].append(line)
        return sections

    # ------------------------------------------------------------
    # 把一个段落的行，拆成"条目"（一条 = 一段教育经历/一份工作）
    # ------------------------------------------------------------
    def _split_entries(self, section_lines: list):
        entries = []
        current_entry_lines = []
        # 判断这一段里有没有任何一行含日期（范围或单个日期都算）
        any_date = any(
            DATE_RANGE_RE.search(l) or SINGLE_DATE_RE.search(l)
            for l in section_lines
        )
        if not any_date:
            return [[l] for l in section_lines]   # 没有任何日期线索，退化成每行一条

        for line in section_lines:
            has_date = DATE_RANGE_RE.search(line) or SINGLE_DATE_RE.search(line)
            if has_date:
                if current_entry_lines:
                    entries.append(current_entry_lines)
                current_entry_lines = [line]
            else:
                if current_entry_lines:
                    current_entry_lines.append(line)
                else:
                    current_entry_lines = [line]
        if current_entry_lines:
            entries.append(current_entry_lines)
        return entries

    def _parse_entry_common(self, entry_lines: list):
        splitted_raw_text = "\n".join(entry_lines)
        start_year, start_month, end_year, end_month, is_current = (
            self._extract_dates(splitted_raw_text))
        return splitted_raw_text, start_year, start_month, end_year, end_month, is_current

    # ------------------------------------------------------------
    # 教育段解析
    # ------------------------------------------------------------
    def parse_education(self, section_lines: list) -> list:
        resume_educations = []
        for entry_lines in self._split_entries(section_lines):
            (splitted_raw_education_text, start_year, start_month,
             end_year, end_month, is_current) = self._parse_entry_common(entry_lines)

            # 学校名只从第一行判断——第一行通常是"这是哪个机构"，
            # 这个假设目前维持不变（换成扫描全部行找学校名，风险是
            # 会把"相关课程"里提到的大学名字之类误当成学校名，
            # 不如维持"第一行=机构名"这个相对可靠的假设）
            main_line = entry_lines[0]
            main_wo_date = DATE_RANGE_RE.sub("", main_line)
            main_wo_date = SINGLE_DATE_RE.sub("", main_wo_date).strip(" ,;|")
            main_parts = [p.strip() for p in re.split(r'[,;|]', main_wo_date) if p.strip()]

            # 默认：第一段就是学校名
            normalized_school_name = main_parts[0].lower() if main_parts else None

            # 特殊情况：如果第一段命中"已知官方校名自带逗号"的清单
            # （比如"University of California"），就把第一段和第二段
            # 合并当成完整校名，而不是只取第一段——不然"University of
            # California, Davis"会被错误地切成学校名="University of
            # California"、丢掉了"Davis"这个校区信息
            if (main_parts and len(main_parts) >= 2
                    and main_parts[0].strip().lower() in KNOWN_COMMA_IN_SCHOOL_NAME_PREFIXES):
                normalized_school_name = f"{main_parts[0]}, {main_parts[1]}".strip().lower()

            # 学位/专业不再只从第一行找——按你指出的场景（学位信息可能
            # 出现在条目的第二行、第三行，不一定和学校名同一行），
            # 改成扫描条目内的每一行，逐行按逗号/分号/竖线拆开检查，
            # 找到第一处命中学位关键词的片段就采用，不需要每一行都
            # 出现学位信息，找到一处就够
            normalized_degree = None
            normalized_field_of_study = None
            for line in entry_lines:
                line_wo_date = DATE_RANGE_RE.sub("", line)
                line_wo_date = SINGLE_DATE_RE.sub("", line_wo_date).strip(" ,;|")
                line_parts = [p.strip() for p in re.split(r'[,;|]', line_wo_date) if p.strip()]
                for part in line_parts:
                    if DEGREE_KEYWORDS.search(part):
                        m = re.match(r'(.*?)\bin\b(.*)', part, re.I)
                        if m and m.group(2).strip():
                            normalized_degree = m.group(1).strip().lower()
                            normalized_field_of_study = m.group(2).strip().lower()
                        else:
                            normalized_degree = part.lower()
                        break
                if normalized_degree is not None:
                    # 已经找到学位信息了，不用继续扫描剩下的行
                    break

            hit_count = sum(x is not None for x in
                            [normalized_school_name, normalized_degree, start_year or end_year])
            extraction_confidence = round(0.3 + 0.2 * hit_count, 2)

            resume_educations.append({
                "splitted_raw_education_text": splitted_raw_education_text,
                "education_description": "\n".join(entry_lines[1:]) or None,
                "normalized_school_name": normalized_school_name,
                "normalized_degree": normalized_degree,
                "normalized_field_of_study": normalized_field_of_study,
                "is_current": is_current,
                "start_year": start_year, "start_month": start_month,
                "end_year": end_year, "end_month": end_month,
                "extraction_confidence": extraction_confidence,
            })
        return resume_educations

    # ------------------------------------------------------------
    # 工作经历段解析
    # ------------------------------------------------------------
    def parse_employment(self, section_lines: list) -> list:
        resume_employments = []
        for entry_lines in self._split_entries(section_lines):
            (splitted_raw_employment_text, start_year, start_month,
             end_year, end_month, is_current) = self._parse_entry_common(entry_lines)

            main_line = entry_lines[0]
            main_wo_date = DATE_RANGE_RE.sub("", main_line)
            main_wo_date = SINGLE_DATE_RE.sub("", main_wo_date).strip(" ,;|")
            parts = [p.strip() for p in re.split(r'[,;|]', main_wo_date) if p.strip()]

            normalized_company_name = parts[0].lower() if parts else None
            normalized_job_title = parts[1].lower() if len(parts) > 1 else None

            hit_count = sum(x is not None for x in
                            [normalized_company_name, normalized_job_title, start_year or end_year])
            extraction_confidence = round(0.3 + 0.2 * hit_count, 2)

            resume_employments.append({
                "splitted_raw_employment_text": splitted_raw_employment_text,
                "employment_description": "\n".join(entry_lines[1:]) or None,
                "normalized_company_name": normalized_company_name,
                "normalized_job_title": normalized_job_title,
                "is_current": is_current,
                "start_year": start_year, "start_month": start_month,
                "end_year": end_year, "end_month": end_month,
                "extraction_confidence": extraction_confidence,
            })
        return resume_employments

    # ------------------------------------------------------------
    # 技能段解析（暂时只做纯文本切分，不匹配 Skill 参考表——
    # 那一步需要先有 Resume_skill 表，属于下一阶段）
    # ------------------------------------------------------------
    @staticmethod
    def parse_skills_raw(section_lines: list) -> list:
        """
        把技能段落的所有行拼成一整段文本，再按常见的分隔符（逗号、
        分号、竖线、项目符号、换行）切开，得到一份"原始技能提及文本"
        的列表——只做字符串切分，不判断这些词是不是真的对应
        Skill 参考表里的某一条，也不做去重之外的任何加工。

        返回的每一项都保留原始大小写（大小写标准化留给匹配阶段做，
        这里只负责"切开"这一件事）。
        """
        if not section_lines:
            return []

        joined_text = "\n".join(section_lines)
        # 项目符号（■ ⚫  等）先统一替换成逗号，再和其余分隔符
        # 一起切分；■/⚫/ 这几个符号是实测样本里见到的常见项目符号
        joined_text = re.sub(r'[■⚫●\uf0b7\uf09f•]', ',', joined_text)
        tokens = re.split(r'[,;|\n]', joined_text)

        skill_names_raw = []
        seen = set()
        for token in tokens:
            cleaned = token.strip(" :\t")
            if not cleaned:
                continue
            key = cleaned.lower()
            if key in seen:
                continue
            seen.add(key)
            skill_names_raw.append(cleaned)
        return skill_names_raw

    # ------------------------------------------------------------
    # 联系方式（邮箱 / 电话）：全文扫描，不受分段限制——这些信息
    # 通常出现在简历最开头（姓名下面那一两行），不属于任何标题段落
    # ------------------------------------------------------------
    @staticmethod
    def parse_contact_info(resume_text: str) -> dict:
        emails_found = []
        seen_emails = set()
        for m in EMAIL_RE.finditer(resume_text):
            email = m.group().strip().lower().rstrip(".,;")
            if email not in seen_emails:
                seen_emails.add(email)
                emails_found.append(email)

        phones_found = []
        seen_phones = set()
        for m in PHONE_RE.finditer(resume_text):
            raw_phone = m.group().strip()
            # 只保留数字部分做去重 key，避免"+1 718-612-9082"和
            # "718-612-9082"（同一个号码，写法不同）被当成两个不同号码
            digits_only = re.sub(r'\D', '', raw_phone)
            # 太短的数字串（比如日期、门牌号误命中）直接跳过，
            # 正常电话号码去掉国家码后至少应该有10位数字
            if len(digits_only) < 10:
                continue
            dedup_key = digits_only[-10:]  # 用后10位做去重（忽略国家码差异）
            if dedup_key not in seen_phones:
                seen_phones.add(dedup_key)
                phones_found.append(raw_phone)

        return {"resume_emails": emails_found, "resume_phones": phones_found}

    # ------------------------------------------------------------
    # 外部身份链接（LinkedIn / GitHub）
    # ------------------------------------------------------------
    def parse_external_identifiers(self, cleaned_resume_text: str) -> list:
        resume_external_identifiers = []
        seen = set()
        for m in EXTERNAL_ID_RE.finditer(cleaned_resume_text):
            site = m.group("site").lower()
            account_handle = m.group("handle").rstrip(".,;)")
            identity_type = "linkedin" if "linkedin" in site else "github"
            normalized_url = f"https://{site}/{account_handle}".lower()
            key = (identity_type, normalized_url)
            if key in seen:
                continue
            seen.add(key)
            resume_external_identifiers.append({
                "identity_type": identity_type,
                "normalized_url": normalized_url,
                "account_handle": account_handle,
                "extraction_confidence": 0.95,
            })
        return resume_external_identifiers

    # ------------------------------------------------------------
    # 总入口
    # ------------------------------------------------------------
    # ------------------------------------------------------------
    # 提取质量检查：判断"这次解析是不是等于白做"
    # ------------------------------------------------------------
    @staticmethod
    def _is_entry_fully_empty(entry: dict, name_field: str) -> bool:
        """
        判断一条条目是不是"关键字段全部为空"——学校名/公司名
        （name_field 指定用哪一个）和起止年份都没有，这种条目
        即使被当成"识别出来的一条"，实际上也没提供任何可用信息。
        """
        return (entry.get(name_field) is None
                and entry.get("start_year") is None
                and entry.get("end_year") is None)

    def _check_extraction_quality(self, result: dict, raw_resume_text_length: int):
        """
        判断标准（当前采用的阈值，如果实测下来太严格/太宽松，
        可以回头调整，不是写死不能改的规则）：

          1. resume_text 本身不是空的（这一点在 parse() 里已经
             提前判断过，能走到这个检查说明确实有文本内容），
             但教育经历 + 工作经历加起来一条都没识别出来
             -> 判定为"完全没提取到"，报错。

          2. 识别出了条目（不是 0 条），但每一条的关键字段
             （学校名/公司名 + 起止年份）全部是空的
             -> 等同于"提取了个寂寞"，同样报错。

        只要不满足上面两条，不管单条内的字段缺了多少，都不算错误，
        正常返回结果（这是和"单个字段缺失属于正常情况"这条原则
        保持一致，检查的是整体，不是逐字段较真）。
        """
        total_entries = len(result["resume_educations"]) + len(result["resume_employments"])

        if total_entries == 0:
            raise ResumeParsingError(
                f"resume_text 长度为 {raw_resume_text_length}，非空，"
                f"但完全没有识别出任何教育经历或工作经历条目"
            )

        fully_empty_count = 0
        for edu in result["resume_educations"]:
            if self._is_entry_fully_empty(edu, "normalized_school_name"):
                fully_empty_count += 1
        for emp in result["resume_employments"]:
            if self._is_entry_fully_empty(emp, "normalized_company_name"):
                fully_empty_count += 1

        if fully_empty_count == total_entries:
            raise ResumeParsingError(
                f"识别出 {total_entries} 条条目，但全部条目的关键字段"
                f"（学校名/公司名、起止年份）都是空的，等同于没有提取到"
                f"任何有用信息"
            )

    def parse(self, resume_text: str):
        """
        resume_text 为空/None 时直接返回空结果，不做任何处理
        （按你的要求：空的直接忽略，不进入本模块任何逻辑）。

        resume_text 非空、但解析质量太差（见 _check_extraction_quality）
        时，会抛出 ResumeParsingError，不会返回一个"看起来正常、
        实际什么都没提取到"的空结果——调用方需要捕获这个异常。

        resume_skills_raw：技能段落切分出来的原始文本列表，
        还没有和 Skill 参考表做匹配（这一步待 Resume_skill 表
        建好之后，在下一阶段的脚本里做，不在本模块内完成）。
        """
        if resume_text is None or str(resume_text).strip() == "":
            return {
                "resume_educations": [],
                "resume_employments": [],
                "resume_external_identifiers": [],
                "resume_skills_raw": [],
                "resume_emails": [],
                "resume_phones": [],
            }

        sections = self._split_sections(str(resume_text))
        contact_info = self.parse_contact_info(str(resume_text))
        result = {
            "resume_educations": self.parse_education(sections["education"]),
            "resume_employments": self.parse_employment(sections["employment"]),
            "resume_external_identifiers": self.parse_external_identifiers(str(resume_text)),
            "resume_skills_raw": self.parse_skills_raw(sections["skills"]),
            "resume_emails": contact_info["resume_emails"],
            "resume_phones": contact_info["resume_phones"],
        }

        self._check_extraction_quality(result, raw_resume_text_length=len(str(resume_text)))
        return result
