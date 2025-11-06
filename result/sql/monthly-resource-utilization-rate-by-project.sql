-- [메인: 4~9월 토탈 + 월별 퍼센트(표준화 기준), 주말 제외]
WITH
params AS (
  SELECT date('2025-04-01') AS d_start,
         date('2025-09-30') AS d_end
),

/* 0) 원천 로우(작성자/날짜 보정/인원 제외까지만) */
raw0 AS (
  SELECT
    date(COALESCE(NULLIF(작성일자,''), NULLIF("만든 날짜",''))) AS d,
    TRIM(작성자)                                AS person,
    COALESCE(NULLIF(TRIM(팀),''),'(미지정팀)')           AS team,
    TRIM(COALESCE(업무_계정,''))                 AS cat_raw,
    TRIM(COALESCE(프로젝트명,''))                AS proj_raw,
    CAST(작업시간 AS REAL)                      AS hours
  FROM Daily_DB
  WHERE 작성자 IS NOT NULL
    AND TRIM(작성자) <> ''
    AND TRIM(작성자) NOT IN (
      '김승동','윤원병','김정훈','문종태','이병혁','이혜광','홍이수','김은성',
      '고지호','박형남','윤광덕','임승진','이해림','강경식'
    )
),

/* 0-1) 최종 필터 + 대분류 재분류 적용
   - TF: '3D데이터 정비 및 사양관리'만 제외, 나머지 TF는 포함
   - 기타업무: 지정 4개 프로젝트는 포함 + cat을 '제품개발(엔진)'으로 재분류, 나머지 기타업무는 제외
   - 교육/연차(반차): 제외
*/
raw AS (
  SELECT
    d,
    person,
    team,
    CASE
      WHEN cat_raw = '기타업무' AND proj_raw IN ('국내 인증(엔진)','국외 인증(엔진)','엔진시험','검정/인증')
        THEN '제품개발(엔진)'
      WHEN TRIM(COALESCE(cat_raw,'')) = '' THEN '(미지정계정)'
      ELSE cat_raw
    END AS cat,                                            -- 대분류(재분류 반영)
    CASE
      WHEN TRIM(COALESCE(proj_raw,'')) = '' THEN '기타업무'
      ELSE proj_raw
    END AS proj,                                           -- 소분류
    hours
  FROM raw0
  WHERE d IS NOT NULL
    -- 포함 규칙
    AND (
      -- 일반: TF/교육/기타업무/연차(반차) 외 카테고리는 포함
      COALESCE(cat_raw,'') NOT IN ('TF','교육','기타업무','연차(반차)')
      -- TF: 특정 프로젝트만 제외
      OR (cat_raw = 'TF' AND proj_raw <> '3D데이터 정비 및 사양관리')
      -- 기타업무: 지정 4개 프로젝트만 포함
      OR (cat_raw = '기타업무' AND proj_raw IN ('국내 인증(엔진)','국외 인증(엔진)','엔진시험','검정/인증'))
    )
    -- 교육/연차(반차)는 무조건 제외 (안전망)
    AND COALESCE(cat_raw,'') NOT IN ('교육','연차(반차)')
),

/* 1) 기간 제한 + 주말 제외 (월=1 ~ 금=5) */
raw_cut AS (
  SELECT *
  FROM raw, params
  WHERE d BETWEEN params.d_start AND params.d_end
    AND strftime('%w', d) IN ('1','2','3','4','5')
),

/* 2) 동일 인물·일자·대분류·소분류 합산 */
base AS (
  SELECT d, person, team, cat, proj, SUM(hours) AS hours
  FROM raw_cut
  GROUP BY d, person, team, cat, proj
),

/* 3) 1인-1일 합계 */
person_day AS (
  SELECT d, person, team, SUM(hours) AS sum_hours
  FROM base
  GROUP BY d, person, team
),

/* 4) 미작성/미달 → '기타업무' 생성(집계에선 제외) */
remainder AS (
  SELECT d, person, team, MAX(8.0 - sum_hours, 0.0) AS etc_add
  FROM person_day
),
completed AS (
  SELECT d, person, team, cat, proj, hours FROM base
  UNION ALL
  SELECT d, person, team, '기타업무' AS cat, '기타업무' AS proj, etc_add
  FROM remainder
  WHERE etc_add > 0
),

/* 5) 보정 후 재합산 */
completed_aggr AS (
  SELECT d, person, team, cat, proj, SUM(hours) AS hours
  FROM completed
  GROUP BY d, person, team, cat, proj
),

/* 6) 일별 참여 인원 (기타업무 제외) */
writers_day AS (
  SELECT d, COUNT(DISTINCT person) AS writers_cnt
  FROM completed_aggr
  WHERE proj <> '기타업무'
  GROUP BY d
),

