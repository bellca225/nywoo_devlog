-- =============================================
-- 테스트 코드 시리즈 (3편)
-- =============================================

DO $TEST$
DECLARE
  author UUID;
  tag_testing UUID;
  tag_js UUID;
  tag_ts UUID;
  tag_nextjs UUID;
  tag_node UUID;
  post_id UUID;
BEGIN

SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;
IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다.';
END IF;

INSERT INTO tags (name) VALUES ('테스팅') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('JavaScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('TypeScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Next.js') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Node.js') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_testing FROM tags WHERE name = '테스팅';
SELECT id INTO tag_js FROM tags WHERE name = 'JavaScript';
SELECT id INTO tag_ts FROM tags WHERE name = 'TypeScript';
SELECT id INTO tag_nextjs FROM tags WHERE name = 'Next.js';
SELECT id INTO tag_node FROM tags WHERE name = 'Node.js';

-- =============================================
-- 1편: 테스트 기초
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '테스트 코드 완전 정복 1편 — 기초 개념, 종류, Jest 핵심',
  'testing-fundamentals-part1',
  '테스트를 왜 써야 하는지부터 단위/통합/E2E 테스트의 차이, 테스트 피라미드, Mock/Stub/Spy의 구분, Jest 핵심 문법까지 — 테스트의 출발점을 완전히 정리했다.',
  '# 테스트 코드 완전 정복 1편 — 기초 개념, 종류, Jest 핵심

> 테스트 코드를 처음 배울 때 가장 큰 장벽은 "뭘 테스트해야 하는가"다. 도구보다 개념이 먼저다.

---

## 왜 테스트를 써야 하는가?

### 테스트 없는 개발의 현실

```
기능 A 추가 → 수동 확인 → 배포
→ 2주 뒤 기능 B 추가 → 기능 A가 깨짐 → 배포 후 발견 → 장애
```

규모가 커질수록 "내 코드가 다른 코드를 망가뜨리지 않는다"는 확신이 없어진다.

### 테스트가 있는 개발

```
기능 A 추가 + 테스트 작성 → CI 통과 → 배포
→ 2주 뒤 기능 B 추가 → 테스트 실패 → 즉시 발견 → 배포 전 수정
```

테스트는 **변경에 대한 안전망**이다. 리팩토링도, 의존성 업그레이드도 두렵지 않게 만든다.

### 테스트가 주는 부수 효과

- **설계 개선**: 테스트하기 어려운 코드 = 의존성이 강하게 결합된 코드. 테스트를 쓰다 보면 자연스럽게 좋은 설계로 수렴한다.
- **문서화**: 테스트는 "이 함수가 어떻게 동작해야 하는가"를 코드로 기술한 살아있는 문서다.
- **배포 자신감**: CI에서 테스트가 통과하면 배포할 수 있다는 근거가 생긴다.

---

## 테스트의 종류

### 단위 테스트 (Unit Test)

가장 작은 단위 — 함수 하나, 클래스 하나 — 를 **고립**시켜 테스트한다.

```typescript
// 테스트 대상
function formatPrice(price: number, currency = "KRW"): string {
  return `${price.toLocaleString()}${currency}`;
}

// 단위 테스트
test("가격을 천 단위 구분자와 통화로 포맷한다", () => {
  expect(formatPrice(15000)).toBe("15,000KRW");
  expect(formatPrice(15000, "USD")).toBe("15,000USD");
});
```

**특징:** 빠름 (ms 단위), 외부 의존성 없음, 가장 많이 써야 함

### 통합 테스트 (Integration Test)

여러 모듈이 **함께 동작하는 것**을 테스트한다. API 레이어 + DB, 컴포넌트 + API 호출 등.

```typescript
// API 라우터 + 실제 DB 로직이 함께 동작하는지 테스트
test("POST /api/posts — 새 포스트를 생성한다", async () => {
  const res = await request(app)
    .post("/api/posts")
    .send({ title: "새 글", content: "내용" })
    .set("Authorization", `Bearer ${token}`);

  expect(res.status).toBe(201);
  expect(res.body.title).toBe("새 글");

  // DB에 실제로 저장됐는지 확인
  const post = await db.posts.findById(res.body.id);
  expect(post).toBeDefined();
});
```

**특징:** 단위보다 느림, 실제 환경에 가까움, 핵심 흐름 검증

### E2E 테스트 (End-to-End Test)

실제 브라우저로 **사용자 시나리오 전체**를 실행한다.

