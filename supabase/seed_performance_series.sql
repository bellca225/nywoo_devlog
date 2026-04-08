-- =============================================
-- 프론트엔드 성능 최적화 시리즈 (2편)
-- =============================================

DO $PERF$
DECLARE
  author UUID;
  tag_perf UUID;
  tag_react UUID;
  tag_nextjs UUID;
  tag_js UUID;
  post_id UUID;
BEGIN

SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;
IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다.';
END IF;

INSERT INTO tags (name) VALUES ('성능최적화') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('React') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Next.js') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('JavaScript') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_perf FROM tags WHERE name = '성능최적화';
SELECT id INTO tag_react FROM tags WHERE name = 'React';
SELECT id INTO tag_nextjs FROM tags WHERE name = 'Next.js';
SELECT id INTO tag_js FROM tags WHERE name = 'JavaScript';

-- =============================================
-- 1편: 렌더링 성능
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '프론트엔드 성능 최적화 1편 — 렌더링 성능 (Core Web Vitals, React, 코드 스플리팅)',
  'frontend-performance-part1-rendering',
  'Core Web Vitals 3가지 지표 이해부터 React memo/useMemo/useCallback/lazy 실전 사용법, 번들 분석, 가상화(Virtual List)까지 — 렌더링 성능을 올리는 모든 방법을 정리했다.',
  '# 프론트엔드 성능 최적화 1편 — 렌더링 성능

> "사용자는 100ms의 지연을 느낀다. 300ms 이상이면 느리다고 판단한다. 1초가 넘으면 이탈한다."

---

## Core Web Vitals 이해

Google이 정의한 실제 사용자 경험을 측정하는 3가지 핵심 지표다. 2024년부터 검색 순위에도 영향을 준다.

### LCP (Largest Contentful Paint)

화면에서 **가장 큰 콘텐츠 요소가 렌더링되는 시점**이다. 보통 히어로 이미지나 h1 텍스트다.

```
좋음: 2.5초 이하
개선 필요: 2.5초 ~ 4.0초
나쁨: 4.0초 초과
```

**LCP를 망치는 주요 원인:**
- 히어로 이미지를 lazy load하는 실수 (`priority` 빠뜨림)
- 렌더링 블로킹 리소스 (CSS, JS)
- 느린 서버 응답 (TTFB)

### CLS (Cumulative Layout Shift)

페이지 로드 중 **레이아웃이 얼마나 흔들리는지**를 측정한다.

```
좋음: 0.1 이하
개선 필요: 0.1 ~ 0.25
나쁨: 0.25 초과
```

이미지/광고에 width/height를 안 주거나, 폰트 로드 후 텍스트가 밀리는 FOUT(Flash of Unstyled Text)가 주요 원인이다.

### INP (Interaction to Next Paint)

**모든 클릭, 탭, 키 입력에 대한 응답 시간**의 대표값이다. 2024년 FID를 대체했다.

```
좋음: 200ms 이하
개선 필요: 200ms ~ 500ms
나쁨: 500ms 초과
```

무거운 JS 실행, 긴 Task, 렌더링 블로킹이 원인이다.

---

## React 렌더링 최적화

### React가 리렌더링되는 조건

```
1. state가 변경됨
2. props가 변경됨
3. 부모 컴포넌트가 리렌더링됨 (props 변경 없어도)
4. Context 값이 변경됨
```

3번이 핵심 문제다. 부모가 리렌더링되면 자식도 무조건 리렌더링된다.

### React.memo

props가 바뀌지 않으면 리렌더링을 건너뛴다.

```typescript
// memo 없이: 부모가 리렌더링되면 항상 리렌더링
function PostCard({ post }: { post: Post }) {
  return <div>{post.title}</div>;
}

// memo로 감싸기: post prop이 바뀔 때만 리렌더링
const PostCard = memo(function PostCard({ post }: { post: Post }) {
  return <div>{post.title}</div>;
});
```

**주의:** memo는 얕은 비교(shallow comparison)를 한다.

```typescript
// 이렇게 쓰면 memo가 의미 없다
// 부모가 리렌더링될 때마다 새 객체가 만들어져서 항상 다르다고 판단
<PostCard style={{ color: "red" }} />   // 새 객체 {}
<PostCard onClick={() => {}} />         // 새 함수 () => {}
```

