# CLAUDE.md — 업무현황판 (Worklog Management Dashboard)

> Claude 전용 핸드오프 문서. 새 세션 시작 시 이 파일 + 작업할 화면의 `.powerfx`를 첨부할 것.
> GitHub: https://github.com/siilver94/PowerApps_worklog-management-dashboard

---

## 0. 이 문서를 읽는 Claude에게 (필독)

이 앱은 **103명이 매일 쓰는 실서비스**다. 그리고 **개발자(김은성 주임)는 Power Fx 코드 자체에는 약하고, 요구사항 중심으로 대화**한다. 다음을 반드시 지킬 것:

1. **Delegation·성능을 항상 먼저 고려한다.** Daily_DB는 연 45,000건 이상 쌓이고, PowerApps 위임 한도는 기본 2,000건이다. 어떤 코드를 주든 위임 가능 여부를 먼저 판단하고, 위임 불가 시 경고 + 대안을 함께 제시한다.
2. **요구사항을 정확히 파악한 뒤 코드를 준다.** 바로 코드부터 던지지 말고, 동작·기능을 먼저 정리하고 합의한 뒤 구현한다.
3. **코드는 `=` 접두사 없이**, 실제 동작하는 완성본으로 준다. 적용 위치(컨트롤 + 속성 + 화면)를 항상 명시한다.
4. **한 번에 한 곳씩 고친다.** 전체를 갈아엎으면 다른 화면 참조가 깨진다. (이번 세션에서 App.OnStart 전체 교체를 시도했다가 크게 꼬였다.)
5. **컬럼명은 문자열로 감싸지 않는다.** `Filter(테이블, 작성자 in ...)` 처럼 컬럼을 직접 참조한다. `"작성자"` 처럼 쌍따옴표로 감싸면 문자열 비교가 되어 필터가 깨진다. (이번 세션의 주요 실수)

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