```typescript
// Playwright로 로그인 → 글 작성 → 목록 확인 시나리오
test("사용자가 로그인 후 포스트를 작성할 수 있다", async ({ page }) => {
  await page.goto("/login");
  await page.fill("[name=email]", "admin@example.com");
  await page.fill("[name=password]", "password");
  await page.click("button[type=submit]");

  await page.goto("/blog/write");
  await page.fill("[name=title]", "E2E 테스트 포스트");
  await page.click("button[type=submit]");

  await expect(page.locator("h1")).toContainText("E2E 테스트 포스트");
});
```

**특징:** 가장 느림, 가장 실제에 가까움, 적게 써야 함

---

## 테스트 피라미드

```
        /\
       /E2E\        ← 적게 (비싸고 느림)
      /------\
     /통합 테스트\   ← 중간
    /------------\
   /  단위 테스트  \  ← 많이 (빠르고 싸고 안정적)
  /________________\
```

마틴 파울러가 제안한 개념. 피라미드 상단으로 갈수록:
- 실행 속도가 느려짐
- 유지보수 비용이 높아짐
- 실패 시 원인 파악이 어려워짐
- 테스트 환경 구성이 복잡해짐

**실무 비율:** 단위 70% : 통합 20% : E2E 10% 정도가 일반적이다.

### 아이스크림 콘 안티패턴

```
  /____________\
 /   E2E 가득   \  ← 잘못된 방식
/----------------\
\   통합 조금    /
 \______________/
      단위 없음
```

E2E만 잔뜩 있는 프로젝트. 느리고, 플레이키(flaky)하고, 디버깅이 지옥이다.

---

## 핵심 용어

### Mock

**외부 의존성 전체를 가짜로 대체**하는 것이다.

```typescript
// fetch를 통째로 mock
global.fetch = jest.fn().mockResolvedValue({
  json: () => Promise.resolve({ id: 1, title: "Mock 포스트" }),
  ok: true,
});
```

### Stub

**미리 정해진 값을 반환**하도록 하는 것이다. Mock보다 단순하다.

```typescript
const getUserStub = jest.fn().mockReturnValue({ id: "1", name: "nywoo" });
```

### Spy

**실제 구현을 유지**하면서 호출 여부, 인자, 횟수를 **감시**한다.

```typescript
const consoleSpy = jest.spyOn(console, "error");

doSomething(); // 내부에서 console.error 호출

expect(consoleSpy).toHaveBeenCalledWith("예상된 에러 메시지");
consoleSpy.mockRestore(); // 원래대로 복원
```

### Fixture

테스트에서 반복 사용하는 **고정 데이터**다.

```typescript
// fixtures/posts.ts
export const postFixture = {
  id: "test-id-123",
  title: "테스트 포스트",
  slug: "test-post",
  published: true,
  created_at: "2026-01-01T00:00:00Z",
};
```

---

## Jest 핵심 문법

### 설치

```bash
npm install -D jest @types/jest ts-jest
```

### jest.config.ts

```typescript
import type { Config } from "jest";

export default {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/__tests__/**/*.ts", "**/*.test.ts"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/src/$1",
  },
} satisfies Config;
```

### describe / test / it

```typescript
describe("formatPrice", () => {
  it("기본 통화는 KRW다", () => {
    expect(formatPrice(1000)).toBe("1,000KRW");
  });

  it("0원은 0KRW를 반환한다", () => {
    expect(formatPrice(0)).toBe("0KRW");
  });

  describe("음수 처리", () => {
    it("음수 가격은 에러를 던진다", () => {
      expect(() => formatPrice(-1)).toThrow("가격은 0 이상이어야 합니다");
    });
  });
});
```

### Matchers

```typescript
// 동등성
expect(result).toBe(42);              // 원시값 비교 (===)
expect(result).toEqual({ id: 1 });   // 객체 깊은 비교
expect(result).toStrictEqual({});    // undefined 프로퍼티까지 비교

// 참/거짓
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();

// 숫자
expect(result).toBeGreaterThan(10);
expect(result).toBeCloseTo(0.3, 5);  // 부동소수점 비교

// 문자열
expect(str).toContain("hello");
expect(str).toMatch(/^\d+$/);

// 배열
expect(arr).toHaveLength(3);
expect(arr).toContain("item");
expect(arr).toEqual(expect.arrayContaining(["a", "b"]));

// 에러
expect(() => fn()).toThrow();
expect(() => fn()).toThrow("에러 메시지");
expect(() => fn()).toThrow(CustomError);

// 비동기
await expect(asyncFn()).resolves.toBe("결과");
await expect(asyncFn()).rejects.toThrow("에러");
```