### useMemo — 연산 결과 메모이제이션

```typescript
// 나쁜 예: 리렌더링마다 필터링 재실행
function PostList({ posts, tag }: Props) {
  const filtered = posts.filter(p => p.tag === tag); // 매번 실행
  return <>{filtered.map(...)}</>;
}

// 좋은 예: tag나 posts가 바뀔 때만 재계산
function PostList({ posts, tag }: Props) {
  const filtered = useMemo(
    () => posts.filter(p => p.tag === tag),
    [posts, tag]
  );
  return <>{filtered.map(...)}</>;
}
```

**useMemo를 쓰면 안 되는 경우:**
- 단순 연산 (조건문, 덧셈 등) — 메모이제이션 오버헤드가 더 크다
- 의존성 배열이 매번 바뀌는 경우 — 의미 없다

### useCallback — 함수 메모이제이션

```typescript
// 나쁜 예: 리렌더링마다 새 함수 생성 → memo(PostCard) 무력화
function PostList({ posts }: Props) {
  const handleDelete = (id: string) => deletePost(id); // 새 함수

  return posts.map(post => (
    <PostCard key={post.id} post={post} onDelete={handleDelete} />
  ));
}

// 좋은 예: deletePost가 바뀔 때만 새 함수
function PostList({ posts }: Props) {
  const handleDelete = useCallback(
    (id: string) => deletePost(id),
    [deletePost]
  );

  return posts.map(post => (
    <PostCard key={post.id} post={post} onDelete={handleDelete} />
  ));
}
```

### useCallback + memo 조합

memo와 useCallback은 세트로 써야 효과가 있다.

```typescript
// 자식: memo로 감싸기
const PostCard = memo(function PostCard({
  post,
  onDelete,
}: {
  post: Post;
  onDelete: (id: string) => void;
}) {
  console.log("PostCard 렌더링:", post.id);
  return (
    <div>
      {post.title}
      <button onClick={() => onDelete(post.id)}>삭제</button>
    </div>
  );
});

// 부모: useCallback으로 함수 안정화
function PostList({ posts }: Props) {
  const handleDelete = useCallback(async (id: string) => {
    await api.deletePost(id);
  }, []); // 의존성 없으면 최초 1회만 생성

  return posts.map(post => (
    <PostCard key={post.id} post={post} onDelete={handleDelete} />
  ));
}
```

### key prop 올바르게 사용하기

```typescript
// 절대 금지: index를 key로 사용
posts.map((post, index) => <PostCard key={index} post={post} />);
// 목록 순서 바뀌면 React가 잘못 매핑 → 렌더링 버그 + 성능 저하

// 올바른 방법: 고유한 ID 사용
posts.map(post => <PostCard key={post.id} post={post} />);
```

---

## 코드 스플리팅

### 번들 분석 먼저

```bash
# Next.js
ANALYZE=true npm run build
# next.config.ts에서 @next/bundle-analyzer 설정 필요

# Vite
npx vite-bundle-visualizer
```

번들 분석 후 큰 청크를 발견하면 코드 스플리팅 대상이다.

### React.lazy + Suspense

```typescript
// 초기 번들에서 분리
const MarkdownEditor = lazy(() => import("@/components/MarkdownEditor"));
const ChartDashboard = lazy(() => import("@/components/ChartDashboard"));

function WritePage() {
  return (
    <Suspense fallback={<div>에디터 로딩 중...</div>}>
      <MarkdownEditor />
    </Suspense>
  );
}
```

`MarkdownEditor`는 페이지 첫 로드 시 받지 않고, 실제로 렌더링될 때 별도 청크로 다운로드된다.

### Next.js dynamic import

```typescript
import dynamic from "next/dynamic";

// SSR 비활성화 (브라우저 전용 라이브러리)
const ReactQuill = dynamic(() => import("react-quill"), {
  ssr: false,
  loading: () => <p>에디터 로딩 중...</p>,
});

// 조건부 로딩
const HeavyModal = dynamic(() => import("@/components/HeavyModal"));

function Page() {
  const [showModal, setShowModal] = useState(false);

  return (
    <>
      <button onClick={() => setShowModal(true)}>모달 열기</button>
      {showModal && <HeavyModal />}
      {/* HeavyModal은 showModal이 true가 될 때 처음 다운로드 */}
    </>
  );
}
```