### Project_DB — 프로젝트 마스터 (약 68건, 소규모)
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Int | PK |
| 상태 | Text | 시작전 / 진행중 / 완료 |
| 연구비_계정 | Text | 개발비 등 |
| 업무_계정 | Text | 제품개발/기술개발/원가절감/설계변경/TF/교육/기타업무/연차(반차)/**연구관리** |
| 프로젝트명 | Text | |
| PM | Text | |
| 관련기종명 | Text | |
| 시작날짜 / 종료날짜 | Date | |
| 비고 | Text | |
| 금액(견본/용역/시작품/특허/신뢰성/WPBC) | Int | |

> **소규모(68건)라 delegation 한도에 안 걸린다.** 프로젝트 전체 목록이 필요하면 Project_DB를 직접 쓰는 게 안전.

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

| 직급2 | 인원 | 부문 컬럼값 | View_Screen에서 보이는 범위 |
|-------|------|------------|------------------------------|
| 소장 | 1명 | 연구소장 | **전체 팀**의 팀장이 작성한 업무일지 |
| 부문장 | 2명 | Function / Project (각 1명) | **담당 부문**의 팀장이 작성한 업무일지 |
| 팀장 | 다수 | Function / Project | **본인 팀**이 작성한 업무일지 |
| 팀원 | 다수 | Function / Project | **본인**이 작성한 업무일지 |

- 부문은 **Function**과 **Project** 2개, 각 부문에 부문장 1명씩.
- 권한 판단 변수: `varMyRole`(직급2), `varMyTeam`(팀), `varMyDivision`(부문).

---

## 5. 핵심 전역 변수

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `varMyEmail` | Text | 소문자 이메일 (`Lower(User().Email)`) — **가장 먼저 세팅, 모든 사용자 매칭의 기준** |
| `varMyName` | Text | 로그인 사용자 한글 이름 (이메일로 LookUp) |
| `varMyTeam` | Text | 팀명 |
| `varMyDivision` | Text | 부문명 (Function / Project) |
| `varMyRole` | Text | 팀원 / 팀장 / 부문장 / 소장 — **권한 제어 핵심** |
| `varViewMode` | Text | View_Screen 모드: "팀별" / "프로젝트별" |
| `vw_StartOfWeek` | Date | View_Screen 주간 시작일(월요일) |
| `varSelectedDate` | Date | Daily_Screen 선택 날짜 |
| `varFirstDayOfMonth` | Date | 달력 현재 월 기준 |
| `varEditMode` | Boolean | 편집 모드 여부 |
| `varFilterMode` | Text | "All" / "15Days" |
| `varProjectMode` | Text | "View" / "New" / "Edit" |
| `varShowToast` / `varShowToast2` | Boolean | 토스트 알림 |

> ⚠️ **`varMyRole` 세팅은 반드시 이메일 기준 LookUp으로.** `User().FullName` 파싱이나 `name_label.Text`에 의존하면 안 됨 (B-06 참고). App.OnStart에서 `varMyEmail` 세팅 직후에 `varMyRole`, `varMyTeam`, `varMyDivision`을 확정할 것. 과거 코드에 `varMe`/`varMyInfo`로 한 번 더 덮어쓰는 줄이 있었는데 이게 Blank를 유발했으니, 중복 세팅이 남아있지 않은지 항상 확인.

---

## 6. 핵심 컬렉션

| 컬렉션명 | 출처 | 설명 |
|----------|------|------|
| `colUsers` | UserInfo_DB | 사용자 캐시. **역할별 필터링·LookUp 반복 비용 제거용.** App.OnStart에서 일찍 생성해야 이후 로직이 동작 |
| `colDailyTasks` | Daily_DB | Daily_Screen 우측 편집 중인 업무 목록 |
| `colDaily_365_Team` | Daily_DB | 최근 365일 내 팀 데이터 캐시 (2,000건 한도 주의) |
| `colDaily_365_All` | Daily_DB | 최근 365일 전체 데이터 캐시 (2,000건 한도 — **주간 조회에는 쓰지 말 것**) |
| `colTargetAuthors` | colUsers | **역할별 조회 대상 작성자 목록** (소장→전체 팀장, 부문장→부문 팀장, 팀장→팀 전원, 팀원→본인) |
| `colProjectList` | Task_DB | **팀별 모드** 프로젝트 목록 (colTargetAuthors가 Task_DB에 등록한 프로젝트) |
| `colAllProjects` | Project_DB | **프로젝트별 모드** 프로젝트 목록 (Project_DB 전체, 68건) |
| `colSelProjects` | UI | View_Screen에서 선택된 프로젝트. `colProjectList`/`colAllProjects`와 **동일 구조(Value 컬럼)** 유지 필수 |
| `colTeamWeekDaily` | Daily_DB | View_Screen 주간 데이터 — **Daily_DB 직접 호출(날짜 필터 위임)** |
| `colTeamMatrix` | 가공 | View_Screen 매트릭스용 GroupBy 결과 |
| `colWorkTagsMap` | 하드코딩 | 업무_계정별 작업_분류 드롭다운 매핑 |
| `colTeamPeriodData` | Daily_DB | DashB_Screen 기간 데이터 |
| `colAccAgg` / `colProjChart` / `colWorkTagAgg` | 가공 | DashB 집계 |
| `colKoreaHolidays` | 하드코딩 | 2025~2030 공휴일 (Daily_Screen 달력 색 처리) |

---

## 7. 작업_분류 매핑 (`colWorkTagsMap`) — 중요 패턴

업무_계정별로 작업_분류 드롭다운 항목이 다르다. App.OnStart의 `colWorkTagsMap` 테이블에 `{Account, Tag, Order}` 형태로 하드코딩.

### 연구관리 계정의 프로젝트별 분기 (이번 세션에서 구현)
`업무_계정 = "연구관리"`인 경우, **프로젝트명까지 조합**해서 작업_분류를 다르게 한다.
- 매핑 키 형식: `"연구관리_" & 프로젝트명` (예: `"연구관리_회계"`, `"연구관리_S/W"`)
- 이 조합 키는 **앱 내부 메모리(colWorkTagsMap)에서만** 쓰는 매핑 키. DB에는 `작업_분류` 태그값(행정/회의 등)만 저장된다.

연구관리 5개 프로젝트 작업_분류:
| 프로젝트 | 작업_분류 항목 |
|----------|----------------|
| 회계 / 관리 / 검정·인증 | 행정, 지원업무, 회의, 문서/보고, 기타 |
| S/W | 기획/설계, 개발/코딩, 문서/보고, 회의, 기타 |
| 데이터분석 | 데이터처리, 분석/모델링, 문서/보고, 회의, 기타 |

### ddWorkTag 매핑 로직 (Daily_Screen)
`ddWorkTag.Items` / `DefaultSelectedItems`에서 Account 키를 이렇게 만든다:
```
If(
    ThisItem.c업무_계정 = "연구관리",
    "연구관리_" & ThisItem.c프로젝트명,
    ThisItem.c업무_계정
)
```

### 작업_분류 강제 선택 (이번 세션에서 구현)
- "미분류"로 저장되는 것을 막기 위해, `colDailyTasks`의 **모든 업무가 작업_분류를 선택해야** 저장 버튼(`Send_btn`) 활성화.
- `ddWorkTag.OnChange`에서 선택 즉시 `colDailyTasks`에 반영(저장 시점 일괄 반영으로는 버튼 활성화 조건이 실시간 동작 안 함).
- 미선택 시 안내 문구 라벨 표시(`"— 미선택 —"`은 placeholder로 유지).

---

## 8. View_Screen 동작 사양 (이번 세션 핵심 작업)

### 팀별 / 프로젝트별 모드
| 모드 | 프로젝트 목록 소스 | 매트릭스에 보이는 사람 |
|------|--------------------|------------------------|
| 팀별 | `colProjectList` (역할별 작성자가 Task_DB에 등록한 프로젝트) | `varMyRole` 권한 범위 (소장→전체 팀장, 부문장→부문 팀장, 팀장/팀원→본인 팀) |
| 프로젝트별 | `colAllProjects` (Project_DB 전체) | **권한 제한 없이 전 인원** (선택 프로젝트 기준) |

### 주간 데이터 로딩 원칙 (중요)
- `colTeamWeekDaily`는 **`Daily_DB` 직접 호출**로 그 주(월~금)만 가져온다.
- 이유: 날짜 범위 필터는 위임 가능 → 주간은 건수가 적어 2,000건 한도에 안 걸림 → 그 주 전 인원 데이터를 정확히 확보.
- ❌ `colDaily_365_All`(2,000건 캐시)에서 주간을 뽑으면 최신순으로 잘려서 특정 팀만 나오는 편향 발생. (이번 세션에서 실제로 겪은 함정)

### 매트릭스 재계산 로직 중복 문제 (미해결 — 다음 작업)
동일한 `colTeamMatrix` 재계산 코드가 **4곳에 복붙**되어 있음:
- `View_Screen.OnVisible`
- `tgl_ViewMode.OnChange`
- `chkProj.OnCheck` / `chkProj.OnUncheck`
- `chkAll.OnCheck` / `chkAll.OnUncheck`

→ **다음 단계: 숨김 버튼 `btnRecalcMatrix` 하나에 로직을 모으고 각 컨트롤은 `Select(btnRecalcMatrix)` 한 줄만 호출.** (DashB_Screen의 `btnRecalcDash` 패턴과 동일하게)

### 매트릭스 재계산 표준 로직 (현재 합의된 형태)
```
ClearCollect(
    colTeamMatrix,
    With(
        { baseRows: colTeamWeekDaily },
        With(
            {
                rawRows: If(
                    CountRows(colSelProjects) = 0,
                    Filter(baseRows, false),
                    Filter(baseRows, Trim(프로젝트명) in colSelProjects.Value)
                )
            },
            AddColumns(
                GroupBy(
                    If(
                        varViewMode = "프로젝트별",
                        rawRows,                                  // 전 인원
                        Switch(                                   // 팀별 권한 제한
                            varMyRole,
                            "소장",   Filter(AddColumns(rawRows, AuthorRole, LookUp(colUsers, 이름_한글 = 작성자).직급2), AuthorRole = "팀장"),
                            "부문장", Filter(AddColumns(rawRows, AuthorRole, LookUp(colUsers, 이름_한글 = 작성자).직급2, AuthorDivision, LookUp(colUsers, 이름_한글 = 작성자).부문), AuthorRole = "팀장" && AuthorDivision = varMyDivision),
                                      Filter(AddColumns(rawRows, AuthorTeam, LookUp(colUsers, 이름_한글 = 작성자).팀), AuthorTeam = varMyTeam)
                        )
                    ),
                    작성자, Rows
                ),
                첫업무제목, If(!IsEmpty(Rows), First(Rows).업무제목, ""),
                Mon, Filter(Rows, Weekday(작성일자, 2) = 1),
                T,   Filter(Rows, Weekday(작성일자, 2) = 2),
                W,   Filter(Rows, Weekday(작성일자, 2) = 3),
                Th,  Filter(Rows, Weekday(작성일자, 2) = 4),
                F,   Filter(Rows, Weekday(작성일자, 2) = 5)
            )
        )
    )
)
```

---

## 9. 알려진 버그 목록

| 번호 | 화면 | 버그 | 상태 |
|------|------|------|------|
| B-01 | View_Screen | 이전주/다음주 이동 시 매트릭스 갱신 안됨 | ⚠️ 주 이동 버튼들이 `colWeek`/`colDaily_365_All`만 갱신. **`Daily_DB` 직접 + `colTeamMatrix` 재계산으로 통일 필요** (OnVisible은 수정 완료, 주이동 버튼은 미적용) |
| B-02 | View_Screen | 소장/부문장 화면에서 팀장 데이터 안보임 | ✅ 해결 (varMyRole 이메일 기준 세팅 + 주간 Daily_DB 직접 호출) |
| B-03 | Task_Screen | 프로젝트별 선택 필터 안됨 | ✅ View_Screen 측은 해결. Task_Screen `colSelectedProjects`는 미점검 |
| B-04 | Task_Screen | 프로젝트 관리 신규 저장 오류 | ❌ 미해결 — `업무_계정_DataCard3`의 `Update` 속성 누락(`cmbAccount.Selected.Value` 미연결) |
| B-05 | Task_Screen | 프로젝트 관리 상태 수정 안됨 | ❌ 미해결 — `상태_DataCard3`가 `TextInput` 자유입력. 드롭다운 전환 필요 |
| B-06 | 전체 | 특정 1명 이름 파싱 깨짐 | ⚠️ 부분 대응 — `User().FullName`이 `"서현 입 / 연구관리팀 / 주임"` 형식. App.OnStart 권한 세팅은 이메일 기준으로 우회했으나, **각 화면 `name_label.Text` 자체는 여전히 FullName 파싱**이라 Daily_DB 작성자 오저장 가능. 근본 해결: 모든 `name_label`을 `varMyName`으로 교체 |

---

## 10. 개발 예정 목록

| 번호 | 분류 | 내용 |
|------|------|------|
| F-01 | 개발 | 연장근로 시스템 (사전/사후 신청 화면) |
| F-02 | 개발 | 26년 사업 계획 프로젝트 — 종료분 완료 처리, 진행중만 표시 |
| F-03 | 개발 | 그래프 색 구분 |
| F-04 | 개발 | 팀별 작성률 표시 |
| F-05 | 개발 | 프로젝트 관리 화면 상태별 필터링 (완료 숨김) |
| F-06 | 개발 | 연차(반차) 색 처리 — Daily_Screen 빨간색 표시 |
| F-07 | 개발 | 출장 시스템 (작업_분류에 "출장" 항목 추가됨) |
| F-08 | 개발 | 연차 시스템 |
| F-09 | 개발 | 공지 시스템 |
| F-10 | 개발 | 기타분류 화면 (팀장별 기타 항목 조회) |
| R-01 | 리팩토링 | **View_Screen 매트릭스 재계산 로직 4곳 → `btnRecalcMatrix` 단일화** (우선순위 높음) |
| R-02 | 리팩토링 | 모든 `name_label.Text` → `varMyName` 통일 (B-06 근본 해결) |
| P-01 | 성능 | App.OnStart 최적화 — Daily_DB 2,000건 한도 구조 개선 (날짜·작성자 기반 부분 로딩 설계) |

---

## 11. 이번 세션 완료 작업 (요약)

1. **CLAUDE.md / 데이터 구조 / 권한 구조 문서화** 완료.
2. **연구관리 업무_계정 작업_분류 추가** — 회계/관리/검정·인증/S/W/데이터분석 5개 프로젝트, 프로젝트명 조합 키 방식.
3. **작업_분류 강제 선택** — 전 항목 선택 시에만 저장 버튼 활성화 + 안내 문구 + `ddWorkTag.OnChange` 즉시 반영.
4. **varMyRole 세팅 버그 수정** — `User().FullName`/`varMe` 의존 제거, 이메일 LookUp 기준으로 확정. 중복 덮어쓰기 줄 제거.
5. **ShowColumns 제거** — `colDaily_365_All/Team`이 ShowColumns로 컬럼명이 OData로 바뀌던 문제 해결.
6. **View_Screen 팀별/프로젝트별 재설계**
   - 팀별 = `colProjectList`(Task_DB, 역할별), 프로젝트별 = `colAllProjects`(Project_DB 전체)
   - 주간 데이터는 `Daily_DB` 직접 호출(위임)로 전 인원 정확 로드
   - `gal_ProjectFilter.Items`·`tgl_ViewMode.OnChange`·`chkProj`·`chkAll` 모드 분기 반영

---

## 12. 다음 세션 우선순위 (추천)

1. **R-01 — View_Screen 매트릭스 재계산 단일화** (지금 4곳 중복이라 추가 버그 위험 큼)
2. **B-01 — 주 이동 버튼**을 `Daily_DB` 직접 + `colTeamMatrix` 재계산으로 통일 (R-01과 함께 처리하면 자연스러움)
3. **B-04 / B-05 — 프로젝트 관리 모달** 저장·상태 수정 버그

---

## 13. 세션 시작 방법

```
1. 이 CLAUDE.md 첨부
2. 작업할 화면의 .powerfx 첨부 (예: View_Screen.powerfx)
3. 작업 내용 설명
   예시: "CLAUDE.md + View_Screen.powerfx — R-01 매트릭스 재계산 단일화 진행"
```

### 코드 스타일 (개발자 선호)
- 한국어 대화, 기술 용어는 영어 유지(Delegation, Filter, Patch 등)
- 코드 블록 앞 `=` 미사용 (복사 후 바로 붙여넣기)
- 코드 제공 후 적용 위치 명시: 컨트롤 / 속성 / 화면 + 한 줄 요약
- Delegation·성능 경고는 항상 선제적으로
