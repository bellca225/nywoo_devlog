-- =============================================
-- 삽질기 포스트 시드 데이터 (2개)
-- seed_posts.sql 실행 후 이 파일 실행
-- =============================================

DO $SEED$
DECLARE
  author UUID;
  tag_supabase UUID;
  tag_nextjs UUID;
  tag_framer UUID;
  tag_ts UUID;
  post_id UUID;
BEGIN

-- admin 유저 확인
SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;
IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다. profiles.role을 admin으로 먼저 업데이트하세요.';
END IF;

-- 태그 생성
INSERT INTO tags (name) VALUES ('Supabase') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Next.js') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Framer Motion') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('TypeScript') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_supabase FROM tags WHERE name = 'Supabase';
SELECT id INTO tag_nextjs FROM tags WHERE name = 'Next.js';
SELECT id INTO tag_framer FROM tags WHERE name = 'Framer Motion';
SELECT id INTO tag_ts FROM tags WHERE name = 'TypeScript';

-- =============================================
-- 포스트 1: Supabase 삽질기 1편
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Next.js 블로그 만들다 Supabase에서 막힌 것들 — 삽질기 1편',
  'supabase-setup-troubleshooting-1',
  'Migration remote 미적용, "Database error creating new user" 오류까지 — Supabase와 Next.js를 처음 연동하며 겪은 실제 문제와 해결 과정을 정리했다.',
  '# Next.js 블로그 만들다 Supabase에서 막힌 것들 — 삽질기 1편

> 처음엔 간단할 줄 알았다. Supabase 프로젝트 만들고, 스키마 짜고, 연결하면 끝이라고 생각했다. 현실은 달랐다.

---

## 문제 1: "Database error creating new user"

블로그 admin 계정을 만들기 위해 Supabase 대시보드 **Authentication > Users > Add user**를 클릭했다.

```
Failed to create user: Database error creating new user
```

에러 메시지가 전부였다. 원인도, 스택 트레이스도 없다.

### 원인 추적

`auth.users`에 유저가 생성될 때 자동으로 `profiles` 테이블에 row를 삽입하는 트리거를 만들어뒀다.

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>''username'', split_part(NEW.email, ''@'', 1)),
    COALESCE(NEW.raw_user_meta_data->>''role'', ''viewer'')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

트리거가 실패하면 Auth 트랜잭션 전체가 롤백된다. 그래서 유저가 안 만들어지는 거였다.

### 진짜 원인: Migration이 Remote에 없었다

```bash
supabase migration list
```

```
   Local          | Remote | Time (UTC)
  ----------------|--------|---------------------
   20260321000000 |        | 2026-03-21 00:00:00
```

Remote 컬럼이 비어있다. 로컬에서만 마이그레이션이 정의돼 있고, **실제 Supabase 프로젝트에는 적용이 안 된 상태**였다.

처음 스키마를 짤 때 Supabase SQL Editor에서 직접 붙여넣기 실행했기 때문에, 테이블은 있는데 마이그레이션 이력이 없는 상태가 됐다.

### 해결

```bash
supabase db push
```

실행하면:

```
ERROR: relation "profiles" already exists (SQLSTATE 42P07)
```

테이블은 이미 있으니 당연히 실패한다. 이럴 때 쓰는 명령이 `migration repair`다.

```bash
supabase migration repair 20260321000000 --status applied
```

로컬 마이그레이션 파일이 이미 remote에 적용된 것으로 기록만 남긴다. 실제 SQL은 실행하지 않는다.

```bash
supabase migration list
```

```
   Local          | Remote         | Time (UTC)
  ----------------|----------------|---------------------
   20260321000000 | 20260321000000 | 2026-03-21 00:00:00
```

이제 양쪽이 맞다.

---

## 문제 2: 여전히 "Database error creating new user"

마이그레이션 이력을 맞췄는데도 유저 생성이 실패했다.

### 원인: 트리거 함수에 ON CONFLICT가 없다

대시보드에서 유저 생성을 몇 번 시도하면서 `auth.users`에 부분적으로 데이터가 남았거나, 트리거가 충돌을 처리하지 못하는 상황이 생겼다.

기존 함수:

```sql
INSERT INTO profiles (id, username, role)
VALUES (NEW.id, ..., ...);
-- 충돌 시 그냥 에러 발생
```

`profiles.id`는 `auth.users.id`를 참조하는 PK다. 같은 id로 재시도하면 UNIQUE violation이 발생하고 트리거가 터진다.

### 해결

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>''username'', split_part(NEW.email, ''@'', 1)),
    ''viewer''
  )
  ON CONFLICT (id) DO NOTHING;  -- 이미 있으면 그냥 넘어감
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

두 가지를 바꿨다:

1. **`ON CONFLICT (id) DO NOTHING`** — 중복 삽입 시도 시 에러 없이 스킵
2. **`SET search_path = public`** — SECURITY DEFINER 함수에서 search_path를 명시하지 않으면 예상치 못한 schema 참조 오류가 날 수 있다

이 SQL을 SQL Editor에서 실행한 뒤 유저 생성 성공.

---

## 문제 3: admin 권한 부여

유저는 만들어졌지만 `profiles.role`은 기본값 `''viewer''`다. 포스트 작성 권한이 없다.

```sql
UPDATE profiles
SET role = ''admin''
WHERE id = (SELECT id FROM auth.users WHERE email = ''내이메일@example.com'');
```

이걸 SQL Editor에서 실행해야 한다. 대시보드 UI에는 role을 바꾸는 기능이 없다.

---

## 정리

| 문제 | 원인 | 해결 |
|------|------|------|
| Database error creating new user | migration remote 미적용 | `supabase migration repair` |
| 여전히 실패 | 트리거에 ON CONFLICT 없음 | 함수 재생성 + ON CONFLICT DO NOTHING |
| 포스트 작성 불가 | role이 viewer | SQL로 직접 UPDATE |

**교훈:** Supabase SQL Editor에서 스키마를 직접 실행했다면, 반드시 `supabase migration repair`로 CLI와 이력을 맞춰둬야 한다. 안 그러면 나중에 `db push`, `db diff` 등 모든 CLI 명령이 꼬인다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_supabase);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);

-- =============================================
-- 포스트 2: Framer Motion 삽질기 2편
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Next.js 블로그 만들다 Framer Motion에서 막힌 것들 — 삽질기 2편',
  'framer-motion-troubleshooting-2',
  'Variants 타입 에러, exit 애니메이션 미동작, 모바일 메뉴가 라우트 이동 후에도 안 닫히는 문제까지 — Framer Motion을 TypeScript 프로젝트에 붙이며 겪은 실수들을 기록했다.',
  '# Next.js 블로그 만들다 Framer Motion에서 막힌 것들 — 삽질기 2편

> Framer Motion은 쉽다고 했다. 근데 TypeScript strict 환경에서 쓰면 은근히 까다롭다.

---

## 문제 1: Variants 타입 에러

### 증상

```typescript
const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.1, duration: 0.5, ease: "easeOut" },
  }),
};
```

이 코드를 `<motion.div variants={fadeUp}>` 에 넘기면:

```
Type ''{ hidden: { opacity: number; y: number; }; show: (i: number) => { ... }; }''
is not assignable to type ''VariantLabels | Variants | undefined''.
```

### 원인

TypeScript가 `fadeUp`을 `Variants` 타입으로 추론하지 못하고 일반 object literal로 본다. strict 모드에서는 타입이 맞지 않으면 props로 못 넘긴다.

### 해결

```typescript
import { motion, type Variants } from "framer-motion";

const fadeUp: Variants = {
  hidden: { opacity: 0, y: 24 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.1, duration: 0.5, ease: [0.25, 0.1, 0.25, 1] },
  }),
};
```

두 가지 변경:

1. **`type Variants` 명시적 import** — `import type`으로 타입만 가져오는 것이 번들 최적화에도 좋다
2. **`ease: "easeOut"` → `ease: [0.25, 0.1, 0.25, 1]`** — cubic-bezier 배열로 바꾸면 Variants 타입 내 transition 정의와도 충돌이 없고, 커스텀 커브도 자유롭게 조정 가능

---

## 문제 2: 모바일 메뉴 exit 애니메이션이 동작하지 않음

### 증상

```typescript
{menuOpen && (
  <motion.div
    initial={{ opacity: 0, y: -10 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -10 }}
  >
    ...
  </motion.div>
)}
```

열릴 때는 `initial → animate` 애니메이션이 잘 됐지만, 닫힐 때 `exit` 애니메이션 없이 그냥 사라졌다.

### 원인

`exit` 애니메이션은 `<AnimatePresence>`로 감싸지 않으면 동작하지 않는다. Framer Motion이 컴포넌트가 DOM에서 제거되는 시점을 감지하려면 `AnimatePresence`가 필요하다.

```typescript
// 틀린 코드
{menuOpen && <motion.div exit={{ opacity: 0 }}>...</motion.div>}

// 올바른 코드
<AnimatePresence>
  {menuOpen && <motion.div exit={{ opacity: 0 }}>...</motion.div>}
</AnimatePresence>
```

### 해결

```typescript
import { motion, AnimatePresence } from "framer-motion";

<AnimatePresence>
  {menuOpen && (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      transition={{ duration: 0.2 }}
      className="md:hidden ..."
    >
      {navLinks.map((link) => (
        <Link key={link.href} href={link.href}>
          {link.label}
        </Link>
      ))}
    </motion.div>
  )}
</AnimatePresence>
```