### Route-level splitting (Next.js 자동 적용)

Next.js App Router는 각 `page.tsx`를 자동으로 별도 청크로 분리한다. 추가 설정 없이도 route 단위 코드 스플리팅이 된다.

---

## 번들 사이즈 줄이기

### Tree Shaking

사용하지 않는 코드를 번들에서 제거하는 것이다. ES Module(`import/export`)이면 번들러가 자동으로 한다.

```typescript
// 나쁜 예: lodash 전체를 import (70KB+)
import _ from "lodash";
const result = _.groupBy(arr, "category");

// 좋은 예: 필요한 함수만 (해당 함수만 번들에 포함)
import { groupBy } from "lodash-es"; // lodash-es는 ES Module
const result = groupBy(arr, "category");

// 또는 네이티브 대체
const result = Object.groupBy(arr, item => item.category); // ES2024
```

### 의존성 크기 확인

```bash
npx bundlephobia <패키지명>
# 또는 https://bundlephobia.com
```

설치 전에 패키지 크기를 확인하는 습관을 들이자.

```
moment: 72KB gzip → date-fns: 13KB gzip (필요한 함수만)
lodash: 69KB gzip → lodash-es 또는 네이티브 메서드
axios: 11KB gzip → ky(3KB) 또는 fetch 네이티브
```

### 중복 패키지 제거

```bash
npx dedupe           # npm
pnpm dedupe          # pnpm
```

---

## Virtual List (가상화)

1만 개의 DOM 노드를 한 번에 렌더링하면 브라우저가 버벅인다. 가상화는 **화면에 보이는 것만 렌더링**한다.

```typescript
// @tanstack/react-virtual 사용
import { useVirtualizer } from "@tanstack/react-virtual";

function VirtualPostList({ posts }: { posts: Post[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: posts.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80, // 각 아이템의 추정 높이(px)
    overscan: 5, // 뷰포트 밖 미리 렌더링할 아이템 수
  });

  return (
    <div
      ref={parentRef}
      style={{ height: "600px", overflow: "auto" }}
    >
      {/* 전체 스크롤 높이 유지 */}
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map(virtualItem => (
          <div
            key={virtualItem.key}
            style={{
              position: "absolute",
              top: virtualItem.start,
              left: 0,
              width: "100%",
              height: virtualItem.size,
            }}
          >
            <PostCard post={posts[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

10,000개 리스트도 항상 화면에 보이는 10~20개만 DOM에 존재한다.

---

## Long Task 분산

INP 악화의 주범은 메인 스레드를 오래 점유하는 **Long Task(50ms 이상)**다.

```typescript
// 나쁜 예: 무거운 연산으로 메인 스레드 블로킹
function processLargeDataset(data: Item[]) {
  return data.map(item => heavyTransform(item)); // 1초 이상 걸릴 수 있음
}

// 좋은 예: scheduler.yield()로 제어권 반환 (Chrome 115+)
async function processLargeDataset(data: Item[]) {
  const results: Item[] = [];
  for (let i = 0; i < data.length; i++) {
    results.push(heavyTransform(data[i]));

    // 매 50개마다 브라우저에 제어권 반환
    if (i % 50 === 0 && "scheduler" in window) {
      await window.scheduler.yield();
    }
  }
  return results;
}