/* 7) 일자-대분류-소분류 시간 (기타업무 제외) */
project_day AS (
  SELECT d, cat, proj, SUM(hours) AS proj_hours
  FROM completed_aggr
  WHERE proj <> '기타업무'
  GROUP BY d, cat, proj
),

/* 8) 월 키 */
keys AS (
  SELECT DISTINCT
    d,
    strftime('%Y-%m', d) AS ymonth
  FROM project_day
),

/* 9) 월별 표준용량(분모) = Σ(일 참여자수 × 8) */
month_capacity AS (
  SELECT
    strftime('%Y-%m', d) AS ymonth,
    SUM(writers_cnt * 8.0) AS month_capacity_hours
  FROM writers_day
  GROUP BY ymonth
),

/* 10) 월×대분류×소분류 시간(분자) */
cat_proj_month AS (
  SELECT
    k.ymonth,
    p.cat,
    p.proj,
    SUM(p.proj_hours) AS proj_hours
  FROM project_day p
  JOIN keys k ON k.d = p.d
  GROUP BY k.ymonth, p.cat, p.proj
),

/* 11) 기간(4~9월) 토탈 분모/분자 */
period_capacity AS (
  SELECT SUM(month_capacity_hours) AS cap_total
  FROM month_capacity
),
cat_proj_period AS (
  SELECT
    cat, proj,
    SUM(proj_hours) AS proj_total_hours
  FROM cat_proj_month
  GROUP BY cat, proj
),

/* 12) 프로젝트별 월별 퍼센트(표준화) 계산용 */
cat_proj_month_pct AS (
  SELECT
    m.ymonth,
    m.cat, m.proj,
    ROUND(m.proj_hours * 100.0 / NULLIF(c.month_capacity_hours, 0), 2) AS pct_month
  FROM cat_proj_month m
  JOIN month_capacity c ON c.ymonth = m.ymonth
),

/* 13) 프로젝트별 월별 퍼센트를 피벗(4~9월) */
cat_proj_month_pivot AS (
  SELECT
    cat, proj,
    ROUND(SUM(CASE WHEN ymonth='2025-04' THEN pct_month END), 2) AS "2025-04_%",
    ROUND(SUM(CASE WHEN ymonth='2025-05' THEN pct_month END), 2) AS "2025-05_%",
    ROUND(SUM(CASE WHEN ymonth='2025-06' THEN pct_month END), 2) AS "2025-06_%",
    ROUND(SUM(CASE WHEN ymonth='2025-07' THEN pct_month END), 2) AS "2025-07_%",
    ROUND(SUM(CASE WHEN ymonth='2025-08' THEN pct_month END), 2) AS "2025-08_%",
    ROUND(SUM(CASE WHEN ymonth='2025-09' THEN pct_month END), 2) AS "2025-09_%"
  FROM cat_proj_month_pct
  GROUP BY cat, proj
),

/* 14) 기간 전체 고유 투입인원(프로젝트별) */
cat_proj_unique_period AS (
  SELECT
    ca.cat, ca.proj,
    COUNT(DISTINCT ca.person) AS unique_writers_period
  FROM completed_aggr ca
  WHERE ca.proj <> '기타업무'
    AND ca.d BETWEEN (SELECT d_start FROM params) AND (SELECT d_end FROM params)
    AND strftime('%w', ca.d) IN ('1','2','3','4','5')
  GROUP BY ca.cat, ca.proj
)

SELECT
  cpp.cat                                   AS "업무_계정_대분류",
  cpp.proj                                  AS "프로젝트명_소분류",

  ROUND(cpp.proj_total_hours, 1)            AS "총_프로젝트시간",
  ROUND(pc.cap_total, 1)                    AS "총_표준용량",
  ROUND(cpp.proj_total_hours * 100.0 / NULLIF(pc.cap_total, 0), 2)
                                            AS "총_투입률_표준화(%)",

  cpu.unique_writers_period                 AS "전체_고유_투입인원",
  ROUND(CASE WHEN cpu.unique_writers_period > 0
       THEN cpp.proj_total_hours * 1.0 / cpu.unique_writers_period END, 1)
                                            AS "기간_1인_평균시간",

  p."2025-04_%" , p."2025-05_%" , p."2025-06_%" ,
  p."2025-07_%" , p."2025-08_%" , p."2025-09_%"
FROM cat_proj_period cpp
JOIN period_capacity pc          ON 1=1
LEFT JOIN cat_proj_month_pivot p ON p.cat = cpp.cat AND p.proj = cpp.proj
LEFT JOIN cat_proj_unique_period cpu
       ON cpu.cat = cpp.cat AND cpu.proj = cpp.proj
ORDER BY "총_투입률_표준화(%)" DESC, "총_프로젝트시간" DESC;
