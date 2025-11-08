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
mapped AS (  -- 재분류: 기타업무 중 4개 프로젝트는 제품개발(엔진)
    SELECT
        CASE
            WHEN "업무_계정" = '기타업무'
             AND (
                    "프로젝트명" IN ('국내 인증(엔진)','국외 인증(엔진)','검정/인증')
                    OR REPLACE("프로젝트명",' ','') = '엔진시험'
                 )
            THEN '제품개발(엔진)'
            ELSE "업무_계정"
        END AS acct,
        ym,
        hours
    FROM base
),
-- 4~9월만 사용
acct_month AS (  -- 계정 × 월 합
    SELECT acct, ym, SUM(hours) AS hours_acct_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY acct, ym
),
month_total AS (  -- 월별 전체 합
    SELECT ym, SUM(hours) AS hours_total_month
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY ym
),
ratio AS (  -- 월별 투입률(%)
    SELECT
        a.acct,
        a.ym,
        (a.hours_acct_month * 100.0) / t.hours_total_month AS r
    FROM acct_month a
    JOIN month_total t ON a.ym = t.ym
),
period_acct AS (  -- 계정별 4~9월 누적 시간
    SELECT acct, SUM(hours) AS hours_acct_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
    GROUP BY acct
),
period_total AS (  -- 전체 4~9월 누적 시간
    SELECT SUM(hours) AS hours_total_period
    FROM mapped
    WHERE ym IN ('2025-04','2025-05','2025-06','2025-07','2025-08','2025-09')
)
SELECT
    r.acct AS "업무_계정",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-04' THEN r.r END),0), 2) AS "2025-04_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-05' THEN r.r END),0), 2) AS "2025-05_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-06' THEN r.r END),0), 2) AS "2025-06_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-07' THEN r.r END),0), 2) AS "2025-07_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-08' THEN r.r END),0), 2) AS "2025-08_%",
    ROUND(COALESCE(SUM(CASE WHEN r.ym='2025-09' THEN r.r END),0), 2) AS "2025-09_%",
    ROUND(AVG(r.r), 2) AS "평균_%",
    ROUND( (pa.hours_acct_period * 100.0) / pt.hours_total_period, 2) AS "총합_%"
FROM ratio r
JOIN period_acct pa ON pa.acct = r.acct
JOIN period_total pt ON 1=1
GROUP BY r.acct
ORDER BY "총합_%" DESC;   -- 필요에 따라 정렬 기준 변경
