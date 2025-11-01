-- [중복 데이터 정리: 작성일자 + 업무제목 + 작업내용 + 작업시간 완전 일치 시 1건만 남김]
DELETE FROM Daily_DB
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM Daily_DB
  WHERE 작성일자 IS NOT NULL
    AND 업무제목 IS NOT NULL
    AND 작업내용 IS NOT NULL
    AND 작업시간 IS NOT NULL
  GROUP BY 작성일자, 업무제목, 작업내용, 작업시간
);
