-- =============================================
-- 배치 3: 하네스 코딩 + CDN/이미지 캐시
-- =============================================

DO $SEED3$
DECLARE
  author UUID;
  tag_testing UUID;
  tag_js UUID;
  tag_ts UUID;
  tag_nextjs UUID;
  tag_perf UUID;
  post_id UUID;
BEGIN

SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;
IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다.';
END IF;

INSERT INTO tags (name) VALUES ('테스팅') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('성능최적화') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('JavaScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('TypeScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Next.js') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_testing FROM tags WHERE name = '테스팅';
SELECT id INTO tag_js FROM tags WHERE name = 'JavaScript';
SELECT id INTO tag_ts FROM tags WHERE name = 'TypeScript';
SELECT id INTO tag_nextjs FROM tags WHERE name = 'Next.js';
SELECT id INTO tag_perf FROM tags WHERE name = '성능최적화';

-- =============================================
-- 포스트 1: 하네스 코딩
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '하네스(Harness) 코딩이란? — 테스트 하네스 설계와 실전 패턴',
  'test-harness-coding-guide',
  '하네스 코딩이 무엇인지, 왜 필요한지, Jest + React Testing Library + MSW로 실전 테스트 하네스를 구축하는 방법까지 정리했다.',
  '# 하네스(Harness) 코딩이란? — 테스트 하네스 설계와 실전 패턴

> "테스트하기 좋은 코드"와 "하네스를 잘 짠 코드"는 같은 말이다.

---

## 하네스(Harness)가 뭔가요?

**테스트 하네스(Test Harness)**는 테스트 대상 코드를 실행하기 위한 **제어된 환경 전체**를 말한다.

자동차의 배선 하네스(Wire Harness)에서 따온 말이다. 전선들을 묶어서 정해진 경로로 전기가 흐르게 하듯, 테스트 하네스는 코드가 **예측 가능한 경로로 실행**되도록 환경을 통제한다.

구체적으로 테스트 하네스는 다음을 포함한다:

- **테스트 러너** (Jest, Vitest)
- **Mock / Stub / Spy** — 외부 의존성 대체
- **테스트용 렌더러** (React Testing Library)
- **API 가로채기** (MSW — Mock Service Worker)
- **공통 setup/teardown** 코드

---

## 왜 하네스 코딩이 중요한가?

### 테스트 없는 개발의 문제

```
기능 추가 → 수동 클릭 확인 → "됩니다" → 배포
→ 3주 뒤 다른 기능 수정 → 이전 기능 깨짐 → 발견 못함 → 장애
```

### 하네스가 있는 개발

```
기능 추가 → 테스트 작성 → CI 통과 → 배포
→ 3주 뒤 다른 기능 수정 → 테스트 실패 → 즉시 발견 → 수정
```

---

## 하네스 코딩의 핵심 원칙

### 1. 의존성을 주입 가능하게 설계

테스트하기 어려운 코드의 공통점은 **의존성이 내부에 박혀있다**는 것이다.

```typescript
// 나쁜 설계: fetch가 내부에 고정
async function getUserPosts(userId: string) {
  const res = await fetch(`/api/users/${userId}/posts`);
  return res.json();
}

// 좋은 설계: fetcher를 주입받음
async function getUserPosts(
  userId: string,
  fetcher = fetch  // 기본값은 실제 fetch, 테스트에서는 mock 주입
) {
  const res = await fetcher(`/api/users/${userId}/posts`);
  return res.json();
}
```

### 2. 사이드 이펙트를 경계로 분리

```typescript
// 순수 함수 (테스트 쉬움)
function formatPosts(rawPosts: RawPost[]): Post[] {
  return rawPosts.map(p => ({
    id: p.id,
    title: p.title.trim(),
    createdAt: new Date(p.created_at),
  }));
}

// 사이드 이펙트 함수 (하네스로 제어)
async function fetchAndFormatPosts(userId: string) {
  const raw = await api.getPosts(userId);  // 하네스에서 mock
  return formatPosts(raw);                  // 순수 함수, 직접 테스트
}
```

---

## 실전: Jest + React Testing Library 하네스 구축

### 설치

```bash
npm install -D jest @testing-library/react @testing-library/user-event @testing-library/jest-dom jest-environment-jsdom ts-jest msw
```

### jest.config.ts

```typescript
import type { Config } from "jest";

const config: Config = {
  testEnvironment: "jsdom",
  setupFilesAfterFramework: ["<rootDir>/jest.setup.ts"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/src/$1",  // 경로 alias
    "\\.(css|scss)$": "identity-obj-proxy",  // CSS 무시
  },
  transform: {
    "^.+\\.tsx?$": ["ts-jest", { tsconfig: "tsconfig.jest.json" }],
  },
};

export default config;
```

### jest.setup.ts

```typescript
import "@testing-library/jest-dom";

// 전역 mock — 모든 테스트에서 window.matchMedia 사용 가능하게
Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});
```

---

## 실전: MSW로 API 하네스 구축

MSW(Mock Service Worker)는 네트워크 요청 자체를 가로채서 mock 응답을 준다. fetch를 직접 mock하는 것보다 실제 환경에 가깝다.

### src/mocks/handlers.ts

```typescript
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/posts", () => {
    return HttpResponse.json([
      { id: "1", title: "테스트 포스트", slug: "test-post" },
      { id: "2", title: "두 번째 포스트", slug: "second-post" },
    ]);
  }),

  http.post("/api/posts", async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: "3", ...body }, { status: 201 });
  }),
];
```

### src/mocks/server.ts

```typescript
import { setupServer } from "msw/node";
import { handlers } from "./handlers";

export const server = setupServer(...handlers);
```

### jest.setup.ts에 서버 연결

```typescript
import { server } from "./src/mocks/server";

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());  // 테스트 간 핸들러 초기화
afterAll(() => server.close());
```

---

## 실전: 컴포넌트 테스트 하네스

### 테스트할 컴포넌트

```typescript
// src/components/PostList.tsx
export function PostList({ userId }: { userId: string }) {
  const { data: posts, isLoading } = useQuery({
    queryKey: ["posts", userId],
    queryFn: () => fetch(`/api/posts?userId=${userId}`).then(r => r.json()),
  });

  if (isLoading) return <div>로딩 중...</div>;
  return (
    <ul>
      {posts?.map(post => <li key={post.id}>{post.title}</li>)}
    </ul>
  );
}
```

### 공통 render 유틸리티 (하네스 핵심)

```typescript
// src/test-utils/render.tsx
import { render, type RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,  // 테스트에서 재시도 없애기
        gcTime: 0,
      },
    },
  });
}

function AllProviders({ children }: { children: React.ReactNode }) {
  const queryClient = createTestQueryClient();
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

// 커스텀 render — 모든 Provider가 포함된 하네스
export function renderWithProviders(
  ui: React.ReactElement,
  options?: RenderOptions
) {
  return render(ui, { wrapper: AllProviders, ...options });
}
```

### 실제 테스트

```typescript
// src/components/PostList.test.tsx
import { screen, waitFor } from "@testing-library/react";
import { renderWithProviders } from "@/test-utils/render";
import { PostList } from "./PostList";

describe("PostList", () => {
  it("포스트 목록을 렌더링한다", async () => {
    renderWithProviders(<PostList userId="user-1" />);

    // 로딩 상태 확인
    expect(screen.getByText("로딩 중...")).toBeInTheDocument();

    // API 응답 후 데이터 확인
    await waitFor(() => {
      expect(screen.getByText("테스트 포스트")).toBeInTheDocument();
      expect(screen.getByText("두 번째 포스트")).toBeInTheDocument();
    });
  });

  it("특정 테스트에서 다른 응답을 사용할 수 있다", async () => {
    // MSW 핸들러를 이 테스트에서만 오버라이드
    server.use(
      http.get("/api/posts", () => {
        return HttpResponse.json([]);  // 빈 배열 응답
      })
    );

    renderWithProviders(<PostList userId="user-1" />);

    await waitFor(() => {
      expect(screen.queryByRole("listitem")).not.toBeInTheDocument();
    });
  });
});
```

---

## 하네스 코딩 체크리스트

### 설계 단계
- [ ] 외부 의존성(API, localStorage, Date)이 주입 가능한가?
- [ ] 순수 함수와 사이드 이펙트가 분리되어 있는가?
- [ ] 컴포넌트가 단일 책임을 갖는가?

### 구현 단계
- [ ] 공통 `render` 유틸리티에 Provider가 포함되어 있는가?
- [ ] MSW 핸들러가 실제 API 스펙을 반영하는가?
- [ ] `beforeEach`에서 상태를 초기화하는가?

### 검증 단계
- [ ] Happy path 테스트가 있는가?
- [ ] Error case 테스트가 있는가?
- [ ] Loading 상태 테스트가 있는가?

---

## 정리

하네스 코딩의 핵심은 **"코드를 고립시켜 예측 가능하게 실행하는 환경"**을 만드는 것이다.

- 의존성 주입으로 mock 교체 가능하게 설계
- MSW로 실제 네트워크에 가까운 API mock
- 공통 render 유틸리티로 반복 제거
- 각 테스트는 독립적으로 — 순서에 무관하게 통과해야 한다',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_testing);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

-- =============================================
-- 포스트 2: CDN + 이미지 캐시
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'CDN과 프론트엔드 이미지 캐시 처리 완전 정리 — 개념부터 실무까지',
  'cdn-image-cache-frontend-guide',
  'CDN이 뭔지부터 Cache-Control 헤더, 브라우저 캐시 vs CDN 캐시, next/image 최적화, WebP/AVIF 전환, Lazy Loading, stale-while-revalidate 전략까지 — 프론트엔드에서 이미지를 다루는 모든 것을 정리했다.',
  '# CDN과 프론트엔드 이미지 캐시 처리 완전 정리 — 개념부터 실무까지

> 이미지 하나 잘못 다루면 LCP가 2초에서 6초로 늘어난다. 캐시 전략 하나로 서버 비용이 90% 줄기도 한다.

---

## CDN이란?

**CDN(Content Delivery Network)**은 전 세계에 분산된 서버 네트워크다. 사용자가 리소스를 요청하면 원본 서버(Origin)가 아닌 **가장 가까운 CDN 엣지 서버**가 응답한다.

### CDN 없는 상황

```
서울 사용자 → 미국 Origin 서버 (왕복 200ms)
도쿄 사용자 → 미국 Origin 서버 (왕복 180ms)
런던 사용자 → 미국 Origin 서버 (왕복 140ms)
```

### CDN 있는 상황

```
서울 사용자 → 서울 CDN 엣지 (왕복 5ms, 캐시 HIT)
도쿄 사용자 → 도쿄 CDN 엣지 (왕복 3ms, 캐시 HIT)
런던 사용자 → 런던 CDN 엣지 (왕복 4ms, 캐시 HIT)
→ Origin 서버는 캐시 MISS 때만 호출
```

### 주요 CDN 서비스

| 서비스 | 특징 |
|--------|------|
| Cloudflare | 무료 플랜 강력, 가장 많이 씀 |
| AWS CloudFront | S3, EC2와 통합 용이 |
| Vercel Edge Network | Next.js 프로젝트 자동 적용 |
| Fastly | 실시간 캐시 퍼지 빠름 |

---

## 캐시의 종류

프론트엔드에서 이미지가 거치는 캐시 레이어는 3단계다.

```
사용자 요청
    ↓
1. 브라우저 캐시 (disk/memory cache)
    ↓ (MISS)
2. CDN 캐시 (엣지 서버)
    ↓ (MISS)
3. Origin 서버
```

각 레이어는 **HTTP 응답 헤더**로 캐시 동작을 제어한다.

---

## Cache-Control 헤더 완전 정리

`Cache-Control`은 캐시 동작을 지시하는 가장 중요한 헤더다.

### 주요 디렉티브

```http
Cache-Control: public, max-age=31536000, immutable
```

| 디렉티브 | 의미 |
|----------|------|
| `public` | CDN, 프록시 등 모든 캐시에 저장 가능 |
| `private` | 브라우저 캐시에만 저장 (CDN 저장 안 함) |
| `max-age=N` | N초 동안 유효. 이후 재검증 |
| `s-maxage=N` | CDN 캐시 전용 max-age (브라우저는 max-age 사용) |
| `immutable` | max-age 내에는 재검증 요청도 보내지 않음 |
| `no-cache` | 매번 재검증 후 사용 (캐시는 저장하되 항상 확인) |
| `no-store` | 캐시에 저장 자체를 하지 않음 |
| `stale-while-revalidate=N` | 만료된 캐시를 즉시 응답하고, 백그라운드에서 갱신 |

### 리소스별 전략

#### 정적 에셋 (JS, CSS, 이미지 — hash 포함 파일명)

```http
Cache-Control: public, max-age=31536000, immutable
```

`main.abc123.js`처럼 파일명에 hash가 있으면 내용이 바뀔 때 파일명이 바뀐다. 그래서 1년(`31536000`초) 캐시해도 안전하다. `immutable`을 추가하면 브라우저가 재검증 요청(`If-None-Match`)도 보내지 않는다.

#### HTML (항상 최신 버전 필요)

```http
Cache-Control: no-cache
```

`no-cache`는 캐시를 안 한다는 뜻이 아니다. "캐시는 저장하되, 매번 서버에 유효한지 확인 후 사용"이라는 뜻이다. 서버가 `304 Not Modified`를 응답하면 캐시를 그대로 쓰고, 변경됐으면 새로 받는다.

#### API 응답

```http
Cache-Control: private, no-cache
```

사용자별로 다른 데이터는 `private`. CDN에 저장되면 안 된다.

---

## ETag와 Last-Modified (재검증 메커니즘)

`max-age`가 만료되면 브라우저는 서버에 **조건부 요청**을 보낸다.

### ETag 기반

```http
# 첫 번째 응답
HTTP/1.1 200 OK
ETag: "abc123"
Cache-Control: max-age=3600

# max-age 만료 후 재검증 요청
GET /image.png
If-None-Match: "abc123"

# 파일이 안 바뀐 경우 (304, body 없음 → 빠름)
HTTP/1.1 304 Not Modified

# 파일이 바뀐 경우 (200, 새 파일 전송)
HTTP/1.1 200 OK
ETag: "def456"
```

ETag가 같으면 `304 Not Modified`로 응답해 body 전송을 생략한다. 네트워크 비용이 크게 줄어든다.

---

## stale-while-revalidate 전략

```http
Cache-Control: max-age=60, stale-while-revalidate=3600
```

동작:
- 60초 이내: 캐시 즉시 사용
- 60초 ~ 3660초: **만료된 캐시를 즉시 응답**하면서, **백그라운드에서 새 데이터 갱신**
- 3660초 초과: 네트워크 요청 후 응답

사용자는 항상 빠른 응답을 받고, 캐시는 백그라운드에서 자동 갱신된다. 뉴스 피드, 블로그 목록 같이 약간 오래된 데이터도 괜찮은 경우에 적합하다.

---

## Next.js에서 이미지 최적화

### next/image 기본 사용

```tsx
import Image from "next/image";

// 원격 이미지
<Image
  src="https://example.com/photo.jpg"
  alt="설명"
  width={800}
  height={600}
  priority    // LCP 이미지에 붙이기 (preload)
/>

// 로컬 이미지 (자동으로 width/height 추론)
import photo from "@/public/photo.jpg";
<Image src={photo} alt="설명" />
```

### next/image가 자동으로 해주는 것

1. **WebP/AVIF 변환** — 브라우저가 지원하면 자동으로 최신 포맷으로 서빙
2. **사이즈 최적화** — `sizes` prop에 따라 적절한 크기로 리사이즈
3. **Lazy Loading** — 뷰포트 밖 이미지는 기본으로 lazy load
4. **CLS 방지** — width/height로 레이아웃 공간 미리 확보

### next.config.ts에서 원격 도메인 허용

```typescript
const config = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "pykjsqsfdnhqkrmwuusv.supabase.co",
        pathname: "/storage/v1/object/public/**",
      },
    ],
    formats: ["image/avif", "image/webp"],  // AVIF 우선
  },
};
```

### sizes prop 올바르게 쓰기

```tsx
// 잘못된 예: 모바일에서도 800px 이미지 다운로드
<Image src={img} width={800} height={600} alt="" />

// 올바른 예: 화면 크기에 맞는 이미지 다운로드
<Image
  src={img}
  fill
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
  alt=""
/>
```

`sizes`를 올바르게 설정하면 모바일에서 불필요하게 큰 이미지를 받지 않는다.

---

## 이미지 포맷 선택 가이드

| 포맷 | 특징 | 용도 |
|------|------|------|
| **AVIF** | 최고 압축률, 느린 인코딩 | 정적 이미지, 지원 브라우저 95%+ |
| **WebP** | AVIF보다 압축률 낮지만 빠른 인코딩 | 범용, AVIF 폴백 |
| **PNG** | 무손실, 투명도 지원 | 로고, 아이콘 (SVG 우선) |
| **JPEG** | 사진에 적합, 투명도 없음 | 사진 (WebP로 교체 권장) |
| **SVG** | 벡터, 확대해도 선명 | 아이콘, 일러스트 |
| **GIF** | 애니메이션 | WebP animated 또는 video로 교체 권장 |

---

## Lazy Loading 구현

### Intersection Observer (Vanilla JS)

```typescript
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const img = entry.target as HTMLImageElement;
        img.src = img.dataset.src!;
        observer.unobserve(img);
      }
    });
  },
  { rootMargin: "200px" }  // 뷰포트 200px 전에 미리 로드
);

document.querySelectorAll("img[data-src]").forEach((img) => {
  observer.observe(img);
});
```

### next/image는 기본 lazy load

```tsx
// 기본: lazy load (뷰포트 밖이면 나중에 로드)
<Image src={img} alt="" />

// LCP 이미지는 priority로 즉시 로드
<Image src={heroImage} alt="" priority />
```

**LCP(Largest Contentful Paint)** 에 해당하는 이미지 — 보통 히어로 이미지 — 는 반드시 `priority`를 붙여야 한다. lazy load하면 LCP 점수가 크게 나빠진다.

---

## Supabase Storage + CDN 연동

Supabase Storage는 S3 호환 스토리지다. 공개 버킷의 파일은 CDN을 통해 서빙된다.

```typescript
// 이미지 URL 생성
const { data } = supabase.storage
  .from("post-images")
  .getPublicUrl("cover/my-post.webp");

// data.publicUrl = "https://xxx.supabase.co/storage/v1/object/public/post-images/cover/my-post.webp"
```

Supabase CDN 캐시 정책은 기본 `max-age=3600`이다. 더 길게 캐시하려면 Transform 옵션을 사용하거나, Cloudflare를 앞에 붙인다.

---

## 실무 체크리스트

### 배포 전 확인

- [ ] LCP 이미지에 `priority` 붙었는가?
- [ ] `sizes` prop이 실제 레이아웃과 일치하는가?
- [ ] 정적 에셋에 `Cache-Control: public, max-age=31536000, immutable` 설정됐는가?
- [ ] 이미지가 WebP 또는 AVIF로 서빙되는가? (DevTools Network 탭에서 확인)
- [ ] 뷰포트 밖 이미지가 lazy load되는가?

### 성능 측정

```bash
# Lighthouse로 이미지 최적화 점수 확인
npx lighthouse https://내사이트.com --output html

# WebPageTest로 CDN 캐시 HIT/MISS 확인
# https://www.webpagetest.org
```

---

## 정리

| 레이어 | 도구 | 전략 |
|--------|------|------|
| 브라우저 캐시 | Cache-Control 헤더 | 정적 에셋 1년, HTML no-cache |
| CDN 캐시 | Cloudflare / Vercel Edge | s-maxage, stale-while-revalidate |
| 이미지 최적화 | next/image | AVIF/WebP 자동 변환, sizes 설정 |
| 로딩 전략 | priority / lazy | LCP는 priority, 나머지는 lazy |

이미지 최적화에서 가장 중요한 두 가지: **LCP 이미지는 priority**, **나머지는 적절한 sizes와 lazy load**.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_perf);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);

RAISE NOTICE '배치3 포스트 2개 삽입 완료. author: %', author;

END $SEED3$;