---

## 문제 3: 페이지 이동해도 모바일 메뉴가 안 닫힘

### 증상

모바일 메뉴에서 링크를 누르면 페이지는 이동하는데, 메뉴가 그대로 열려있다.

처음엔 각 `<Link>`의 `onClick`에 `setMenuOpen(false)`를 넣었다.

```typescript
<Link onClick={() => setMenuOpen(false)} href={link.href}>
```

이건 동작은 하지만 링크마다 핸들러를 달아야 하고, 뒤로가기 같은 네비게이션에는 반응하지 않는다.

### 해결: `usePathname`으로 라우트 감지

```typescript
import { usePathname } from "next/navigation";

const pathname = usePathname();

useEffect(() => {
  setMenuOpen(false);
}, [pathname]);
```

`pathname`이 바뀔 때마다 — 링크 클릭이든, 뒤로가기든, 프로그래밍 방식 이동이든 — 메뉴가 자동으로 닫힌다. `onClick` 핸들러도 제거해서 코드가 깔끔해졌다.

---

## 문제 4: hover 애니메이션이 전체 카드에 영향을 줌

### 증상

```typescript
<motion.article
  variants={fadeUp}
  whileHover={{ y: -4 }}
  transition={{ duration: 0.2 }}
>
```

카드에 마우스를 올리면 `whileHover`의 `y: -4`는 잘 됐는데, `transition={{ duration: 0.2 }}`이 `variants`의 fadein 애니메이션에도 영향을 줬다. 처음 렌더링 시 카드가 너무 빨리 나타나는 문제가 생겼다.

### 원인

`<motion.*>` 컴포넌트의 최상위 `transition` prop은 해당 요소의 **모든 애니메이션**에 적용된다. `variants`로 정의한 fade-up에도 `duration: 0.2`가 덮어쓰였다.

### 해결

```typescript
<motion.article
  variants={fadeUp}
  whileHover={{ y: -4, transition: { duration: 0.2 } }}
>
```

`transition`을 `whileHover` 객체 안으로 이동하면 hover 시에만 적용된다. `variants`의 transition은 variants 정의 내부에서 관리되므로 서로 독립적으로 동작한다.

---

## 정리

| 문제 | 원인 | 해결 |
|------|------|------|
| Variants 타입 에러 | TypeScript가 object literal을 Variants로 추론 못 함 | `type Variants` 명시 import |
| exit 애니메이션 미동작 | AnimatePresence 없음 | `<AnimatePresence>`로 감싸기 |
| 메뉴가 라우트 이동 후 안 닫힘 | onClick만으로 처리 | `usePathname` + `useEffect`로 감지 |
| hover transition이 전체에 적용 | 최상위 transition prop이 모든 애니메이션에 영향 | transition을 whileHover 객체 안으로 이동 |

**교훈:** Framer Motion은 직관적으로 보이지만 TypeScript strict 환경에서 타입을 제대로 안 잡아주면 에러가 쌓인다. 그리고 `exit`는 무조건 `AnimatePresence` 안에서만 동작한다. 이건 문서에도 나와있는데 그냥 지나친 거다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_framer);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

-- =============================================
-- 포스트 3: Vercel 배포 포스트
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Next.js 프로젝트 Vercel로 배포하기 — GitHub 연동부터 환경변수까지',
  'nextjs-vercel-deployment-guide',
  'GitHub 저장소 연결, 환경변수 설정, 자동 배포 파이프라인 구성까지 — Next.js 프로젝트를 Vercel에 배포하는 전체 과정을 정리했다.',
  '# Next.js 프로젝트 Vercel로 배포하기 — GitHub 연동부터 환경변수까지

> 로컬에서 잘 되는 거 배포까지 올리는 과정. 생각보다 빠르지만 환경변수 처리에서 한 번씩 막힌다.

---

## Vercel이 뭔가요?

Vercel은 Next.js를 만든 회사가 운영하는 배포 플랫폼이다. Next.js와 가장 잘 맞는 호스팅 환경이고, GitHub에 push하면 자동으로 빌드 및 배포가 된다.

**특징:**
- GitHub push → 자동 빌드 → 자동 배포
- PR마다 Preview URL 자동 생성
- 무료 플랜으로 개인 프로젝트 충분히 운영 가능
- Edge Network으로 전 세계 빠른 응답

---

## 배포 전 체크리스트

### 1. `.env.local`은 git에 올리지 않는다

```bash
# .gitignore에 이미 있는지 확인
cat .gitignore | grep .env
```

`.env.local`이 `.gitignore`에 포함되어야 한다. 없으면 추가:

```
.env.local
```

환경변수는 Vercel 대시보드에서 따로 설정한다.

### 2. 빌드가 로컬에서 통과하는지 확인