### 비동기 테스트

```typescript
// async/await (권장)
test("API 데이터를 받아온다", async () => {
  const data = await fetchPosts();
  expect(data).toHaveLength(3);
});

// Promise 반환
test("Promise 테스트", () => {
  return fetchPosts().then(data => {
    expect(data).toHaveLength(3);
  });
});
```

### Setup / Teardown

```typescript
describe("UserService", () => {
  let db: Database;

  beforeAll(async () => {
    db = await Database.connect();  // 전체 suite에서 1번
  });

  afterAll(async () => {
    await db.close();
  });

  beforeEach(() => {
    db.clear();  // 각 테스트 전 초기화
  });

  afterEach(() => {
    jest.clearAllMocks();  // mock 상태 초기화
  });
});
```

### jest.fn() 활용

```typescript
const mockFn = jest.fn();

mockFn("a", "b");
mockFn("c");

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(2);
expect(mockFn).toHaveBeenCalledWith("a", "b");
expect(mockFn).toHaveBeenLastCalledWith("c");

// 반환값 설정
mockFn.mockReturnValue(42);
mockFn.mockReturnValueOnce("첫 번째만");
mockFn.mockResolvedValue({ id: 1 });   // async
mockFn.mockRejectedValue(new Error()); // async 에러

// 구현 대체
mockFn.mockImplementation((x: number) => x * 2);
```

### 모듈 Mock

```typescript
// 모듈 전체 mock
jest.mock("@/lib/supabase/client");

// 특정 함수만 mock
jest.mock("@/lib/email", () => ({
  sendEmail: jest.fn().mockResolvedValue({ success: true }),
  // 나머지는 실제 구현
  ...jest.requireActual("@/lib/email"),
}));
```

---

## 좋은 테스트의 조건 (F.I.R.S.T)

| 원칙 | 의미 |
|------|------|
| **F**ast | 빠르게 실행된다 |
| **I**solated | 다른 테스트에 의존하지 않는다 |
| **R**epeatable | 어떤 환경에서도 같은 결과 |
| **S**elf-validating | 통과/실패를 자동으로 판단 |
| **T**imely | 코드 작성과 동시에 (또는 직전에) 작성 |

---

## 정리

테스트를 처음 시작할 때 가장 중요한 것 세 가지:

1. **단위 테스트부터 시작** — 함수 하나를 테스트하는 것부터
2. **외부 의존성은 mock으로 제어** — DB, API, 파일시스템
3. **테스트가 깨지는 상황을 먼저 생각** — happy path보다 edge case

2편에서는 React 컴포넌트와 API 호출을 테스트하는 프론트엔드 실전을 다룬다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_testing);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_js);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

-- =============================================
-- 2편: 프론트엔드 테스트 실전
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '테스트 코드 완전 정복 2편 — 프론트엔드 테스트 실전 (RTL, MSW, Playwright)',
  'testing-fundamentals-part2-frontend',
  'React Testing Library로 컴포넌트 테스트하기, userEvent로 인터랙션 시뮬레이션, MSW로 API 모킹, Playwright로 E2E — 프론트엔드 테스트의 전체 흐름을 실전 코드로 정리했다.',
  '# 테스트 코드 완전 정복 2편 — 프론트엔드 테스트 실전

> 컴포넌트 테스트의 황금률: **구현이 아닌 동작을 테스트하라.**

---

## React Testing Library 철학

**@testing-library/react** (RTL)는 DOM 기반 테스트 라이브러리다. 핵심 철학이 있다.

> "The more your tests resemble the way your software is used, the more confidence they can give you."

즉, 사용자가 실제로 보고 클릭하는 방식으로 테스트해야 한다.

### Enzyme vs RTL

```typescript
// Enzyme (구식) — 구현 세부사항 테스트
wrapper.find("Button").prop("onClick")();
expect(wrapper.state("isOpen")).toBe(true);

// RTL (현대) — 동작 테스트
await userEvent.click(screen.getByRole("button", { name: "메뉴 열기" }));
expect(screen.getByRole("navigation")).toBeVisible();
```

Enzyme은 내부 state, props를 직접 검사한다. 리팩토링하면 테스트가 깨진다. RTL은 사용자 관점에서 DOM을 검사한다. 리팩토링해도 동작이 같으면 테스트가 통과한다.

---

## 설치

