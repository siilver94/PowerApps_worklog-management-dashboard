-- task_DB 테이블 생성 스크립트
CREATE TABLE Task_DB (
    작성자 VARCHAR(100),
    ID INT PRIMARY KEY,
    업무_계정 VARCHAR(100),
    프로젝트명 VARCHAR(255),
    PM VARCHAR(100),
    시작날짜 DATE,
    종료날짜 DATE,
    관련기종명 VARCHAR(100),
    업무제목 VARCHAR(255),
    업무_시작일자 DATE,
    업무_종료일자 DATE,
    관련ECN VARCHAR(100),
    업무요청자 VARCHAR(100),
    상태 VARCHAR(50),
    상세_업무내용 VARCHAR(1000),
    비고 VARCHAR(500)
);