```bash
npm run build
```

타입 에러, lint 에러가 없어야 한다. Vercel은 `npm run build`와 동일한 과정으로 빌드하기 때문에 로컬에서 실패하면 배포도 실패한다.

---

## GitHub에 올리기

```bash
# 원격 저장소 연결 (이미 되어있으면 skip)
git remote add origin https://github.com/유저명/레포명.git

# 첫 push
git push -u origin main
```

---

## Vercel에서 프로젝트 연결

### 1. Vercel 대시보드에서 프로젝트 생성

1. [vercel.com](https://vercel.com) 접속 → GitHub 계정으로 로그인
2. **Add New → Project** 클릭
3. GitHub 저장소 목록에서 해당 레포 선택 → **Import**

### 2. 빌드 설정 확인

Vercel이 Next.js를 자동 감지해서 설정을 채워준다.

| 항목 | 값 |
|------|-----|
| Framework Preset | Next.js |
| Build Command | `next build` |
| Output Directory | `.next` |
| Install Command | `npm install` |

건드릴 필요 없다.

### 3. 환경변수 설정 (중요)

`.env.local`에 있는 값들을 여기서 입력해야 한다.

**Environment Variables** 섹션에서:

```
NEXT_PUBLIC_SUPABASE_URL     = https://xxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY = sb_publishable_xxxx...
NEXT_PUBLIC_APP_URL          = https://내도메인.vercel.app
```

`NEXT_PUBLIC_`으로 시작하는 변수는 클라이언트에서도 읽힌다. 비밀키는 `NEXT_PUBLIC_` 없이 서버 전용으로.

**Deploy** 클릭 → 빌드 시작.

---

## 자동 배포 파이프라인

한 번 연결하면 이후부터는 push만 하면 된다.

```bash
git add .
git commit -m "feat: 새 기능 추가"
git push origin main
```

### 브랜치별 동작

| 브랜치 | 결과 |
|--------|------|
| `main` | Production 배포 (실제 도메인) |
| 그 외 브랜치 | Preview 배포 (임시 URL 자동 생성) |

PR을 열면 Vercel 봇이 자동으로 Preview URL을 댓글로 달아준다. 리뷰어가 배포된 결과를 바로 확인할 수 있어서 유용하다.

---

## 환경변수 변경 시

코드 변경 없이 환경변수만 바꿔도 재배포가 필요하다.

1. Vercel 대시보드 → 프로젝트 → **Settings → Environment Variables**
2. 변수 수정
3. **Deployments → 최근 배포 → Redeploy** 클릭

또는 CLI로:

```bash
# Vercel CLI 설치
npm i -g vercel

# 로그인
vercel login

# 환경변수 추가
vercel env add ANTHROPIC_API_KEY

# 프로덕션 재배포
vercel --prod
```

---

## 로컬 환경변수 동기화

Vercel에 올린 환경변수를 로컬로 내려받을 수 있다.

```bash
vercel env pull .env.local
```

팀 프로젝트에서 유용하다. 새로 클론한 뒤 이 명령 하나로 `.env.local`을 세팅할 수 있다.

---

## 커스텀 도메인 연결

무료 플랜에서도 커스텀 도메인 연결이 가능하다.

1. 대시보드 → 프로젝트 → **Settings → Domains**
2. 도메인 입력 → **Add**
3. DNS 레코드 설정 안내가 나옴

도메인 구매처(가비아, Cloudflare 등)에서 안내된 CNAME 또는 A 레코드를 추가하면 된다. 반영까지 최대 48시간이지만 보통 수 분 내에 된다.

---

## 배포 실패 시 디버깅

### 빌드 로그 확인

Vercel 대시보드 → 해당 배포 클릭 → **Build Logs** 탭

TypeScript 에러, 누락된 환경변수, import 경로 오류 등이 여기서 다 나온다.

### 자주 나오는 에러

**환경변수 없음:**
```
Error: Missing NEXT_PUBLIC_SUPABASE_URL
```
→ Vercel 환경변수 설정에서 추가 후 재배포

**타입 에러:**
```
Type error: Property ''x'' does not exist on type ''y''
```
→ 로컬에서 `npm run build` 통과시키고 push

**모듈 없음:**
```
Module not found: Can''t resolve ''@/components/...''
```
→ `tsconfig.json`의 `paths` 설정 확인

---

## 정리

```
코드 작성 → git push → Vercel 자동 빌드 → 자동 배포
```

핵심은 **환경변수를 Vercel 대시보드에 따로 입력하는 것**이다. `.env.local`은 로컬 전용이고 git에 올리지 않는다. 이것만 지키면 배포 자체는 어렵지 않다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);

RAISE NOTICE '삽질기 + 배포 포스트 3개 삽입 완료. author: %', author;

END $SEED$;
