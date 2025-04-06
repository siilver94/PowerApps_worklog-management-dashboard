#  DB Schema Repository

이 저장소는 당사 프로젝트에서 사용된 주요 데이터베이스 테이블의 구조를 문서화하기 위한 공간입니다.  
실제 데이터는 회사 보안 정책상 포함되어 있지 않으며, 테이블 구조만을 공유합니다.

##  Overview

| Table Name     | Description                                 |
|----------------|---------------------------------------------|
| `UserInfo_DB`  | 직원의 인적사항, 학력, 차량 정보 등 인사 데이터 관리 |
| `Daily_DB`     | 팀 및 개인별 일일 업무 이력 기록용 테이블         |
| `Project_DB`   | 프로젝트 기본 정보 및 예산 관리 테이블             |
| `Task_DB`      | 업무 요청 및 처리 이력 추적 테이블               |

---

##  Table Schemas

### UserInfo_DB

| Column Name        | Type      | Description         |
|--------------------|-----------|---------------------|
| 이름_한글           | VARCHAR   | 한글 이름             |
| 이름_영문           | VARCHAR   | 영문 이름             |
| e-mail             | VARCHAR   | 이메일 주소           |
| 부문                | VARCHAR   | 소속 부문             |
| 팀                  | VARCHAR   | 소속 팀               |
| 직급                | VARCHAR   | 직급 정보             |
| 생년월일             | VARCHAR   | YYYY-MM-DD 형식 생일 |
| 사번                | INT       | 직원 고유번호 (PK)     |
| 입사일자             | VARCHAR   | 입사 일자              |
| 과학시술인번호         | VARCHAR   | 인증 번호 (선택 사항)  |
| 최종학력_학교         | VARCHAR   | 졸업 학교              |
| 최종학력_학위         | VARCHAR   | 학위명                 |
| 학위번호             | VARCHAR   | 학위 등록 번호         |
| 연락처              | VARCHAR   | 휴대전화 번호          |
| 차량번호             | VARCHAR   | 차량 번호              |
| 차종                | VARCHAR   | 차량 모델명            |
| 자택주소             | VARCHAR   | 주소                   |

---

###  Daily_DB

| Column Name      | Type      | Description         |
|------------------|-----------|---------------------|
| ID               | INT       | 식별자 (PK)          |
| 작성일자           | VARCHAR   | 업무 기록 작성 날짜    |
| 팀                | VARCHAR   | 작성자 팀명           |
| 상태              | VARCHAR   | 업무 상태             |
| 업무_계정          | VARCHAR   | 계정 분류             |
| 프로젝트명          | VARCHAR   | 연결된 프로젝트 명     |
| 업무_시작일자        | VARCHAR   | 업무 시작 일자         |
| 업무_종료일자        | VARCHAR   | 업무 종료 일자         |
| 업무제목            | VARCHAR   | 간단한 제목            |
| 상세_업무내용        | VARCHAR   | 상세 내용              |
| 작업내용            | VARCHAR   | 작업한 상세 기록        |
| 작업시간            | INT       | 소요 시간 (분 단위)     |

---

###  Project_DB

| Column Name      | Type      | Description            |
|------------------|-----------|------------------------|
| ID               | INT       | 식별자 (PK)             |
| 상태              | VARCHAR   | 프로젝트 상태            |
| 연구비_계정         | VARCHAR   | 연구비 코드             |
| 업무_계정          | INT       | 업무 계정 코드           |
| 프로젝트명          | VARCHAR   | 프로젝트 명칭            |
| PM               | VARCHAR   | 프로젝트 매니저 이름      |
| 관련기종명          | VARCHAR   | 연관 제품/기기명         |
| 시작날짜            | DATE      | 프로젝트 시작일           |
| 종료날짜            | DATE      | 프로젝트 종료일           |
| 비고              | VARCHAR   | 추가 메모 사항            |
| 금액(견본)         | INT       | 견본 예산                |
| 금액(용역)         | INT       | 용역 예산                |
| 금액(시작품)       | INT       | 시작품 예산              |
| 금액(특허)         | INT       | 특허 관련 예산            |
| 금액(신뢰성)       | INT       | 신뢰성 시험 예산          |
| 금액(WPBC)         | INT       | WPBC 관련 예산           |

---

###  Task_DB

| Column Name      | Type      | Description         |
|------------------|-----------|---------------------|
| 작성자             | VARCHAR   | 요청 등록자           |
| ID               | INT       | 업무 식별자 (PK)       |
| 업무_계정          | VARCHAR   | 업무 관련 코드         |
| 프로젝트명          | VARCHAR   | 관련 프로젝트 명칭      |
| PM               | VARCHAR   | 책임자 이름            |
| 시작날짜            | DATE      | 업무 계획 시작일         |
| 종료날짜            | DATE      | 업무 계획 종료일         |
| 관련기종명          | VARCHAR   | 연관 기기명             |
| 업무제목            | VARCHAR   | 제목                   |
| 업무_시작일자        | DATE      | 실제 시작 일자           |
| 업무_종료일자        | DATE      | 실제 종료 일자           |
| 관련ECN            | VARCHAR   | 변경 통제 번호 (선택)     |
| 업무요청자           | VARCHAR   | 요청자 이름             |
| 상태              | VARCHAR   | 진행 상태               |
| 상세_업무내용        | VARCHAR   | 설명 및 상세 업무 내용     |
| 비고              | VARCHAR   | 비고 사항               |

---

##  Note

- 모든 테이블에는 민감한 데이터가 제거되어 있으며, 테스트 및 문서화 용도로만 사용됩니다.
- 구조는 변경될 수 있으며, 협업 시에는 버전 관리를 통해 관리됩니다.

---

