# nywoo.dev — 포트폴리오 + 기술 블로그

개발하면서 정리한 내용과 커리어를 담는 개인 사이트입니다.

🔗 **사이트**: https://nywoo-devlog.vercel.app

![Next.js](https://img.shields.io/badge/Next.js_16-000?style=flat-square&logo=next.js&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-000?style=flat-square&logo=typescript&logoColor=3178C6)
![Supabase](https://img.shields.io/badge/Supabase-000?style=flat-square&logo=supabase&logoColor=3FCF8E)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-000?style=flat-square&logo=tailwindcss&logoColor=06B6D4)
![Claude Code](https://img.shields.io/badge/Claude_Code-000?style=flat-square&logo=anthropic&logoColor=D97757)

---

## 주요 기능

| 페이지 | 내용 |
|---|---|
| **홈** | 소개, 블로그 통계, 최근 글 |
| **블로그** | 글 목록, 태그 필터, 검색, 마크다운 본문(코드 하이라이트, GFM) |
| **글쓰기** | 관리자만 접근 가능한 작성 화면 |
| **타임라인** | 커리어 타임라인 (3D 파티클 배경) |
| **로그인** | Supabase Auth 기반 로그인 |

---

## 기술 스택

| 영역 | 사용 기술 |
|---|---|
| 프레임워크 | Next.js 16 (App Router), React 19, TypeScript |
| 스타일 | Tailwind CSS 4, shadcn/ui, framer-motion |
| 상태·데이터 | Zustand(클라이언트 상태), TanStack Query(서버 상태) |
| 백엔드 | Supabase (PostgreSQL, Auth, Row Level Security) |
| 폼 | react-hook-form + zod |
| 콘텐츠 | react-markdown, remark-gfm, rehype-highlight |

---

## 설계 포인트

### 1. 권한은 DB에서 막는다 (RLS)
화면에서 버튼을 숨기는 것만으로는 권한을 지킬 수 없어서, Supabase의 Row Level Security로 DB 단에서 막았습니다.

- `profiles.role`이 `admin`인 사용자만 글 작성·수정·삭제 가능
- 발행(`published = true`)된 글만 누구나 읽기 가능, 초안은 작성자만 조회
- `/blog/write`, `/dashboard`는 Next.js proxy(구 middleware)에서 로그인 여부를 먼저 확인하고, 페이지에서 한 번 더 `admin` 역할을 검사

### 2. 세션 갱신은 proxy에서
`@supabase/ssr`로 요청마다 쿠키 세션을 확인하고, Access Token이 만료되면 Refresh Token으로 자동 재발급합니다.

### 3. 렌더링 최적화
- 검색어 입력은 `useDeferredValue`로 처리해 타이핑이 목록 필터링에 막히지 않게 함
- 태그 목록·필터 결과는 `useMemo`로 계산 결과 재사용
- 헤더 스크롤 감지는 `requestAnimationFrame`으로 쓰로틀링
- 필터를 바꿀 때마다 목록 전체가 다시 애니메이션되던 문제 제거

---

## AI와 함께 개발하는 방식

이 프로젝트는 [Claude Code](https://claude.com/claude-code)와 페어 프로그래밍으로 만들었습니다. AI가 코드를 마음대로 쓰지 않도록 [`CLAUDE.md`](./CLAUDE.md)에 규칙을 정해 두었습니다.

- **설계 먼저**: 코드를 쓰기 전에 구조를 설명하고 승인을 받은 뒤 구현
- **브랜치 전략**: `main`(배포) ← `develop`(통합) ← `feat/기능명`, `main` 직접 커밋 금지
- **커밋 컨벤션**: `feat` / `fix` / `style` / `refactor` / `chore` / `docs`
- **코드 규칙**: Tailwind만 사용, 컴포넌트 하나당 파일 하나, `'use client'`는 꼭 필요할 때만
- **최신 버전 대응**: [`AGENTS.md`](./AGENTS.md)로 학습 데이터와 다른 Next.js 16 변경점을 문서에서 먼저 확인하게 함

AI가 만든 코드도 직접 읽고 설명할 수 있을 때 커밋합니다.

---

## 프로젝트 구조

```
src/
├─ app/
│  ├─ page.tsx · HomeClient.tsx    홈
│  ├─ blog/                        목록 · [slug] 상세 · write 작성
│  ├─ timeline/                    커리어 타임라인
│  └─ (auth)/login/                로그인
├─ components/
│  ├─ common/                      Provider (Auth, Query)
│  ├─ layout/                      Header, ThemeProvider
│  └─ ui/                          shadcn/ui
├─ lib/
│  ├─ supabase/                    server · client 클라이언트
│  └─ types/
├─ store/                          Zustand
└─ proxy.ts                        세션 갱신 + 보호 라우트
supabase/
├─ schema.sql                      테이블 + RLS 정책
└─ seed_*.sql                      블로그 글 시리즈
```

---

## 실행하기

```bash
npm install
cp .env.example .env.local   # Supabase 프로젝트 URL과 anon key 입력
npm run dev
```

Supabase SQL Editor에서 `supabase/schema.sql`을 먼저 실행하세요.
