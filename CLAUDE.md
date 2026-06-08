# CLAUDE.md — 업무현황판 (Worklog Management Dashboard)

> Claude 전용 컨텍스트 문서. README.md와 별도로 관리.
> GitHub: https://github.com/siilver94/PowerApps_worklog-management-dashboard

---

## 프로젝트 개요

TYM 중앙기술연구소 내부 업무 관리 앱.
- **플랫폼**: Microsoft PowerApps Canvas App → Microsoft Teams 탭 배포
- **데이터**: SharePoint Lists (Dataverse/프리미엄 커넥터 사용 불가 — 무료 플랜)
- **사용자**: 약 103명, 매일 업무일지 작성 중 (실서비스 운영 중)
- **개발자**: 김은성 주임 (단독 개발·유지보수)

---

## 화면 구성 (5개 스크린)

| 파일 | 화면명 | 역할 |
|------|--------|------|
| `App.OnStart.powerfx` | 앱 전역 | 전역변수 초기화, 컬렉션 캐싱, 사용자 정보 로드 |
| `Daily_Screen.powerfx` | 업무일지 | 날짜별 업무일지 작성/수정/삭제, 달력, Task 추가 |
| `Task_Screen.powerfx` | 업무현황 | 칸반보드 (시작전/진행중/완료), Task 등록/수정, 프로젝트 관리 |
| `View_Screen.powerfx` | 업무조회 | 팀/직급별 주간 업무 매트릭스 조회, 피드백 작성 |
| `DashB_Screen.powerfx` | 대시보드 | 업무계정/프로젝트/작업분류 분포 차트, KPI, 기간 필터 |
| `cal_Screen.powerfx` | (미사용) | — |

---

## 데이터 구조 (SharePoint Lists)

### 계층 구조
```
Project_DB (프로젝트 마스터)
    └── Task_DB (개인 업무 등록 — Project_DB 참조)
            └── Daily_DB (매일 업무일지 — Task_DB 참조)
```

### Project_DB — 프로젝트 마스터 (68건)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 상태 | Text | 시작전 / 진행중 / 완료 |
| 연구비_계정 | Text | 개발비 등 |
| 업무_계정 | Text | 제품개발 / 기술개발 / 원가절감 / 설계변경 / TF / 교육 / 기타업무 / 연차(반차) |
| 프로젝트명 | Text | |
| PM | Text | |
| 관련기종명 | Text | |
| 시작날짜 | Date | |
| 종료날짜 | Date | |
| 비고 | Text | |
| 금액(견본) | Int | |
| 금액(용역) | Int | |
| 금액(시작품) | Int | |
| 금액(특허) | Int | |
| 금액(신뢰성) | Int | |
| 금액(WPBC) | Int | |

### Task_DB — 개인 업무 등록 (2,539건+)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 작성자 | Text | 이름_한글 |
| 업무_계정 | Text | Project_DB 참조 |
| 프로젝트명 | Text | Project_DB 참조 |
| PM | Text | Project_DB에서 자동 |
| 시작날짜 | Date | Project_DB에서 자동 |
| 종료날짜 | Date | Project_DB에서 자동 |
| 관련기종명 | Text | |
| 업무제목 | Text | |
| 업무_시작일자 | Date | 개인 업무 시작일 |
| 업무_종료일자 | Date | 개인 업무 종료일 |
| 관련ECN | Text | |
| 업무요청자 | Text | |
| 상태 | Text | 시작전 / 진행중 / 완료 |
| 상세_업무내용 | Text | |
| 비고 | Text | |
| 만든 날짜 | DateTime | 자동 |

> **업무_시작일자 기준 365일 필터**: Daily_Screen 좌측 Task 목록에서 365일 초과된 Task는 숨김 처리. 단, 이 필터의 실효성은 재검토 필요.

### Daily_DB — 일일 업무일지 (월 ~3,800건 누적, 연 ~45,000건+)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 작성일자 | Date | |
| 만든 날짜 | DateTime | 자동 |
| 작성자 | Text | 이름_한글 |
| 팀 | Text | UserInfo_DB에서 자동 |
| 상태 | Text | Task_DB 참조 |
| 업무_계정 | Text | Task_DB 참조 |
| 프로젝트명 | Text | Task_DB 참조 |
| 업무_시작일자 | Date | Task_DB 참조 |
| 업무_종료일자 | Date | Task_DB 참조 |
| 업무제목 | Text | Task_DB 참조 |
| 상세_업무내용 | Text | Task_DB 참조 |
| 작업내용 | Text | 당일 작업 내용 (사용자 직접 입력) |
| 작업시간 | Int | 당일 작업 시간 (사용자 직접 입력) |
| 피드백 | Text | 팀장/관리자 피드백 |
| 작업_분류 | Text | 업무_계정별 세부 분류 드롭다운 |

