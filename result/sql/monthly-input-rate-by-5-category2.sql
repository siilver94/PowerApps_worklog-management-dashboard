WITH base AS (  -- 기간/평일/연차 제외
    SELECT
        date("작성일자") AS d,
        strftime('%Y-%m', "작성일자") AS ym,
        "업무_계정",
        "프로젝트명",
        "작업시간" AS hours
    FROM "Daily_DB"
    WHERE
        "작성일자" >= '2025-01-01' AND "작성일자" < '2026-01-01'
        AND strftime('%w', "작성일자") NOT IN ('0','6')       -- 평일만
        AND "프로젝트명" <> '연차(반차)'                        -- 연차(반차) 제외
),

mapped AS (  -- 5개 대분류 매핑
    SELECT
        CASE
            -- ① 개발 그룹
            WHEN "업무_계정" IN ('제품개발', '기술개발', '설계변경')
                 OR ("업무_계정" = '기타업무' AND "프로젝트명" IN (
                        '국내 인증(엔진)','국외 인증(엔진)','검정/인증','엔진 시험'
                    ))
                 THEN '개발'

            -- ② 기타
            WHEN "업무_계정" = '기타업무' OR "프로젝트명" = '연차(반차)'
                 THEN '기타'

            -- ③ 교육
            WHEN "업무_계정" = '교육'
                 THEN '교육'

            -- ④ TF
            WHEN "업무_계정" = 'TF'
                 THEN 'TF'

            -- ⑤ 원가절감
            WHEN "업무_계정" = '원가절감'
                 THEN '원가절감'

            ELSE '기타'  -- 나머지는 안전하게 기타 처리
        END AS group_acct,
        ym,
        hours
    FROM base
),

-- 4~9월만 사용
acct_month AS (
    SELECT group_acct, ym, SUM(hours) AS hours_acct_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY group_acct, ym
),

month_total AS (
    SELECT ym, SUM(hours) AS hours_total_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY ym
),

ratio AS (  -- 월별 투입률(%)
    SELECT
        a.group_acct,
        a.ym,
        (a.hours_acct_month * 100.0) / t.hours_total_month AS r
    FROM acct_month a
    JOIN month_total t ON a.ym = t.ym
),

period_acct AS (
    SELECT group_acct, SUM(hours) AS hours_acct_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY group_acct
),

period_total AS (
    SELECT SUM(hours) AS hours_total_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
)

SELECT
    r.group_acct AS "업무_계정_대분류",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-04' THEN r.r END),0), 2) AS "2025-04_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-05' THEN r.r END),0), 2) AS "2025-05_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-06' THEN r.r END),0), 2) AS "2025-06_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-07' THEN r.r END),0), 2) AS "2025-07_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-08' THEN r.r END),0), 2) AS "2025-08_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-09' THEN r.r END),0), 2) AS "2025-09_%",
    ROUND(AVG(r.r), 2) AS "평균_%",
    ROUND((pa.hours_acct_period * 100.0) / pt.hours_total_period, 2) AS "총합_%"
FROM ratio r
JOIN period_acct pa ON pa.group_acct = r.group_acct
JOIN period_total pt ON 1=1
GROUP BY r.group_acct
ORDER BY "총합_%" DESC;
