-- UserInfo_DB 테이블 생성 스크립트
CREATE TABLE UserInfo_DB (
    이름_한글 VARCHAR(100),
    이름_영문 VARCHAR(100),
    e_mail VARCHAR(100),
    부문 VARCHAR(50),
    팀 VARCHAR(50),
    직급 VARCHAR(50),
    생년월일 VARCHAR(10),
    사번 INT PRIMARY KEY,
    입사일자 VARCHAR(10),
    과학시술인번호 VARCHAR(50),
    최종학력_학교 VARCHAR(100),
    최종학력_학위 VARCHAR(50),
    학위번호 VARCHAR(50),
    연락처 VARCHAR(20),
    차량번호 VARCHAR(20),
    차종 VARCHAR(50),
    자택주소 VARCHAR(255)
);
