WITH dup_check AS (
  SELECT
    작성일자,
    업무제목,
    작업내용,
    작업시간,
    COUNT(*) AS dup_count
  FROM Daily_DB
  WHERE 작성일자 IS NOT NULL
    AND 업무제목 IS NOT NULL
    AND 작업내용 IS NOT NULL
    AND 작업시간 IS NOT NULL
  GROUP BY 작성일자, 업무제목, 작업내용, 작업시간
  HAVING COUNT(*) > 1
)
SELECT D.*
FROM Daily_DB AS D
JOIN dup_check AS C
  ON D.작성일자 = C.작성일자
 AND D.업무제목 = C.업무제목
 AND D.작업내용 = C.작업내용
 AND D.작업시간 = C.작업시간
ORDER BY D.작성일자, D.업무제목;
