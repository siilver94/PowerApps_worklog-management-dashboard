# CLAUDE.md — 업무현황판 (Worklog Management Dashboard)

> Claude 전용 핸드오프 문서. 새 세션 시작 시 이 파일 + 작업할 화면의 `.powerfx`를 첨부할 것.
> GitHub: https://github.com/siilver94/PowerApps_worklog-management-dashboard

---

## 0. 이 문서를 읽는 Claude에게 (필독)

이 앱은 **103명이 매일 쓰는 실서비스**다. 그리고 **개발자(김은성 주임)는 Power Fx 코드 자체에는 약하고, 요구사항 중심으로 대화**한다. 다음을 반드시 지킬 것:

1. **Delegation·성능을 항상 먼저 고려한다.** Daily_DB는 연 45,000건 이상 쌓이고, PowerApps 위임 한도는 기본 2,000건이다. 어떤 코드를 주든 위임 가능 여부를 먼저 판단하고, 위임 불가 시 경고 + 대안을 함께 제시한다.
2. **요구사항을 정확히 파악한 뒤 코드를 준다.** 바로 코드부터 던지지 말고, 동작·기능을 먼저 정리하고 합의한 뒤 구현한다. 더 나은 구조가 있으면 먼저 제안하고 선택하게 한다.
3. **코드는 `=` 접두사 없이**, 실제 동작하는 완성본으로 준다. 적용 위치(컨트롤 + 속성 + 화면)를 항상 명시한다.
4. **한 번에 한 곳씩 고친다.** 전체를 갈아엎으면 다른 화면 참조가 깨진다.
5. **컬럼명은 문자열로 감싸지 않는다.** `Filter(테이블, 작성자 in ...)` 처럼 컬럼을 직접 참조한다. `"작성자"` 처럼 쌍따옴표로 감싸면 문자열 비교가 되어 필터가 깨진다.
6. **속성값은 한 줄씩 명확히 준다.** `X=465/Y=124` 같은 함축 표기 금지. 컨트롤 타입·이름·X·Y·Width·Height를 각각 별도 줄로. UI 작업은 STEP별로 적용 → 스크린샷 확인 → 다음 단계로 진행한다.
7. **내가 준 주석/안내 줄을 그대로 붙여넣는 경우가 있다.** 코드를 줄 때 "이 줄은 지워라" 같은 안내가 실제 코드에 섞이지 않도록, 붙여넣을 최종 코드만 깔끔하게 준다. (다음주 이동 버튼에서 `+7` 후 `-7` 주석이 같이 들어가 제자리로 돌아간 사고 있었음)

---

## 1. 프로젝트 개요

TYM 중앙기술연구소 내부 업무 관리 앱.

| 항목 | 내용 |
|------|------|
| 플랫폼 | Microsoft PowerApps Canvas App → Microsoft Teams 탭 배포 |
| 데이터 | SharePoint Lists (Dataverse·프리미엄 커넥터 불가 — 무료 플랜) |
| 사용자 | 약 103명, 매일 업무일지 작성 (실서비스 운영 중) |
| 개발자 | 김은성 주임 (단독 개발·유지보수) |
| 자동화 | Power Automate 표준 커넥터·기본 흐름만 (HTTP·프리미엄 불가) |

---

## 2. 화면 구성 (5개 스크린 + 1 미사용)

| 파일 | 화면명 | 역할 |
|------|--------|------|
| `App.OnStart.powerfx` | 앱 전역 | 전역변수 초기화, 컬렉션 캐싱, 사용자 정보·권한 로드 |
| `Daily_Screen.powerfx` | 업무일지 | 날짜별 업무일지 작성/수정/삭제, 달력, Task 추가, 작업_분류 선택 |
| `Task_Screen.powerfx` | 업무현황 | 칸반보드(시작전/진행중/완료), Task 등록/수정, 프로젝트 관리 모달 |
| `View_Screen.powerfx` | 업무조회 | 팀별/프로젝트별 주간 매트릭스 조회, 피드백 작성 |
| `DashB_Screen.powerfx` | 대시보드 | 업무계정/프로젝트/작업분류 분포 차트, KPI, 기간 필터 |
| `cal_Screen.powerfx` | (미사용) | — |

---