```bash
npm install -D @testing-library/react @testing-library/user-event @testing-library/jest-dom jest jest-environment-jsdom
```

### jest.setup.ts

```typescript
import "@testing-library/jest-dom";
```

### jest.config.ts

```typescript
export default {
  testEnvironment: "jsdom",
  setupFilesAfterFramework: ["<rootDir>/jest.setup.ts"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/src/$1",
    "\\.(css|scss|svg)$": "identity-obj-proxy",
  },
};
```

---

## screen 쿼리 완전 정리

RTL에서 요소를 찾는 방법이 다양하다. **우선순위가 있다.**

### 쿼리 우선순위 (높음 → 낮음)

```typescript
// 1순위: 접근성 기반 (모든 사용자가 접근 가능한 것)
screen.getByRole("button", { name: "제출" });
screen.getByLabelText("이메일");
screen.getByPlaceholderText("이메일을 입력하세요");
screen.getByText("로그인");

// 2순위: 시맨틱
screen.getByAltText("프로필 사진");
screen.getByTitle("닫기");

// 3순위: Test ID (최후의 수단)
screen.getByTestId("submit-button"); // data-testid 속성 사용
```

`getByRole`이 1순위인 이유: 접근성 트리 기반이라 스크린 리더 사용자가 보는 것과 동일하게 요소를 찾는다. 자연스럽게 접근성 개선도 된다.

### get vs query vs find

```typescript
// getBy: 없으면 즉시 에러 — 있어야 하는 요소
screen.getByRole("heading");

// queryBy: 없으면 null 반환 — 없어야 하는 요소 확인
expect(screen.queryByText("에러 메시지")).not.toBeInTheDocument();

// findBy: 비동기 대기 (기본 1000ms) — 나중에 나타나는 요소
await screen.findByText("로딩 완료");
```

---

## 컴포넌트 테스트 실전

### 기본 렌더링 테스트

```typescript
// components/PostCard.tsx
interface Props {
  title: string;
  summary: string;
  tag: string;
}

export function PostCard({ title, summary, tag }: Props) {
  return (
    <article>
      <span className="tag">{tag}</span>
      <h2>{title}</h2>
      <p>{summary}</p>
    </article>
  );
}
```

```typescript
// components/PostCard.test.tsx
import { render, screen } from "@testing-library/react";
import { PostCard } from "./PostCard";

describe("PostCard", () => {
  const defaultProps = {
    title: "Jest 테스트 작성법",
    summary: "Jest를 사용해 테스트를 작성하는 방법을 알아봅니다.",
    tag: "테스팅",
  };

  it("제목, 요약, 태그를 렌더링한다", () => {
    render(<PostCard {...defaultProps} />);

    expect(screen.getByRole("heading", { name: "Jest 테스트 작성법" })).toBeInTheDocument();
    expect(screen.getByText("Jest를 사용해 테스트를 작성하는 방법을 알아봅니다.")).toBeInTheDocument();
    expect(screen.getByText("테스팅")).toBeInTheDocument();
  });
});
```

### 인터랙션 테스트 (userEvent)

```typescript
import userEvent from "@testing-library/user-event";

// components/SearchInput.test.tsx
describe("SearchInput", () => {
  it("입력값이 바뀌면 onChange가 호출된다", async () => {
    const user = userEvent.setup();
    const handleChange = jest.fn();

    render(<SearchInput onChange={handleChange} />);

    await user.type(screen.getByRole("searchbox"), "react");

    expect(handleChange).toHaveBeenLastCalledWith("react");
  });

  it("폼 제출 시 onSearch가 호출된다", async () => {
    const user = userEvent.setup();
    const handleSearch = jest.fn();

    render(<SearchInput onSearch={handleSearch} />);

    await user.type(screen.getByRole("searchbox"), "react");
    await user.keyboard("{Enter}");

    expect(handleSearch).toHaveBeenCalledWith("react");
  });
});
```

`userEvent`는 `fireEvent`보다 실제 사용자 행동에 가깝다. `type`은 문자를 하나씩 입력하고, 각 keystroke에 대한 이벤트를 모두 발생시킨다.

### 비동기 컴포넌트 테스트

