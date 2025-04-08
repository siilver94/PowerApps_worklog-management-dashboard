# worklog-management-dashboard

**worklog-management-dashboard(이하 업무현황판)**는 연구소 내 프로젝트 및 업무 일지를 효율적으로 관리하기 위한 Power Apps & SharePoint 기반의 애플리케이션입니다.
프로젝트 현황(Task)과 연구원들의 일일 업무일지(Daily Logs)를 연결하여, 보다 체계적으로 업무 시간을 기록하고 진행 상황을 추적할 수 있습니다.

## 개요 (Overview)

업무현황판는 아래의 요구 사항을 바탕으로 설계되었습니다.

연구원별 프로젝트 관리: 여러 프로젝트(Task)를 한 눈에 파악
일일 업무 기록(Daily Logs): 실제 작업내용, 소요 시간 등을 매일 간편하게 작성
사용자 정보(팀, 직급 등) 연동: UserInfoDB를 통해 사용자별 팀/직급 정보를 자동 매핑
Teams 환경에서 동작하며, SharePoint 리스트를 데이터 저장소로 활용
이를 통해 기존 문서나 엑셀 기반으로 관리되던 업무 기록을 전산화하여, 누구나 쉽고 빠르게 진행 현황을 파악하고 시간을 기록할 수 있습니다.

## 주요 기능 (Features)

1. 업무 현황(Task) 관리

- SharePoint의 Task_DB에 [업무_계정(대분류), 프로젝트명(소분류), 상태, 업무 시작/종료일, PM 등]을 저장 및 수정 
- “업무현황판”에서 각 Task를 간단히 등록/편집 가능

2. 일일 업무일지(Daily Logs)

- Daily_DB에 매일매일 작업 내용을 기록
- “오늘 날짜 범위”가 걸쳐 있는 Task들을 자동 필터 → 한 번에 여러 업무를 기록 & 저장
- 작업내용, 작업시간, 작성일자 등 입력 후 “저장” → 실제 Daily_DB에 Insert


3. 사용자 정보(UserInfo_DB) 연동

- 사용자 이메일 ↔ 이름/부서/직급 매핑
- 작성자/팀 정보를 자동으로 불러와 “일지를 쓰는” 과정에서 입력 편의 제공

  
4. 동적 필터링 & 편의 기능

- “오늘 해당하는 Task만 표시” / “Task 추가/해제” 기능
- 한 번에 여러 레코드 Patch → 반복적인 업무 시간을 최소화
  
5. Power Apps UI

- Canvas App 형태로 제작, Teams 환경과 자연스럽게 연동
- SharePoint 커넥터를 통해 필터, Patch, SubmitForm 등으로 데이터 CRUD 처리

  
## 구조 및 데이터베이스 (Architecture & SharePoint Lists)

현재 프로젝트에서 사용하는 SharePoint 리스트 구조는 아래와 같습니다:

1. Project_DB

- 프로젝트의 대분류(업무_구분), 소분류(프로젝트명), PM, 시작/종료일, 관련기종명 등
- 인덱스를 통해 빠른 필터링/검색을 지원 (업무_구분, 프로젝트명, 날짜 컬럼 등)
  
2. Task_DB

- 실제 업무 현황(Task)을 등록·수정·조회하는 핵심 테이블
- 주요 열: [업무_계정(대분류), 프로젝트명(소분류), 상태, 업무 시작/종료일, PM, 업무제목, 상세업무내용, 작성자 등]
  
3. Daily_DB

- 일일 업무일지를 기록 (연구원별로 작성)
- 주요 열: [작성자, 작성일자, 상태, 업무_계정, 프로젝트명, 업무제목, 상세업무내용, 작업내용, 작업시간 등]
  
4. UserInfo_DB

- 사용자(연구원) 정보를 보관, 매핑
- 주요 열: [이름, 이메일, 사번, 부문, 팀, 직급]
- Power Apps에서 LookUp하여 팀/직급 등 자동 입력
  
## 화면 구성 (Screens)

1) 업무현황 (Task_Screen)
   
- 대분류(업무_계정) & 소분류(프로젝트명) 선택
- 프로젝트(업무) 등록 / 수정 / 조회 기능
- 타임라인(시작전, 진행중, 완료) 보기 등
  
2) 업무 일지 (Daily_Screen)
   
- 왼쪽: 전체 Task 목록 (필터=“내 Task”)
- 오른쪽: “오늘 날짜 범위”에 자동 로드된 Task들 (Gallery)
  - 각 행에 작업내용, 작업시간 입력
  - “해제” 버튼으로 목록에서만 제거 (DB 영향 X)
- “저장” 버튼을 눌러 Daily_DB에 한 번에 Insert
- 향후 “캘린더 뷰”, “Task 수정 팝업” 등 기능 추가 예정

  
## 설치 및 설정 (Setup)

1. SharePoint 리스트 준비

- 위에서 언급한 Project_DB, Task_DB, Daily_DB, UserInfo_DB 생성
- 열(Column) 이름, 데이터 타입, 인덱스 설정
  
2. Power Apps Import

- Power Apps Studio에서 Canvas App 생성 → 해당 저장소의 App(.msapp) 파일 임포트 (추후 업로드 예정)
- SharePoint 커넥터 연결, 데이터소스(위 4개 리스트) 바인딩
  
3. 환경 변수/라이선스

- 현재 무료/기본 Teams + Power Apps 라이선스 범위에서 동작
- Office365Users 커넥터 사용 시, 사용자 프로필 조회 권한 필요
  
4. 실행

- Teams 탭/Power Apps 통해 “업무현황판 + 업무일지” 앱 실행
- 연구원들이 매일 Daily_Screen에서 작업내용/시간을 기록
  
## 향후 개발 계획 (Roadmap)

1. Task 수정 기능 통합
- Daily_Screen 내에서 곧바로 Task_DB(업무) 세부 수정 가능
  
2. 캘린더 연동
- Daily_DB의 작성일자 기준으로 달력에 표시 (작성일이 있는 날 “●” 아이콘 등)
  
3. 팀장/관리자 대시보드
- Power BI 또는 별도 Screen에서 팀별/프로젝트별 누적 시간 분석
  
4. 오래된 데이터 아카이브
- 2년 이상 지난 Daily_DB 항목 자동 백업/삭제
  
5. 권한 관리
- 연구원(작성자) / 팀장 / 관리자 권한별 화면 제어
  
## 기여 방법 (Contributing)

1. Fork & Pull Requests
- 레포지토리를 포크(Fork) 후 로컬에서 수정 → Pull Request로 기여
  
2. 이슈 등록
- 버그/개선사항 발견 시 Issue 탭에 등록
  
3. 브랜치 전략
- main은 안정 버전, dev는 개발용
- 기능 추가 시 feature 브랜치 분기하여 작업 후 Merge
