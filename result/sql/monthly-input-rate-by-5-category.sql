WITH base AS (
    SELECT
        date("작성일자") AS d,
        strftime('%Y-%m', "작성일자") AS ym,
        "업무_계정",
        "프로젝트명",
        "작업시간" AS hours
    FROM "Daily_DB"
    WHERE
        "작성일자" >= '2025-01-01' AND "작성일자" < '2026-01-01'
        AND strftime('%w', "작성일자") NOT IN ('0','6')
        AND "프로젝트명" <> '연차(반차)'
),

mapped AS (  -- 대분류·소분류 동시 매핑
    SELECT
        CASE
            WHEN "업무_계정" IN ('제품개발', '기술개발', '설계변경')
                 OR ("업무_계정"='기타업무' AND "프로젝트명" IN ('국내 인증(엔진)','국외 인증(엔진)','검정/인증','엔진 시험'))
                THEN '개발'
            WHEN "업무_계정"='기타업무' OR "프로젝트명"='연차(반차)'
                THEN '기타'
            WHEN "업무_계정"='TF'
                THEN 'TF'
            WHEN "업무_계정"='교육'
                THEN '교육'
            WHEN "업무_계정"='원가절감'
                THEN '원가절감'
            ELSE '기타'
        END AS 대분류,
        
        CASE
            WHEN "업무_계정" IN ('제품개발') THEN '제품개발'
            WHEN "업무_계정" IN ('기술개발') THEN '기술개발'
            WHEN "업무_계정" IN ('설계변경') THEN '설계변경'
            WHEN "업무_계정"='기타업무' AND "프로젝트명" IN ('국내 인증(엔진)','국외 인증(엔진)','검정/인증','엔진 시험')
                THEN '제품개발(엔진)'
            WHEN "업무_계정"='기타업무' THEN '기타업무'
            WHEN "프로젝트명"='연차(반차)' THEN '연차(반차)'
            WHEN "업무_계정" IN ('TF','교육','원가절감') THEN '-'
            ELSE '-'
        END AS 소분류,
        ym,
        hours
    FROM base
),

acct_month AS (
    SELECT 대분류, 소분류, ym, SUM(hours) AS hours_acct_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY 대분류, 소분류, ym
),

month_total AS (
    SELECT ym, SUM(hours) AS hours_total_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY ym
),

ratio AS (
    SELECT
        a.대분류,
        a.소분류,
        a.ym,
        (a.hours_acct_month * 100.0) / t.hours_total_month AS r
    FROM acct_month a
    JOIN month_total t ON a.ym = t.ym
),

period_acct AS (
    SELECT 대분류, 소분류, SUM(hours) AS hours_acct_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY 대분류, 소분류
),

period_total AS (
    SELECT SUM(hours) AS hours_total_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
)

SELECT
    r.대분류 AS "업무_대분류",
    r.소분류 AS "업무_소분류",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-04' THEN r.r END),0), 2) AS "2025-04_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-05' THEN r.r END),0), 2) AS "2025-05_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-06' THEN r.r END),0), 2) AS "2025-06_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-07' THEN r.r END),0), 2) AS "2025-07_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-08' THEN r.r END),0), 2) AS "2025-08_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-09' THEN r.r END),0), 2) AS "2025-09_%",
    ROUND(AVG(r.r), 2) AS "평균_%",
    ROUND((pa.hours_acct_period * 100.0) / pt.hours_total_period, 2) AS "총합_%"
FROM ratio r
JOIN period_acct pa ON pa.대분류 = r.대분류 AND pa.소분류 = r.소분류
JOIN period_total pt ON 1=1
GROUP BY r.대분류, r.소분류
ORDER BY r.대분류, "총합_%" DESC;