```typescript
// 로딩 → 데이터 표시 흐름
describe("PostList", () => {
  it("로딩 후 포스트 목록을 표시한다", async () => {
    render(<PostList />);

    // 로딩 상태
    expect(screen.getByText("로딩 중...")).toBeInTheDocument();

    // 데이터 로드 후 (MSW가 응답)
    await screen.findByText("첫 번째 포스트");
    expect(screen.getByText("두 번째 포스트")).toBeInTheDocument();
    expect(screen.queryByText("로딩 중...")).not.toBeInTheDocument();
  });

  it("API 에러 시 에러 메시지를 표시한다", async () => {
    // 이 테스트에서만 에러 응답으로 오버라이드
    server.use(
      http.get("/api/posts", () => {
        return HttpResponse.error();
      })
    );

    render(<PostList />);

    await screen.findByText("데이터를 불러오는 데 실패했습니다.");
  });
});
```

---

## MSW (Mock Service Worker)

MSW는 Service Worker를 이용해 **네트워크 레이어에서 요청을 가로챈다**. fetch를 직접 mock하는 것보다 훨씬 실제 환경에 가깝다.

### 설치 및 설정

```bash
npm install -D msw
```

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/posts", ({ request }) => {
    const url = new URL(request.url);
    const tag = url.searchParams.get("tag");

    const posts = [
      { id: "1", title: "Jest 완전 정복", tag: "테스팅" },
      { id: "2", title: "React 상태관리", tag: "React" },
    ];

    const filtered = tag ? posts.filter(p => p.tag === tag) : posts;
    return HttpResponse.json(filtered);
  }),

  http.post("/api/posts", async ({ request }) => {
    const body = await request.json() as Record<string, unknown>;
    return HttpResponse.json({ id: "new-id", ...body }, { status: 201 });
  }),

  http.delete("/api/posts/:id", ({ params }) => {
    return HttpResponse.json({ deleted: params.id });
  }),
];
```

```typescript
// src/mocks/server.ts
import { setupServer } from "msw/node";
import { handlers } from "./handlers";
export const server = setupServer(...handlers);
```

```typescript
// jest.setup.ts
import { server } from "./src/mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

`onUnhandledRequest: "error"` — mock에 정의되지 않은 요청이 오면 에러를 던진다. 의도치 않은 네트워크 요청을 방지한다.

---

## 공통 renderWithProviders 유틸리티

TanStack Query, Zustand, Router 등 Provider가 많을 때 테스트마다 감싸는 것은 중복이다.

```typescript
// src/test-utils/index.tsx
import { render, type RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";

function createQueryClient() {
  return new QueryClient({
    defaultOptions: { queries: { retry: false, gcTime: 0 } },
  });
}

interface WrapperProps {
  children: React.ReactNode;
  initialRoute?: string;
}

function Providers({ children, initialRoute = "/" }: WrapperProps) {
  const queryClient = createQueryClient();
  return (
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[initialRoute]}>
        {children}
      </MemoryRouter>
    </QueryClientProvider>
  );
}

export function renderWithProviders(
  ui: React.ReactElement,
  options?: Omit<RenderOptions, "wrapper"> & { initialRoute?: string }
) {
  const { initialRoute, ...renderOptions } = options ?? {};
  return render(ui, {
    wrapper: ({ children }) => (
      <Providers initialRoute={initialRoute}>{children}</Providers>
    ),
    ...renderOptions,
  });
}

// re-export everything
export * from "@testing-library/react";
```

---

## Playwright로 E2E 테스트

### 설치

```bash
npm install -D @playwright/test
npx playwright install
```

### playwright.config.ts

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: "http://localhost:3000",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

### Page Object Model (POM)

E2E 테스트에서 셀렉터를 테스트 코드에 직접 쓰면 유지보수가 힘들다. POM 패턴으로 분리한다.

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from "@playwright/test";

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel("이메일");
    this.passwordInput = page.getByLabel("비밀번호");
    this.submitButton = page.getByRole("button", { name: "로그인" });
    this.errorMessage = page.getByRole("alert");
  }

  async goto() {
    await this.page.goto("/login");
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

```typescript
// e2e/auth.test.ts
import { test, expect } from "@playwright/test";
import { LoginPage } from "./pages/LoginPage";

test.describe("인증", () => {
  test("올바른 자격증명으로 로그인 성공", async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login("admin@example.com", "password");

    await expect(page).toHaveURL("/dashboard");
  });

  test("잘못된 비밀번호로 에러 표시", async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login("admin@example.com", "wrong-password");

    await expect(loginPage.errorMessage).toContainText("이메일 또는 비밀번호가 올바르지 않습니다");
  });
});
```

### Playwright 유용한 기능

```typescript
// 네트워크 가로채기
await page.route("/api/posts", async (route) => {
  await route.fulfill({
    json: [{ id: "1", title: "Mock 포스트" }],
  });
});

// 스크린샷 비교 (Visual Regression)
await expect(page).toHaveScreenshot("homepage.png");

// 모바일 뷰포트
test("모바일에서 메뉴가 동작한다", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  // ...
});

// 병렬 실행 설정
test.describe.configure({ mode: "parallel" });
```

---

## 정리

| 도구 | 역할 |
|------|------|
| Jest | 테스트 러너, assertion, mock |
| React Testing Library | 컴포넌트 렌더링, DOM 쿼리 |
| userEvent | 실제 사용자 인터랙션 시뮬레이션 |
| MSW | 네트워크 요청 mock |
| Playwright | E2E, 브라우저 자동화 |

3편에서는 백엔드 API 테스트, DB 테스트, 그리고 Vitest와 Contract Testing 등 최신 트렌드를 다룬다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_testing);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_nextjs);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