### UserInfo_DB — 사용자 정보 (103명)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| 이름_한글 | Text | 앱 전반 작성자 기준 키 |
| 이름_영문 | Text | |
| e-mail | Text | 소문자 변환 후 `User().Email`과 매칭 |
| 부문 | Text | Function 등 |
| 팀 | Text | 가상검증팀, 외장개발팀 등 |
| 직급 | Text | 실제 직급 |
| 직급2 | Text | **앱 권한 제어 핵심** — 팀원 / 팀장 / 부문장 / 소장 |
| 사번 | Int | PK |
| (나머지) | | 입사일자, 학력, 연락처 등 |

---

## 사용자 권한 구조 (로직 전용 — SharePoint 권한 없음)

```
소장 (1명)     → View_Screen: 모든 팀의 팀장 업무일지 조회
부문장 (2명)   → View_Screen: 담당 부문 팀장 업무일지 조회
팀장 (다수)    → View_Screen: 본인 팀 전체 주간 조회 / DashB_Screen: 팀원 선택 가능
팀원 (다수)    → 본인 데이터만 작성·조회
```

**제어 방식**: `varMyRole` 변수 (`직급2` 컬럼 값) 기준으로 화면 분기
**권한 판단 변수**: `varMyRole`, `varMyTeam`, `varMyDivision`

---

## 핵심 전역 변수

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `varMyName` | Text | 로그인 사용자 한글 이름 |
| `varMyEmail` | Text | 소문자 이메일 |
| `varMyTeam` | Text | 팀명 |
| `varMyDivision` | Text | 부문명 |
| `varMyRole` | Text | 팀원 / 팀장 / 부문장 / 소장 |
| `varSelectedDate` | Date | Daily_Screen 선택 날짜 |
| `varFirstDayOfMonth` | Date | 달력 현재 월 기준 |
| `vw_StartOfWeek` | Date | View_Screen 주간 시작일 (월요일) |
| `varEditMode` | Boolean | 편집 모드 여부 |
| `varFilterMode` | Text | "All" / "15Days" |
| `varProjectMode` | Text | "View" / "New" / "Edit" |
| `varMyRole` | Text | 권한 제어 핵심 |
| `varShowToast` / `varShowToast2` | Boolean | 토스트 알림 |

---

## 핵심 컬렉션

| 컬렉션명 | 출처 | 설명 |
|----------|------|------|
| `colDailyTasks` | Daily_DB | Daily_Screen 우측 편집 중인 업무 목록 |
| `colDaily_365_Team` | Daily_DB | 최근 365일 내 팀 데이터 캐시 |
| `colDaily_365_All` | Daily_DB | 최근 365일 전체 데이터 캐시 |
| `colTeamWeekDaily` | Daily_DB | View_Screen 주간 데이터 |
| `colTeamMatrix` | 가공 | View_Screen 매트릭스용 GroupBy 결과 |
| `colTeamPeriodData` | Daily_DB | DashB_Screen 기간 데이터 |
| `colProjectList` | Daily_DB + Project_DB | 프로젝트 목록 |
| `colSelectedProjects` | UI | Task_Screen/View_Screen 다중 선택 |
| `colWorkTagsMap` | 하드코딩 | 업무_계정별 작업_분류 드롭다운 매핑 |
| `colUsers` | UserInfo_DB | UserInfo 캐시 |
| `colAccAgg` | 가공 | DashB 업무계정 집계 |
| `colProjChart` | 가공 | DashB 프로젝트 차트 |
| `colKoreaHolidays` | 하드코딩 | 2025~2030 공휴일 목록 |

---

## 알려진 버그 목록

| 번호 | 화면 | 버그 | 원인 |
|------|------|------|------|
| B-01 | View_Screen | 이전주/다음주 화살표 이동 안됨 | `icPrev`/`icnNext`가 `colWeek`만 갱신, `colTeamMatrix` 재계산 없음 |
| B-02 | View_Screen | 소장/부문장 화면에서 팀장 데이터 안보임 | `varMyRole` 세팅 타이밍 문제 + `colDaily_365_Team`이 내 팀 데이터만 포함 |
| B-03 | Task_Screen | 프로젝트별 선택 필터 안됨 | `colSelectedProjects` 컬렉션 타입 불일치 가능성 |
| B-04 | Task_Screen | 프로젝트 관리 신규 저장 오류 | `업무_계정_DataCard3`의 `Update` 속성 누락 (`cmbAccount` 미연결) |
| B-05 | Task_Screen | 프로젝트 관리 상태 수정 안됨 | `상태_DataCard3`가 `TextInput` 자유입력 — 드롭다운 필요 |

---

## 개발 예정 목록

