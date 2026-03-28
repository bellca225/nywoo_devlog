@AGENTS.md

# nywoo_devlog — Claude Code 규칙

## 프로젝트 개요
nywoo의 개발 포트폴리오 + 기술 블로그 사이트.
Next.js 15 App Router + TypeScript + Tailwind CSS + shadcn/ui + framer-motion

## 브랜치 전략
- `main` — 배포용. 직접 커밋 금지.
- `develop` — 통합 브랜치. 기능 완성 후 여기로 merge.
- `feat/기능명` — 기능 단위 작업. develop에서 분기, 완료 후 develop으로 PR.

새 기능 시작 시: `git checkout develop && git checkout -b feat/기능명`

## 커밋 컨벤션
- `feat:` 새 기능
- `fix:` 버그 수정
- `style:` UI/스타일 변경 (기능 변경 없음)
- `refactor:` 리팩토링
- `chore:` 설정, 의존성
- `docs:` 문서, README

## 코드 규칙
- 컴포넌트: `src/components/` (공통: common/, 레이아웃: layout/)
- 페이지: `src/app/` (App Router)
- 스타일: Tailwind만 사용. inline style, CSS module 금지.
- 타입: 모든 컴포넌트에 TypeScript 타입 명시
- 상태관리: Zustand (`src/store/`)

## 주의사항
- 코드 작성 전 항상 설계/구조 먼저 설명하고 승인 받을 것
- 컴포넌트 하나당 파일 하나
- 'use client' 는 꼭 필요한 경우에만