## 3. 데이터 구조 (SharePoint Lists)

### 계층 구조
```
Project_DB (프로젝트 마스터)
    └── Task_DB (개인 업무 등록 — Project_DB 참조)
            └── Daily_DB (매일 업무일지 — Task_DB 참조)
```
- **Project_DB**: 회사가 관리하는 프로젝트 마스터. 사용자가 여기서 진행할 프로젝트를 고른다.
- **Task_DB**: 사용자가 Project_DB의 프로젝트를 골라 "내 업무"로 등록.
- **Daily_DB**: 사용자가 매일 Task_DB의 업무를 골라 그날 작업내용·시간을 기록.

### Project_DB — 프로젝트 마스터 (약 68~80건, 소규모)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 상태 | Text | 시작전 / 진행중 / 완료 |
| 연구비_계정 | Text | 개발비 등 |
| 업무_계정 | Text | 제품개발/기술개발/원가절감/설계변경/TF/교육/기타업무/연차(반차)/출장/**연구관리** |
| 프로젝트명 | Text | |
| PM | Text | |
| 관련기종명 | Text | |
| 시작날짜 / 종료날짜 | Date | |
| 비고 | Text | |
| 만든 날짜(Created) | DateTime | 시스템 자동 |
| 금액(견본/용역/시작품/특허/신뢰성/WPBC) | Int | |

> **소규모라 delegation 한도에 안 걸린다.** 프로젝트 전체 목록이 필요하면 Project_DB를 직접 쓰는 게 안전.

> ⚠️ **OData 내부 컬럼명 주의.** Project_DB의 한글 컬럼은 내부적으로 인코딩된다. 프로젝트명 = `OData__xd504__xb85c__xc81d__xd2b8__xba`, 시작날짜 = `OData__xc2dc__xc791__xb0a0__xc9dc_`, 종료날짜 = `OData__xc885__xb8cc__xb0a0__xc9dc_`, 상태 = `OData__xc0c1__xd0dc_`, 업무_계정 = `OData__xad6c__xbd84___xc5c5__xbb34_`, 비고 = `OData__xbe44__xace0_`. `SortByColumns` 등 컬럼명을 문자열로 받는 함수에서만 이 인코딩명을 쓰고, `Filter`·`Patch`의 레코드 표기에서는 한글 컬럼명을 그대로 쓴다.

### Task_DB — 개인 업무 등록 (2,500건+)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 작성자 | Text | 이름_한글 |
| 업무_계정 / 프로젝트명 / PM / 시작날짜 / 종료날짜 / 관련기종명 | — | Project_DB에서 가져옴 |
| 업무제목 | Text | |
| 업무_시작일자 / 업무_종료일자 | Date | 개인 업무 기간 |
| 관련ECN / 업무요청자 / 비고 | Text | |
| 상태 | Text | 시작전 / 진행중 / 완료 |
| 상세_업무내용 | Text | |

> ⚠️ **`Distinct`·`in` 연산자는 위임 불가.** Task_DB(2,500건+)에서 `Distinct(...)`나 `작성자 in colXxx.이름_한글` 으로 필터하면 앞 500~2,000건만 로컬 처리되어 **최근 등록 데이터가 누락**된다. (이번 세션에서 프로젝트 목록 일부 누락으로 겪음) → 단일 작성자 비교(`작성자 = varMyName`)는 위임 가능하므로 우선 사용.

### Daily_DB — 일일 업무일지 (월 ~3,800건, 연 ~45,000건+) ⚠️ 대용량
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 작성일자 | Date | |
| 작성자 | Text | 이름_한글 |
| 팀 | Text | UserInfo_DB에서 자동 |
| 상태 / 업무_계정 / 프로젝트명 / 업무_시작일자 / 업무_종료일자 / 업무제목 / 상세_업무내용 | — | Task_DB 참조 |
| 작업내용 | Text | 당일 작업 내용 (사용자 직접 입력) |
| 작업시간 | Int | 당일 작업 시간 (사용자 직접 입력) |
| 피드백 | Text | 팀장/관리자 피드백 |
| 작업_분류 | Text | 업무_계정별 세부 분류 (드롭다운) |

> **이 테이블이 성능의 핵심.** 전체를 Filter로 당기면 2,000건에서 잘린다. **날짜 범위 필터는 위임 가능**하므로, 주간 등 좁은 범위는 Daily_DB 직접 호출이 오히려 정확하다.

### UserInfo_DB — 사용자 정보 (103명)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| 이름_한글 | Text | **앱 전반의 작성자 기준 키** |
| 이름_영문 | Text | |
| e-mail | Text | 소문자 변환 후 `User().Email`과 매칭 |
| 부문 | Text | **Function / Project** 2개 |
| 팀 | Text | 가상검증팀, 외장개발팀 등 |
| 직급 | Text | 실제 직급(주임 등) |
| 직급2 | Text | **앱 권한 제어 핵심** — 팀원 / 팀장 / 부문장 / 소장 |
| 사번 | Int | PK |

---

## 4. 사용자 권한 구조 (SharePoint 권한 없음 — 100% 앱 로직)

| 직급2 | 인원 | 부문 컬럼값 | View_Screen 팀별 모드에서 보이는 범위 |
|-------|------|------------|------------------------------|
| 소장 | 1명 | 연구소장 | **전체 팀**의 팀장이 작성한 업무일지 |
| 부문장 | 2명 | Function / Project (각 1명) | **담당 부문**의 팀장이 작성한 업무일지 |
| 팀장 | 다수 | Function / Project | **본인 팀** 전원 |
| 팀원 | 다수 | Function / Project | **본인 팀** 전원 (팀장과 동일) |

- 부문은 **Function**과 **Project** 2개, 각 부문에 부문장 1명씩.
- 권한 판단 변수: `varMyRole`(직급2), `varMyTeam`(팀), `varMyDivision`(부문).
- ⚠️ **팀원도 팀 전체를 본다.** (이번 세션에서 "본인만"→"팀 전체"로 변경. `colTargetAuthors`의 default 분기를 `Filter(colUsers, 팀 = varMyTeam)`로 수정)

---

## 5. 핵심 전역 변수

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `varMyEmail` | Text | 소문자 이메일 (`Lower(User().Email)`) — **가장 먼저 세팅, 모든 사용자 매칭의 기준** |
| `varMyName` | Text | 로그인 사용자 한글 이름 (이메일로 LookUp) — **작성자 기준 키. name_label 대신 이걸 쓴다** |
| `varMyTeam` | Text | 팀명 |
| `varMyDivision` | Text | 부문명 (Function / Project) |
| `varMyRole` | Text | 팀원 / 팀장 / 부문장 / 소장 — **권한 제어 핵심** |
| `varViewMode` | Text | View_Screen 모드: "팀별" / "프로젝트별" |
| `vw_StartOfWeek` | Date | View_Screen 주간 시작일(월요일) |
| `varSelectedDate` | Date | Daily_Screen 선택 날짜 |
| `varFirstDayOfMonth` | Date | 달력 현재 월 기준 |
| `varEditMode` | Boolean | 편집 모드 여부 |
| `varFilterMode` | Text | "All" / "15Days" |
| `varProjectMode` | Text | "View" / "New" / "Edit" — 프로젝트 관리 모달 모드 |
| `varAutoHour` / `locAutoHour` | Number | 연차/반차 작업시간 자동 입력값 (전역/로컬 동기화) |
| `varShowProjectModal` | Boolean | 프로젝트 관리 모달 표시 |
| `varShowDeleteConfirm` | Boolean | 프로젝트 삭제 확인 |
| `varShowToast` / `varShowToast2` | Boolean | 토스트 알림 |

> ⚠️ **`varMyRole` 세팅은 반드시 이메일 기준 LookUp으로.** `User().FullName` 파싱이나 `name_label.Text`에 의존하면 안 됨. App.OnStart에서 `varMyEmail` 세팅 직후에 `varMyRole`, `varMyTeam`, `varMyDivision`을 확정할 것.

---

## 6. 핵심 컬렉션

| 컬렉션명 | 출처 | 설명 |
|----------|------|------|
| `colUsers` | UserInfo_DB | 사용자 캐시. **역할별 필터링·LookUp 반복 비용 제거용.** App.OnStart에서 일찍 생성해야 이후 로직이 동작 |
| `colDailyTasks` | Daily_DB | Daily_Screen 우측 편집 중인 업무 목록 |
| `colDaily_365_Team` | Daily_DB | 최근 365일 내 팀 데이터 캐시 (2,000건 한도 주의) |
| `colDaily_365_All` | Daily_DB | 최근 365일 전체 데이터 캐시 (2,000건 한도 — **주간 조회에는 쓰지 말 것**) |
| `colTargetAuthors` | colUsers | **역할별 조회 대상 작성자 목록** (소장→전체 팀장, 부문장→부문 팀장, 팀장/팀원→팀 전원) |
| `colProjectList` | Task_DB | **팀별 모드** 프로젝트 목록 (colTargetAuthors가 Task_DB에 등록한 프로젝트). ⚠️ `colTargetAuthors` 생성 **이후**에 빌드해야 함 |
| `colAllProjects` | Project_DB | **프로젝트별 모드** 프로젝트 목록 (Project_DB 전체) |
| `colSelProjects` | UI | View_Screen에서 선택된 프로젝트. `colProjectList`/`colAllProjects`와 **동일 구조(Value 컬럼)** 유지 필수 |
| `colSelectedProjects` | (폐기) | Task_Screen 구버전 선택 추적. **colDeselectedProjects로 대체됨** |
| `colDeselectedProjects` | UI | **Task_Screen 프로젝트 필터 — 해제된 것만 추적.** 기본 전체 선택 상태에서, 체크 해제한 프로젝트만 담는다 (Distinct/in 위임 한계 우회) |
| `colTeamWeekDaily` | Daily_DB | View_Screen 주간 데이터 — **Daily_DB 직접 호출(날짜 필터 위임)** |
| `colTeamMatrix` | 가공 | View_Screen 매트릭스용 GroupBy 결과 |
| `colWorkTagsMap` | 하드코딩 | 업무_계정별 작업_분류 드롭다운 매핑 |
| `colTeamPeriodData` | Daily_DB | DashB_Screen 기간 데이터 |
| `colAccAgg` / `colProjChart` / `colWorkTagAgg` | 가공 | DashB 집계 |
| `colKoreaHolidays` | 하드코딩 | 2025~2030 공휴일 (Daily_Screen 달력 색 처리) |

### App.OnStart 컬렉션 빌드 순서 (중요)
```
varMyEmail → varMyTeam / varMyName
  → colUsers (UserInfo_DB 캐시)
  → colTargetAuthors (colUsers 기반 역할별)
  → colProjectList (Task_DB, colTargetAuthors 참조)   ← 반드시 colTargetAuthors 이후!
  → colAllProjects (Project_DB 전체)
  → varMyRole / varMyDivision (이메일 LookUp)
```
> ⚠️ 과거 App.OnStart 맨 아래에 `colProjectList`를 Project_DB 기반으로 **재생성**하는 줄이 남아 `colAllProjects`와 동일해지는 버그가 있었음. colProjectList는 **한 곳에서만**, colTargetAuthors 생성 직후에 빌드한다.

---

## 7. 작업_분류 매핑 (`colWorkTagsMap`) — 중요 패턴

업무_계정별로 작업_분류 드롭다운 항목이 다르다. App.OnStart의 `colWorkTagsMap` 테이블에 `{Account, Tag, Order}` 형태로 하드코딩.

### 연구관리 계정의 프로젝트별 분기
`업무_계정 = "연구관리"`인 경우, **프로젝트명까지 조합**해서 작업_분류를 다르게 한다.
- 매핑 키 형식: `"연구관리_" & 프로젝트명` (예: `"연구관리_회계"`, `"연구관리_S/W"`)
- 이 조합 키는 **앱 내부 메모리(colWorkTagsMap)에서만** 쓰는 매핑 키. DB에는 `작업_분류` 태그값(행정/회의 등)만 저장된다.

연구관리 프로젝트 작업_분류:
| 프로젝트 | 작업_분류 항목 |
|----------|----------------|
| 회계 / 관리 / 검정·인증 | 행정, 지원업무, 회의, 문서/보고, 기타 |
| S/W | 기획/설계, 개발/코딩, 문서/보고, 회의, 기타 |
| 데이터분석 | 데이터처리, 분석/모델링, 문서/보고, 회의, 기타 |
| 엔진시험관리 | 인력관리, 시설/장비관리, 안전관리, 기타 |

### ddWorkTag 매핑 로직 (Daily_Screen)
`ddWorkTag.Items` / `DefaultSelectedItems`에서 Account 키를 이렇게 만든다:
```
If(
    ThisItem.c업무_계정 = "연구관리",
    "연구관리_" & ThisItem.c프로젝트명,
    ThisItem.c업무_계정
)
```

### 작업_분류 강제 선택
- "미분류"로 저장되는 것을 막기 위해, `colDailyTasks`의 **모든 업무가 작업_분류를 선택해야** 저장 버튼(`Send_btn`) 활성화.
- `ddWorkTag.OnChange`에서 선택 즉시 `colDailyTasks`에 반영.

### ⚠️ 작업분류 선택 시 입력값 초기화 버그 (해결됨)
- 증상: 작업시간·작업내용 입력 후 작업_분류를 선택하면 입력값이 사라짐.
- 원인: `ddWorkTag.OnChange`의 `Patch(colDailyTasks, ...)`가 갤러리 재렌더링을 유발 → TextInput이 Default로 리셋.
- 해결: **OnChange의 Patch에 작업시간·작업내용도 함께 저장**(`작업시간: Value(txtWorkHour.Value)`, `작업내용: txtWorkContent.Value`)해서 재렌더링 전에 값을 확정.

### 연차/반차 작업시간 자동 입력 (구현됨)
- `업무_계정 = "연차(반차)"` + 작업_분류가 "연차"면 8, "오전반차"/"오후반차"면 4를 작업시간에 자동 입력.
- `ddWorkTag.OnChange`에서 **자동값 계산 → UpdateContext(locAutoHour) → Patch(작업시간에 자동값 우선) → Reset(txtWorkHour)** 순서가 핵심. 순서가 어긋나면 옛날 값이 다시 표시됨.
- `txtWorkHour.Value` = `If(!IsBlank(locAutoHour), locAutoHour, ThisItem.작업시간)`

---

## 8. View_Screen 동작 사양

### 팀별 / 프로젝트별 모드
| 모드 | 프로젝트 목록 소스 | 매트릭스에 보이는 사람 |
|------|--------------------|------------------------|
| 팀별 | `colProjectList` (역할별 작성자가 Task_DB에 등록한 프로젝트) | `varMyRole` 권한 범위 (소장→전체 팀장, 부문장→부문 팀장, 팀장/팀원→본인 팀) |
| 프로젝트별 | `colAllProjects` (Project_DB 전체) | **권한 제한 없이 전 인원** (선택 프로젝트 기준) |

### 주간 데이터 로딩 원칙 (중요)
- `colTeamWeekDaily`는 **`Daily_DB` 직접 호출**로 그 주(월~금)만 가져온다.
- 이유: 날짜 범위 필터는 위임 가능 → 주간은 건수가 적어 2,000건 한도에 안 걸림 → 그 주 전 인원 데이터를 정확히 확보.
- ❌ `colDaily_365_All`(2,000건 캐시)에서 주간을 뽑으면 최신순으로 잘려서 특정 팀만 나오는 편향 발생.

### 주 이동 버튼 (icPrev / icnNext / ButtonCanvas4_1) — 해결됨
- 각 버튼은 `vw_StartOfWeek` 변경 + `colWeek` 재로드 **뿐 아니라** `colTeamWeekDaily` 재로드 + `colTeamMatrix` 재계산까지 해야 매트릭스가 갱신된다.
- ⚠️ 코드 붙여넣을 때 `+7`/`-7` 주석 줄이 섞여 들어가지 않도록 주의 (다음주 버튼이 제자리로 돌아가는 사고 있었음).

### 매트릭스 재계산 로직 중복 문제 (미해결 — 다음 작업)
동일한 `colTeamMatrix` 재계산 코드가 **여러 곳에 복붙**되어 있음:
- `View_Screen.OnVisible`
- `tgl_ViewMode.OnChange`
- `chkProj.OnCheck` / `chkProj.OnUncheck`
- `chkAll.OnCheck` / `chkAll.OnUncheck`
- 주 이동 버튼 3개 (icPrev / icnNext / ButtonCanvas4_1)

→ **다음 단계: 숨김 버튼 `btnRecalcMatrix` 하나에 로직을 모으고 각 컨트롤은 `Select(btnRecalcMatrix)` 한 줄만 호출.**

---

## 9. Task_Screen 프로젝트 필터 — colDeselectedProjects 방식 (해결됨)

좌측 `GalleryProjects`에서 프로젝트를 체크/해제해 칸반 갤러리를 필터링한다.

### 왜 역방향(해제 추적)인가
- 기존: `colSelectedProjects`(선택된 것 목록)를 Task_DB `Distinct`로 만듦 → **Distinct 위임 한계로 최근 프로젝트 누락** → 체크가 일부 안 됨.
- 변경: **기본 전체 선택 상태**로 두고, 해제한 프로젝트만 `colDeselectedProjects`에 담는다. 비교 대상이 작아 위임 문제 없음.

### 구현
| 위치 | 코드 |
|------|------|
| `Task_Screen.OnVisible` | `Clear(colDeselectedProjects)` (전체 선택 상태로 시작) |
| 프로젝트 체크박스 `Checked` | `IsBlank(LookUp(colDeselectedProjects, Value = ThisItem.Value))` |
| 체크박스 `OnUncheck` | `Collect(colDeselectedProjects, {Value: ThisItem.Value})` |
| 체크박스 `OnCheck` | `RemoveIf(colDeselectedProjects, Value = ThisItem.Value)` |
| 칸반 갤러리(시작전/진행중/완료) `Items`의 projRows | `If(IsEmpty(colDeselectedProjects), baseRows, Filter(baseRows, !(프로젝트명 in colDeselectedProjects.Value)))` |
| `chkSelectAll.OnCheck` | `Clear(colDeselectedProjects)` |
| `chkSelectAll.OnUncheck` | `ClearCollect(colDeselectedProjects, GalleryProjects.AllItems)` |
| `chkSelectAll.Checked` | `IsEmpty(colDeselectedProjects)` |

---

## 10. 프로젝트 관리 모달 (conProjectModal) — 2패널 재설계 (이번 세션 핵심)

업무현황 화면의 `btnProjectManage`로 여는 프로젝트 마스터(Project_DB) 관리 모달. **Form 컨트롤을 제거하고 Patch 방식으로 전면 재설계**했다.

### 레이아웃 (1280 × 720)
```
conProjectModal (1280 × 720, X=80, Y=40)
├── recLeftBg (좌측 배경, W=380)
├── ddAccount (업무_계정 필터) + ddStatus (상태 필터: 전체/시작전/진행중/완료)
├── galProjectList (좌측 목록, 상태 뱃지 표시)
├── recPanelDivider (좌/우 구분선, X=380)
└── conProjDetail (우측 상세, X=381, W=899)   ← 구 Container16
    ├── recHeader / recHeaderDivider (헤더 H=72)
    ├── lblProjName (View) / txtProjName (Edit·New) — 프로젝트명, 같은 위치 Visible 토글
    ├── recStatusBadge / lblStatusBadge (상태 뱃지)
    ├── [바디 좌] 기본 정보: 업무_계정 / PM / 관련기종명 / 시작날짜 / 종료날짜 / 상태
    │     각 필드 = lblKey_* (필드명 고정) + lblVal_* (View) + 입력컨트롤 (Edit·New)
    ├── recBodyDivider (좌/우 바디 구분선, X=449)
    └── [바디 우] 프로젝트 현황: D-day / 진행률 바 / 등록일
```

### 모드 토글 패턴
- `varProjectMode` = "View" / "Edit" / "New"
- 같은 위치에 **View용 라벨**과 **Edit용 입력**을 겹쳐두고 `Visible` 조건으로 교체:
  - View 라벨: `Visible = varProjectMode = "View"`
  - Edit 입력: `Visible = varProjectMode = "Edit" || varProjectMode = "New"`
  - Key 라벨(필드명): 항상 표시 (Visible 조건 없음)

### 우측 현황 계산식
- **D-day**: 상태가 완료면 "완료 ✓", 아니면 `DateDiff(Today(), 종료날짜)`로 D-n/D-Day/D+n. 색은 초과=빨강, 14일 이내=주황, 그 외=검정.
- **진행률**: `elapsed / total * 100` (시작~오늘 / 시작~종료). 바 Width = `380 * pct / 100`. 색은 100%+=빨강, 70%+=주황, 그 외=파랑.
- **등록일**: `Text(galProjectList.Selected.'만든 날짜', "yyyy.mm.dd")`

### 갤러리 상태 뱃지 색
```
시작전 = RGBA(158, 158, 158, 1)  (회색)
진행중 = RGBA(30, 136, 229, 1)   (파랑)
완료   = RGBA(56, 142, 60, 1)    (초록)
```

### galProjectList.Items (업무_계정 + 상태 필터)
```
SortByColumns(
    Filter(
        Project_DB,
        (IsBlank(ddAccount.Selected.Value) || 업무_계정 = ddAccount.Selected.Value) &&
        (ddStatus.Selected.Value = "전체" || 상태 = ddStatus.Selected.Value)
    ),
    "OData__xd504__xb85c__xc81d__xd2b8__xba",
    SortOrder.Ascending
)
```

### 저장 (btnSaveProject.OnSelect) — Patch 방식
- 검증: 프로젝트명·업무_계정 필수.
- New → `Patch(Project_DB, Defaults(Project_DB), {...})`, Edit → `Patch(Project_DB, galProjectList.Selected, {...})`.
- 저장 필드: 프로젝트명/PM/관련기종명/시작날짜/종료날짜/상태(cmbProjStatus)/업무_계정(cmbProjAccount).
- 이후 `Refresh(Project_DB)` + `varProjectMode="View"` + 토스트.
- 삭제는 `conDeleteConfirm` 확인 후 `Remove(Project_DB, galProjectList.Selected)`.

### 주요 컨트롤 이름 규칙
- 필드: `lblKey_<필드>` / `lblVal_<필드>` / 입력은 `txtProj*` `cmbProj*` `dpProj*`
- 현황: `lblKey_Dday` `lblVal_Dday` `recProgressBg` `recProgressFill` `lblVal_Progress` `lblVal_RegDate`

---

## 11. 알려진 버그 목록

| 번호 | 화면 | 버그 | 상태 |
|------|------|------|------|
| B-01 | View_Screen | 주 이동 시 매트릭스 갱신 안됨 | ✅ 해결 — 주 이동 버튼 3개에 `colTeamWeekDaily` 재로드 + `colTeamMatrix` 재계산 추가 |
| B-02 | View_Screen | 소장/부문장 화면에서 팀장 데이터 안보임 | ✅ 해결 |
| B-03 | Task/View | 프로젝트별 선택 필터 안됨 / colProjectList·colAllProjects 동일 | ✅ 해결 — 소스 분리(colProjectList=Task_DB, colAllProjects=Project_DB) + colProjectList 중복 생성 제거 |
| B-04 | Task_Screen | 프로젝트 관리 신규 저장 오류 | ✅ 해결 — Form 제거, Patch 방식 재설계 |
| B-05 | Task_Screen | 프로젝트 관리 상태 수정 안됨 | ✅ 해결 — 상태 드롭다운(cmbProjStatus) + Patch |
| B-06 | 전체 | 특정 직원 이름 파싱 깨짐 (`User().FullName` = "임서현 / 연구관리팀 / 주임") | ✅ 해결 — `name_label.Text`를 `varMyName`으로 전환 |
| B-07 | Task_Screen | 프로젝트 체크박스 일부 미선택(최근 프로젝트 누락) | ✅ 해결 — colDeselectedProjects 역방향 추적 방식 |
| B-08 | Daily_Screen | 작업분류 선택 시 작업시간·작업내용 초기화 | ✅ 해결 — OnChange Patch에 입력값 동시 저장 |

---

## 12. 개발 예정 목록

| 번호 | 분류 | 내용 |
|------|------|------|
| F-01 | 개발 | 연장근로 시스템 (사전/사후 신청 화면) |
| F-02 | 개발 | 26년 사업 계획 프로젝트 — 종료분 완료 처리, 진행중만 표시 |
| F-03 | 개발 | 그래프 색 구분 |
| F-04 | 개발 | 팀별 작성률 표시 |
| F-05 | 개발 | 프로젝트 관리 화면 상태별 필터링 | ✅ ddStatus로 구현 완료 |
| F-06 | 개발 | 연차(반차) 색 처리 — Daily_Screen 빨간색 표시 |
| F-07 | 개발 | 출장 시스템 (작업_분류에 "출장" 항목 추가됨) |
| F-08 | 개발 | 연차 시스템 |
| F-09 | 개발 | 공지 시스템 |
| F-10 | 개발 | 기타분류 화면 (팀장별 기타 항목 조회) |
| R-01 | 리팩토링 | **View_Screen 매트릭스 재계산 로직 다수 → `btnRecalcMatrix` 단일화** (우선순위 높음) |
| R-02 | 리팩토링 | 모든 `name_label.Text` → `varMyName` 통일 잔여분 점검 |
| P-01 | 성능 | App.OnStart 최적화 — Daily_DB 2,000건 한도 구조 개선 (날짜·작성자 기반 부분 로딩 설계) |

---

## 13. 이번 세션 완료 작업 (요약)

1. **colProjectList / colAllProjects 소스 분리** — App.OnStart 맨 아래 중복 생성 줄 제거. 팀별=Task_DB(colTargetAuthors 기반), 프로젝트별=Project_DB 전체. (B-03)
2. **colTargetAuthors 팀원 분기 변경** — "본인만" → "팀 전체"(`Filter(colUsers, 팀 = varMyTeam)`).
3. **Task_Screen 프로젝트 필터 재설계** — colSelectedProjects(선택 추적) → colDeselectedProjects(해제 추적)로 전환. Distinct/in 위임 한계 우회. 전체 선택/해제 체크박스 동기화. (B-07)
4. **name_label → varMyName 전환** — `User().FullName` 파싱 깨짐 근본 해결. (B-06)
5. **작업분류 선택 시 입력값 초기화 버그** — ddWorkTag.OnChange Patch에 작업시간·작업내용 동시 저장. (B-08)
6. **연차/반차 작업시간 자동 입력** — 연차=8, 반차=4. OnChange 계산→UpdateContext→Patch→Reset 순서 확정.
7. **View_Screen 주 이동 버튼** — colTeamWeekDaily 재로드 + colTeamMatrix 재계산 추가. 다음주 버튼 주석 혼입 사고 수정. (B-01)
8. **프로젝트 관리 모달 2패널 재설계** — Form 제거, Patch 방식. 1280×720, 좌측 필터(업무_계정+상태)+목록, 우측 헤더/기본정보/현황(D-day·진행률·등록일). 상태 뱃지, 모드 토글(View/Edit/New). (B-04, B-05, F-05)

---

## 14. 다음 세션 우선순위 (추천)

1. **프로젝트 관리 모달 마무리** — 버튼 정리(STEP 6-A), 저장 Patch 교체(6-B), ddStatus 필터(6-C) 적용 확인 + Edit/New 모드 동작 테스트.
2. **R-01 — View_Screen 매트릭스 재계산 단일화** (재계산 코드가 여러 곳 중복이라 추가 버그 위험 큼).
3. **F-06 — 연차/반차 색 처리** (작업시간 자동 입력은 끝났으니 시각 표시만 추가).

---

## 15. 세션 시작 방법

```
1. 이 CLAUDE.md 첨부
2. 작업할 화면의 .powerfx 첨부 (예: Task_Screen.powerfx)
3. 작업 내용 설명
   예시: "CLAUDE.md + Task_Screen.powerfx — 프로젝트 관리 모달 버튼 정리부터 진행"
```

### 코드 스타일 (개발자 선호)
- 한국어 대화, 기술 용어는 영어 유지(Delegation, Filter, Patch 등)
- 코드 블록 앞 `=` 미사용 (복사 후 바로 붙여넣기)
- 코드 제공 후 적용 위치 명시: 컨트롤 / 속성 / 화면 + 한 줄 요약
- 속성값은 한 줄씩 (X=465/Y=124 함축 표기 금지)
- UI 작업은 STEP별로: 적용 → 스크린샷 확인 → 다음 단계
- Delegation·성능 경고는 항상 선제적으로
- 더 나은 구조가 있으면 코드 전에 먼저 제안