-- =============================================
-- 3편: 백엔드 테스트 + 최신 트렌드
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '테스트 코드 완전 정복 3편 — 백엔드 테스트 실전 + 최신 트렌드 (Vitest, Contract Testing)',
  'testing-fundamentals-part3-backend',
  'Supertest로 API 테스트, 실제 DB vs 인메모리 DB 전략, 트랜잭션 롤백으로 테스트 격리, Vitest 마이그레이션, Pact Contract Testing, AI 기반 테스트 생성까지 — 테스트의 깊은 내용을 정리했다.',
  '# 테스트 코드 완전 정복 3편 — 백엔드 테스트 실전 + 최신 트렌드

> 백엔드 테스트에서 가장 어려운 것은 DB다. 어떻게 격리할 것인가.

---

## 백엔드 테스트 전략

### 계층별 테스트 접근

```
Controller (라우터)
    ↓
Service (비즈니스 로직)  ← 단위 테스트 핵심
    ↓
Repository (DB 접근)     ← 통합 테스트
    ↓
Database
```

**Service** 계층을 순수 함수로 설계하면 단위 테스트가 쉬워진다. DB 접근은 Repository로 분리하고, 테스트에서 Repository를 mock한다.

---

## Supertest로 API 통합 테스트

Supertest는 HTTP 서버를 실제로 띄우지 않고 **인메모리에서 요청을 보내는** 라이브러리다.

### 설치

```bash
npm install -D supertest @types/supertest
```

### Express 앱 분리 (중요)

```typescript
// src/app.ts — listen() 없는 순수 앱
import express from "express";
import { postsRouter } from "./routes/posts";

export const app = express();
app.use(express.json());
app.use("/api/posts", postsRouter);
```

```typescript
// src/server.ts — 실제 실행 진입점
import { app } from "./app";
app.listen(3000, () => console.log("서버 실행 중"));
```

테스트에서는 `app.ts`만 import한다. `listen()`이 없으니 포트 충돌 없이 병렬 실행된다.

### API 테스트 작성

```typescript
// routes/posts.test.ts
import request from "supertest";
import { app } from "../app";
import { db } from "../lib/db";

describe("POST /api/posts", () => {
  afterEach(async () => {
    await db.posts.deleteMany({});  // 테스트 후 정리
  });

  it("201 — 새 포스트를 생성한다", async () => {
    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", "Bearer valid-token")
      .send({
        title: "테스트 포스트",
        content: "내용",
        slug: "test-post",
      });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      title: "테스트 포스트",
      slug: "test-post",
    });
    expect(res.body.id).toBeDefined();
  });

  it("400 — 필수 필드 누락 시 에러", async () => {
    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", "Bearer valid-token")
      .send({ title: "제목만" }); // content, slug 누락

    expect(res.status).toBe(400);
    expect(res.body.error).toContain("content");
  });

  it("401 — 인증 없으면 거부", async () => {
    const res = await request(app)
      .post("/api/posts")
      .send({ title: "제목", content: "내용", slug: "slug" });

    expect(res.status).toBe(401);
  });
});
```

---

## DB 테스트 격리 전략

### 전략 1: 인메모리 DB (SQLite)

프로덕션은 PostgreSQL, 테스트는 SQLite를 사용한다.

```typescript
// jest.config.ts
process.env.DATABASE_URL = "file::memory:?cache=shared";
```

**장점:** 빠름, 설정 간단
**단점:** PostgreSQL 전용 기능(JSON 연산자, CTE 등) 테스트 불가. 프로덕션 환경과 다르다.

### 전략 2: 실제 DB + 트랜잭션 롤백