// 대안: Web Worker로 분리
const worker = new Worker(new URL("./worker.ts", import.meta.url));
worker.postMessage({ data: largeData });
worker.onmessage = (e) => setResult(e.data);
```

---

## React DevTools Profiler 사용법

1. React DevTools 설치 (Chrome 확장)
2. Profiler 탭 → Record 클릭
3. 문제가 생기는 인터랙션 실행
4. Record 중지
5. 각 컴포넌트의 렌더링 시간과 이유 확인

**Flamegraph**에서 회색은 리렌더링 안 됨, 노란색/빨간색은 리렌더링됨을 의미한다. 예상보다 자주 리렌더링되는 컴포넌트를 찾아서 memo/useCallback 적용 여부를 결정한다.

---

## 정리

| 문제 | 원인 | 해결 |
|------|------|------|
| LCP 느림 | 히어로 이미지 lazy load | priority 추가 |
| CLS 발생 | 이미지 크기 미지정 | width/height 명시 |
| INP 느림 | Long Task | scheduler.yield / Web Worker |
| 불필요한 리렌더링 | 부모 리렌더링 전파 | memo + useCallback |
| 번들 과대 | 미사용 코드 포함 | Tree shaking + 번들 분석 |
| 초기 로딩 느림 | 거대한 번들 | 코드 스플리팅 |
| 긴 목록 렌더링 느림 | 모든 DOM 동시 생성 | Virtual List |

2편에서는 네트워크 레이어 최적화 — 프리로드, 폰트, CSS, 서비스 워커, 성능 측정 도구를 다룬다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_perf);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_react);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);

-- =============================================
-- 2편: 네트워크/로딩 성능
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '프론트엔드 성능 최적화 2편 — 네트워크/로딩 성능 (프리로드, 폰트, CSS, 서비스 워커)',
  'frontend-performance-part2-network',
  '리소스 힌트(preload/prefetch/preconnect), 폰트 최적화, Critical CSS, 서비스 워커 캐싱 전략, HTTP/2, Brotli 압축, 성능 측정 도구까지 — 로딩 성능을 올리는 모든 방법을 정리했다.',
  '# 프론트엔드 성능 최적화 2편 — 네트워크/로딩 성능

> 가장 빠른 요청은 보내지 않는 요청이다. 그 다음은 캐시에서 오는 요청이다.

---

## 리소스 힌트 (Resource Hints)

브라우저에게 "이 리소스가 곧 필요할 것 같아"라고 미리 알려주는 HTML 힌트들이다.

### preload — 현재 페이지에서 곧 필요한 리소스

```html
<!-- 폰트: 렌더링 전에 미리 받아두기 -->
<link rel="preload" href="/fonts/Pretendard.woff2" as="font" type="font/woff2" crossorigin>

<!-- LCP 이미지: 파싱 기다리지 않고 즉시 다운로드 시작 -->
<link rel="preload" href="/hero.webp" as="image">

<!-- 중요한 스크립트 -->
<link rel="preload" href="/critical.js" as="script">
```

`preload`는 현재 페이지 탐색에서 **반드시 필요한** 리소스에 사용한다. 너무 많이 쓰면 오히려 다른 중요 리소스를 밀어내 역효과가 난다.

### prefetch — 다음 페이지에서 필요한 리소스

```html
<!-- 사용자가 다음에 방문할 가능성이 높은 페이지의 리소스 -->
<link rel="prefetch" href="/about/bundle.js" as="script">
```

브라우저가 **유휴 상태일 때** 미리 받아 캐시에 저장한다. 우선순위가 낮아 현재 페이지 성능에 영향이 없다.

### preconnect — API 서버 연결 미리 맺기

```html
<!-- Supabase API와 미리 TCP + TLS 핸드셰이크 -->
<link rel="preconnect" href="https://pykjsqsfdnhqkrmwuusv.supabase.co">

<!-- 폰트 CDN -->
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
```

DNS 조회 + TCP 연결 + TLS 협상을 미리 완료한다. 첫 API 요청이 수백 ms 빨라진다.

### Next.js에서 리소스 힌트

```typescript
// app/layout.tsx
export default function RootLayout() {
  return (
    <html>
      <head>
        <link rel="preconnect" href="https://pykjsqsfdnhqkrmwuusv.supabase.co" />
      </head>
      <body>{children}</body>
    </html>
  );
}

// next/image는 priority prop으로 자동 preload
<Image src="/hero.webp" priority alt="히어로" width={1200} height={600} />
```

---

## 폰트 최적화

폰트는 CLS와 LCP에 모두 영향을 준다.

### FOUT vs FOIT

```
FOUT (Flash of Unstyled Text): 시스템 폰트로 먼저 보이다가 웹폰트로 교체
FOIT (Flash of Invisible Text): 폰트 로드까지 텍스트가 안 보임
```

### font-display: swap

```css
@font-face {
  font-family: "Pretendard";
  src: url("/fonts/Pretendard.woff2") format("woff2");
  font-display: swap; /* 시스템 폰트로 먼저 보여주고, 로드되면 교체 */
}
```

`optional`: 캐시에 없으면 아예 웹폰트 로드 안 함 (CLS 완전 방지, 첫 방문은 시스템 폰트)
`swap`: 즉시 시스템 폰트 → 로드 후 교체 (FOUT 발생하지만 LCP 보호)

### Next.js next/font

```typescript
// 빌드 타임에 폰트를 다운로드, 자동 최적화, CORS 문제 없음
import { Geist } from "next/font/google";
import localFont from "next/font/local";

