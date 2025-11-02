-- [월×업무_계정(대분류)×프로젝트명(소분류) — 표준화 기준 중심]
WITH
params AS (
  SELECT date('2025-04-01') AS d_start,
         date('2025-09-30') AS d_end
),

/* 0) 날짜 보정 + 원천 필터(작성자/업무_계정 제외) */
raw AS (
  SELECT
    date(COALESCE(NULLIF(작성일자,''), NULLIF("만든 날짜",'')))                 AS d,
    TRIM(작성자)                                                               AS person,
    COALESCE(NULLIF(TRIM(팀),''), '(미지정팀)')                                AS team,
    COALESCE(NULLIF(TRIM(업무_계정),''), '(미지정계정)')                        AS cat,   -- 대분류
    COALESCE(NULLIF(TRIM(프로젝트명),''), '기타업무')                           AS proj,  -- 소분류
    CAST(작업시간 AS REAL)                                                     AS hours
  FROM Daily_DB
  WHERE 작성자 IS NOT NULL
    AND TRIM(작성자) <> ''
    AND TRIM(작성자) NOT IN (
      '김승동','윤원병','김정훈','문종태','이병혁','이혜광',
      '홍이수','김은성','고지호','박형남','윤광덕','임승진',
      '이해림','강경식'
    )
    -- 원천에서 특정 계정 제외
    AND COALESCE(TRIM(업무_계정),'') NOT IN ('TF','교육','기타업무','연차(반차)')
),

/* 기간 제한 */
raw_cut AS (
  SELECT *
  FROM raw, params
  WHERE d IS NOT NULL
    AND d BETWEEN params.d_start AND params.d_end
	AND strftime('%w', d) IN ('1','2','3','4','5')
),

/* 1) 동일 인물·일자·대분류·소분류 합산 */
base AS (
  SELECT d, person, team, cat, proj, SUM(hours) AS hours
  FROM raw_cut
  GROUP BY d, person, team, cat, proj
),

/* 2) 1인-1일 합계(현재 ‘기타업무’ 제외 상태에서의 합) */
person_day AS (
  SELECT d, person, team, SUM(hours) AS sum_hours
  FROM base
  GROUP BY d, person, team
),

/* 3) 미작성/미달분을 '기타업무'로 생성(집계에서는 제외 예정) */
remainder AS (
  SELECT d, person, team, MAX(8.0 - sum_hours, 0.0) AS etc_add
  FROM person_day
),

/* 4) 보정 적용(대분류=‘기타업무’, 소분류=‘기타업무’로 추가) */
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

/* 6) 일별 참여 인원(‘기타업무’ 제외: 카운트 대상은 실프로젝트 참여자) */
writers_day AS (
  SELECT d, COUNT(DISTINCT person) AS writers_cnt
  FROM completed_aggr
  WHERE proj <> '기타업무'
  GROUP BY d
),

/* 7) 일자-대분류-소분류 시간(‘기타업무’ 제외) */
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

/* 9) 월별 표준용량(분모) = Σ(일 참여자수×8)  — 월 공통 값 */
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

/* 11) 월×대분류×소분류 고유 투입인원(한 번이라도 참여) */
cat_proj_unique_writers AS (
  SELECT
    strftime('%Y-%m', ca.d) AS ymonth,
    ca.cat,
    ca.proj,
    COUNT(DISTINCT ca.person) AS unique_writers
  FROM completed_aggr ca
  WHERE ca.proj <> '기타업무'
  GROUP BY strftime('%Y-%m', ca.d), ca.cat, ca.proj
)

SELECT
  cpm.ymonth                                              AS 월,
  cpm.cat                                                 AS 업무_계정_대분류,
  cpm.proj                                                AS 프로젝트명_소분류,
  ROUND(cpm.proj_hours, 1)                                AS 프로젝트_총시간,
  ROUND(mc.month_capacity_hours, 1)                        AS 표준용량,           -- 월 공통
  ROUND(cpm.proj_hours * 100.0 / NULLIF(mc.month_capacity_hours,0), 2)
      AS 투입률_표준화기준_퍼센트,
  cpu.unique_writers                                      AS 고유_투입인원,
  ROUND(CASE WHEN cpu.unique_writers > 0
        THEN cpm.proj_hours * 1.0 / cpu.unique_writers END, 1)
      AS "1인_평균투입시간"
FROM cat_proj_month cpm
JOIN month_capacity mc              ON mc.ymonth = cpm.ymonth
LEFT JOIN cat_proj_unique_writers cpu
       ON cpu.ymonth = cpm.ymonth AND cpu.cat = cpm.cat AND cpu.proj = cpm.proj
ORDER BY 월, 업무_계정_대분류, 프로젝트명_소분류;