각 테스트를 트랜잭션으로 감싸고, 끝나면 롤백한다. DB에 실제로 아무것도 안 남는다.

```typescript
// test-utils/db.ts
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export async function withTestTransaction<T>(
  fn: (tx: Omit<PrismaClient, "$transaction">) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    const result = await fn(tx);
    // 항상 롤백 — 실제로 저장하지 않음
    throw new RollbackError(result);
  }).catch((e) => {
    if (e instanceof RollbackError) return e.result as T;
    throw e;
  });
}

class RollbackError extends Error {
  constructor(public result: unknown) {
    super("test-rollback");
  }
}
```

```typescript
// 사용 예시
test("포스트 생성 후 DB 확인", async () => {
  await withTestTransaction(async (tx) => {
    const post = await tx.post.create({
      data: { title: "테스트", content: "내용", slug: "test" },
    });

    expect(post.id).toBeDefined();

    const found = await tx.post.findUnique({ where: { id: post.id } });
    expect(found?.title).toBe("테스트");
    // 트랜잭션 종료 → 롤백 → DB에 아무것도 안 남음
  });
});
```

**장점:** 실제 DB로 테스트, 프로덕션과 동일한 환경
**단점:** 느림, DB 서버 필요

### 전략 3: Test Container (권장)

Docker로 테스트 전용 DB를 격리된 컨테이너에 띄운다.

```bash
npm install -D @testcontainers/postgresql
```

```typescript
import { PostgreSqlContainer } from "@testcontainers/postgresql";

let container: StartedPostgreSqlContainer;

beforeAll(async () => {
  container = await new PostgreSqlContainer("postgres:16-alpine")
    .withDatabase("testdb")
    .start();

  process.env.DATABASE_URL = container.getConnectionUri();
  await runMigrations(); // prisma migrate deploy 등
}, 60000); // 컨테이너 시작 시간 여유

afterAll(async () => {
  await container.stop();
});
```

**장점:** 프로덕션과 완전히 동일한 환경, CI에서도 동일하게 동작
**단점:** 느림, Docker 필요

---

## Service 계층 단위 테스트

Repository를 mock해서 DB 없이 비즈니스 로직만 테스트한다.

```typescript
// services/PostService.ts
export class PostService {
  constructor(private readonly postRepo: PostRepository) {}

  async createPost(data: CreatePostDto, authorId: string) {
    const existing = await this.postRepo.findBySlug(data.slug);
    if (existing) throw new ConflictError("이미 존재하는 slug입니다");

    return this.postRepo.create({ ...data, authorId });
  }
}
```

```typescript
// services/PostService.test.ts
describe("PostService.createPost", () => {
  let service: PostService;
  let mockRepo: jest.Mocked<PostRepository>;

  beforeEach(() => {
    mockRepo = {
      findBySlug: jest.fn(),
      create: jest.fn(),
      // ...
    } as jest.Mocked<PostRepository>;

    service = new PostService(mockRepo);
  });

  it("slug 중복 시 ConflictError를 던진다", async () => {
    mockRepo.findBySlug.mockResolvedValue({ id: "existing" } as Post);

    await expect(
      service.createPost({ title: "제목", slug: "duplicate-slug", content: "내용" }, "user-1")
    ).rejects.toThrow(ConflictError);

    expect(mockRepo.create).not.toHaveBeenCalled();
  });

  it("정상 생성 시 생성된 포스트를 반환한다", async () => {
    mockRepo.findBySlug.mockResolvedValue(null);
    mockRepo.create.mockResolvedValue({ id: "new-id", title: "제목" } as Post);

    const result = await service.createPost(
      { title: "제목", slug: "new-slug", content: "내용" },
      "user-1"
    );

    expect(result.id).toBe("new-id");
    expect(mockRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ slug: "new-slug", authorId: "user-1" })
    );
  });
});
```

---

## 최신 트렌드

### Vitest — Jest의 현대적 대안

Vitest는 Vite 기반 테스트 프레임워크다. 2023~2024년부터 빠르게 채택되고 있다.

**Jest 대비 장점:**
- ESM 네이티브 지원 (Jest는 CJS 기반)
- Vite 설정 재사용 — 별도 babel/ts 설정 불필요
- 속도가 훨씬 빠름 (HMR 기반 watch 모드)
- `vi` 네임스페이스로 Jest와 호환되는 API