// Google Fonts
const geist = Geist({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-geist",
});

// 로컬 폰트 (Pretendard 등)
const pretendard = localFont({
  src: [
    { path: "../public/fonts/Pretendard-Regular.woff2", weight: "400" },
    { path: "../public/fonts/Pretendard-Bold.woff2", weight: "700" },
  ],
  display: "swap",
  variable: "--font-pretendard",
});
```

next/font는 폰트를 자체 도메인에서 서빙해 preconnect도 필요 없고, `size-adjust`로 CLS도 자동 최소화한다.

### 폰트 서브셋

한글 폰트는 수천 개의 글자를 포함해 파일이 크다. 사용하는 글자만 추출한 서브셋을 사용한다.

Pretendard 공식 배포본은 이미 서브셋(Dynamic Subset)이 포함되어 있다. Unicode-range로 사용된 글자만 받는다.

---

## Critical CSS (인라인 CSS)

**위에 보이는 영역(Above the fold)**을 렌더링하는 데 필요한 CSS를 HTML에 인라인으로 포함한다. 외부 CSS 파일 로드를 기다리지 않고 즉시 렌더링된다.

```html
<head>
  <!-- Critical CSS: 인라인으로 즉시 적용 -->
  <style>
    body { margin: 0; font-family: Pretendard, sans-serif; }
    header { height: 64px; background: #000; }
    .hero { min-height: 400px; }
  </style>

  <!-- 나머지 CSS: 비동기로 로드 -->
  <link rel="preload" href="/styles.css" as="style" onload="this.onload=null;this.rel=''stylesheet''">
  <noscript><link rel="stylesheet" href="/styles.css"></noscript>
</head>
```

Next.js + Tailwind를 쓰면 사용된 클래스만 번들에 포함되므로 CSS가 이미 작다. Critical CSS를 별도로 추출할 필요가 줄어든다.

---

## 이미지 최적화 (핵심 요약)

```typescript
// 1. next/image 사용: 자동 WebP/AVIF, lazy load, CLS 방지
<Image src={img} alt="" width={800} height={600} />

// 2. LCP 이미지는 priority
<Image src={heroImg} alt="" priority />

// 3. sizes로 정확한 이미지 크기 지시
<Image
  src={img}
  fill
  sizes="(max-width: 768px) 100vw, 50vw"
  alt=""
/>

// 4. 레이아웃 밖 이미지: loading="lazy"는 브라우저 기본값
// → next/image를 쓰면 자동 처리
```

---

## HTTP/2와 압축

### HTTP/2 다중화 (Multiplexing)

HTTP/1.1: 동시 요청 6개 제한, 요청마다 새 연결
HTTP/2: 하나의 연결로 동시에 수십 개 요청, 헤더 압축

Vercel, Cloudflare, AWS CloudFront는 기본으로 HTTP/2를 사용한다. 별도 설정 없이 적용된다.

### Brotli 압축

```
Gzip: 평균 70% 압축
Brotli: 평균 80% 압축 (텍스트 파일에서 Gzip 대비 20~26% 더 작음)
```

Vercel과 대부분의 CDN은 Brotli를 자동 적용한다. 직접 Nginx를 운영한다면:

```nginx
# nginx.conf
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/javascript application/json;
```

---

## 서비스 워커 캐싱 전략

서비스 워커는 브라우저와 네트워크 사이에서 요청을 가로채 캐싱을 제어한다.

### Workbox로 서비스 워커 구성

```bash
npm install -D workbox-cli
```

### 캐싱 전략 선택

```typescript
import { registerRoute } from "workbox-routing";
import { CacheFirst, NetworkFirst, StaleWhileRevalidate } from "workbox-strategies";

// 정적 에셋: 캐시 우선 (변경 없음)
registerRoute(
  ({ request }) => request.destination === "image",
  new CacheFirst({
    cacheName: "images",
    plugins: [
      new ExpirationPlugin({ maxEntries: 50, maxAgeSeconds: 30 * 24 * 60 * 60 }),
    ],
  })
);

// API 응답: 네트워크 우선 (최신 데이터), 실패 시 캐시
registerRoute(
  ({ url }) => url.pathname.startsWith("/api/"),
  new NetworkFirst({
    cacheName: "api-cache",
    networkTimeoutSeconds: 3,
  })
);

// 페이지: Stale-While-Revalidate (빠른 응답 + 백그라운드 갱신)
registerRoute(
  ({ request }) => request.mode === "navigate",
  new StaleWhileRevalidate({ cacheName: "pages" })
);
```

### Next.js에서 PWA (next-pwa)

```bash
npm install next-pwa
```

```typescript
// next.config.ts
import withPWA from "next-pwa";

export default withPWA({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/.*\.supabase\.co\/rest\/.*/,
      handler: "NetworkFirst",
      options: { cacheName: "supabase-api" },
    },
  ],
})(nextConfig);
```

---

## 성능 측정 도구

### 1. Lighthouse (Chrome DevTools)

```bash
# CLI로 자동화
npx lighthouse https://내사이트.com \
  --output=json \
  --output-path=./lighthouse-report.json