| 번호 | 분류 | 내용 |
|------|------|------|
| F-01 | 개발 | 연장근로 시스템 (사전/사후 신청 화면) |
| F-02 | 개발 | 26년 사업 계획 프로젝트 — 종료된 것 완료 처리, 진행중만 표시 |
| F-03 | 개발 | 그래프 색 구분 |
| F-04 | 개발 | 팀별 작성률 표시 |
| F-05 | 개발 | 프로젝트 관리 화면 상태별 필터링 (완료 숨김) |
| F-06 | 개발 | 연차(반차) 색 처리 — Daily_Screen에서 빨간색 표시 |
| F-07 | 개발 | 출장 시스템 |
| F-08 | 개발 | 연차 시스템 |
| F-09 | 개발 | 공지 시스템 |
| F-10 | 개발 | 기타분류 화면 (팀장별 기타 항목 조회) |
| P-01 | 성능 | App.OnStart 최적화 — Daily_DB 대용량 로딩 개선 필요 (월 3,800건 누적) |

---

## 개발 원칙 & 주의사항

### 라이센스 제약 (항상 준수)
- **무료 플랜** → Dataverse, 프리미엄 커넥터 사용 불가
- 데이터 소스: SharePoint List 또는 Excel/OneDrive만
- Power Automate: 표준 커넥터·기본 흐름만 (HTTP 요청 등 프리미엄 불가)

### Power Fx 코딩 규칙
- 수식 앞 `=` 접두사 없이 작성 (복사해서 바로 붙여넣기 가능하도록)
- 항상 **컨트롤명 + 속성 + 화면명** 명시
- 수식 아래 `// → 이 수식이 하는 일: ...` 한 줄 요약 필수
- 주석 상세히 작성

### 성능 주의사항
- Daily_DB는 월 ~3,800건 누적 → **Delegation 필수**
- `Filter`, `LookUp`에서 위임 가능 함수 우선 사용
- `ForAll` 안에서 `LookUp(UserInfo_DB, ...)` 반복 호출은 성능 최악 → `colUsers` 캐시 활용
- `App.OnStart`에서 Daily_DB 전체 캐싱은 장기적으로 부하 — 점진적 개선 예정

### 사용자 이름 처리
- 앱 내 사용자 이름: 각 화면마다 별도 컨트롤로 복붙된 구조
  - `Daily_Screen`: `name_label.Text`
  - `Task_Screen`: `name_label_1.Text`
  - `View_Screen`: `name_label_2.Text`
  - `DashB_Screen`: `name_label_8.Text`
- 코드 곳곳에서 `varMyName` 대신 `name_label.Text` 직접 참조 중 → 향후 `varMyName`으로 통일 예정 (지금 당장 리팩토링 금지, 기존 로직 유지)
- UserInfo_DB 매칭: `이름_한글` 컬럼 기준
- 이메일 매칭: `Lower(User().Email)` = `e-mail` 컬럼 (소문자 변환 필수)

### OData 컬럼명 인코딩
- SharePoint 한글 컬럼명은 내부적으로 URL 인코딩된 이름으로 저장됨
- PowerApps 자동완성에서 인코딩된 이름만 뜨면 그걸 그대로 써야 함 (정상 동작)
- 주요 매핑:

| 표시 컬럼명 | 내부 OData 이름 | 리스트 |
|------------|----------------|--------|
| 업무_시작일자 | `OData__xc5c5__xbb34___xc2dc__xc791__xc` | Task_DB |
| 업무_종료일자 | `OData__xc5c5__xbb34___xc885__xb8cc__xc` | Task_DB |
| 프로젝트명 | `OData__xd504__xb85c__xc81d__xd2b8__xba` | Task_DB / Project_DB |
| 업무_계정 | `OData__xad6c__xbd84_` | Task_DB |
| 작성자 | `OData__xc791__xc131__xc790_` | Task_DB |
| 작성일자 | `OData__xc791__xc131__xc77c__xc790_` | Daily_DB |

### 실서비스 주의
- **103명이 매일 사용 중** — 데이터 마이그레이션 없이 기존 데이터 보존 필수
- 컬럼명/타입 변경 시 기존 레코드 영향 반드시 검토
- SharePoint 내부 컬럼명(OData 인코딩)과 표시명 혼용 주의
  - 예: `업무_시작일자` 내부명 → `OData__xc5c5__xbb34___xc2dc__xc791__xc`

---

## 세션 시작 방법

새 대화 시작 시:
1. 이 `CLAUDE.md` 첨부
2. 수정할 화면의 `.powerfx` 파일 첨부
3. 작업 내용 설명

```
예시: "CLAUDE.md + View_Screen.powerfx 첨부 — B-01 주 이동 버그 수정해줘"
```