```bash
npm install -D vitest @vitest/ui
```

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test-utils/setup.ts"],
  },
});
```

Jest에서 마이그레이션은 거의 `jest` → `vitest`, `jest.fn()` → `vi.fn()`으로 치환하는 수준이다.

```typescript
// Jest
import { jest } from "@jest/globals";
const mockFn = jest.fn();
jest.mock("./module");

// Vitest
import { vi } from "vitest";
const mockFn = vi.fn();
vi.mock("./module");
```

### Contract Testing (Pact)

마이크로서비스 환경에서 **Consumer(프론트엔드)가 기대하는 API 스펙**을 Provider(백엔드)가 만족하는지 자동으로 검증한다.

```typescript
// Consumer 테스트 (프론트엔드)
const provider = new PactV3({
  consumer: "Frontend",
  provider: "PostsAPI",
});

test("포스트 목록 API 계약", async () => {
  provider
    .given("포스트가 존재함")
    .uponReceiving("포스트 목록 요청")
    .withRequest({ method: "GET", path: "/api/posts" })
    .willRespondWith({
      status: 200,
      body: eachLike({
        id: string("1"),
        title: string("포스트 제목"),
      }),
    });

  await provider.executeTest(async (mockServer) => {
    const posts = await fetchPosts(mockServer.url);
    expect(posts).toHaveLength(1);
  });
});
```

Consumer가 계약 파일(Pact)을 생성 → Provider가 그 계약 파일로 자신의 API를 검증. 통합 테스트 환경 없이 서비스 간 인터페이스를 검증할 수 있다.

### Visual Regression Testing

Playwright의 스크린샷 비교 기능으로 **UI가 의도치 않게 바뀌는 것**을 감지한다.

```typescript
test("메인 페이지 스크린샷", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveScreenshot("homepage.png", {
    maxDiffPixels: 100,  // 100픽셀 이내 차이는 허용
  });
});
```

처음 실행 시 기준 스크린샷이 생성되고, 이후 실행 시 픽셀 단위로 비교한다. CSS 변경, 폰트 로딩 차이, 다크모드 등을 자동으로 검출한다.

### AI 기반 테스트 생성

2025년부터 실무에서 쓰이기 시작한 방식이다.

**Copilot / Claude로 테스트 초안 생성:**
- 함수 코드를 붙여넣고 "이 함수에 대한 Jest 테스트 작성해줘 — edge case 포함" 요청
- 생성된 코드를 검토하고 실제 도메인에 맞게 수정

**자동화 도구:**
- **Momentic** — 브라우저를 직접 조작하며 E2E 테스트를 AI가 자동 생성
- **Reflect** — 자연어로 E2E 시나리오 작성, AI가 실행

주의: AI가 생성한 테스트는 반드시 검토해야 한다. 비즈니스 로직을 모르는 AI는 중요한 edge case를 빠뜨리거나, 틀린 동작을 테스트로 굳혀버릴 수 있다.

---

## 테스트 커버리지

```bash
jest --coverage
# 또는
vitest --coverage
```

```
-----------|---------|----------|---------|---------
File       | % Stmts | % Branch | % Funcs | % Lines
-----------|---------|----------|---------|---------
PostService|    92.3 |     87.5 |     100 |    92.3
```

**커버리지 숫자의 함정:** 100% 커버리지라도 의미 없는 테스트로 채울 수 있다. 커버리지는 "테스트가 실행된 코드 라인 비율"이지, "동작이 올바른지"를 보장하지 않는다.

중요한 것은 **비즈니스 로직의 핵심 경로와 edge case**가 커버되는지다.

---

## 전체 정리

| 영역 | 도구 | 전략 |
|------|------|------|
| 단위 테스트 | Jest / Vitest | 순수 함수, mock 의존성 |
| 컴포넌트 테스트 | RTL + userEvent | 동작 기반, 접근성 쿼리 |
| API mock | MSW | 네트워크 레이어에서 가로채기 |
| 통합 테스트 | Supertest | 실제 HTTP 요청, 실제 DB |
| DB 격리 | 트랜잭션 롤백 / Testcontainers | 테스트 간 독립성 보장 |
| E2E | Playwright + POM | 핵심 사용자 시나리오만 |
| 계약 테스트 | Pact | 마이크로서비스 간 인터페이스 |
| Visual | Playwright 스크린샷 | UI 회귀 방지 |

테스트 피라미드를 지키고, 각 계층에 맞는 도구를 쓰는 것이 핵심이다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_testing);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_node);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

RAISE NOTICE '테스트 시리즈 3편 삽입 완료. author: %', author;

END $TEST$;