```

Performance 점수 100점이 목표가 아니다. LCP, CLS, INP 각각의 수치를 확인하고 "좋음" 기준 이내로 맞추는 것이 목표다.

### 2. Web Vitals API (실제 사용자 데이터)

```typescript
// next.js app/layout.tsx
import { SpeedInsights } from "@vercel/speed-insights/next";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />  {/* 실제 사용자의 Web Vitals 수집 */}
      </body>
    </html>
  );
}
```

또는 직접 수집:

```typescript
import { onLCP, onCLS, onINP } from "web-vitals";

onLCP(({ value, rating }) => {
  console.log(`LCP: ${value}ms (${rating})`);
  // analytics로 전송
  sendToAnalytics({ metric: "LCP", value, rating });
});

onCLS(({ value }) => sendToAnalytics({ metric: "CLS", value }));
onINP(({ value }) => sendToAnalytics({ metric: "INP", value }));
```

### 3. Performance API

```typescript
// 특정 코드 실행 시간 측정
performance.mark("filter-start");
const filtered = posts.filter(p => p.tag === tag);
performance.mark("filter-end");

performance.measure("filter", "filter-start", "filter-end");
const measure = performance.getEntriesByName("filter")[0];
console.log(`필터링: ${measure.duration.toFixed(2)}ms`);
```

### 4. Chrome DevTools Performance 탭

1. Performance 탭 → Record
2. 문제 있는 인터랙션 실행
3. Record 중지
4. **Main Thread**에서 Long Task(빨간 삼각형) 찾기
5. 해당 Task를 클릭해서 어떤 함수가 오래 걸리는지 확인

---

## 성능 예산 (Performance Budget)

팀에서 성능 기준을 미리 정해두고, CI에서 초과 시 배포를 막는다.

```javascript
// lighthouserc.js
module.exports = {
  ci: {
    assert: {
      assertions: {
        "categories:performance": ["error", { minScore: 0.9 }],
        "first-contentful-paint": ["error", { maxNumericValue: 2000 }],
        "largest-contentful-paint": ["error", { maxNumericValue: 2500 }],
        "cumulative-layout-shift": ["error", { maxNumericValue: 0.1 }],
        "total-byte-weight": ["error", { maxNumericValue: 500000 }], // 500KB
      },
    },
  },
};
```

```yaml
# .github/workflows/lighthouse.yml
- name: Lighthouse CI
  run: npx lhci autorun
```

---

## 전체 최적화 우선순위

처음 성능 최적화를 시작할 때 순서:

```
1. Lighthouse 실행 → 현재 점수와 문제 파악
2. LCP 이미지 priority 확인 (가장 임팩트 큼)
3. 불필요한 번들 크기 제거 (bundle analyzer)
4. preconnect로 중요 도메인 미리 연결
5. 폰트 최적화 (next/font 사용)
6. React 리렌더링 확인 (DevTools Profiler)
7. 긴 목록은 가상화 적용
8. 서비스 워커로 정적 에셋 캐싱
```

**작은 것부터 측정하고 개선하자.** 측정 없는 최적화는 추측이다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_perf);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_js);

RAISE NOTICE '성능 최적화 시리즈 2편 삽입 완료. author: %', author;

END $PERF$;
