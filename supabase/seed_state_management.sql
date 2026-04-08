-- =============================================
-- 상태관리 완벽분석 시리즈 (2편)
-- =============================================

DO $STATE$
DECLARE
  author UUID;
  tag_react UUID;
  tag_vue UUID;
  tag_js UUID;
  tag_ts UUID;
  post_id UUID;
BEGIN

SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;
IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다.';
END IF;

INSERT INTO tags (name) VALUES ('React') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Vue') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('JavaScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('TypeScript') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_react FROM tags WHERE name = 'React';
SELECT id INTO tag_vue FROM tags WHERE name = 'Vue';
SELECT id INTO tag_js FROM tags WHERE name = 'JavaScript';
SELECT id INTO tag_ts FROM tags WHERE name = 'TypeScript';

-- =============================================
-- 1편: React 상태관리 완벽 분석
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'React 상태관리 완벽 분석 — useState부터 Zustand/Jotai/Redux Toolkit/TanStack Query까지',
  'react-state-management-deep-dive',
  'React 상태관리의 모든 옵션을 깊이 비교했다. 언제 useState를 써야 하고, 언제 전역 상태가 필요하며, 서버 상태는 왜 분리해야 하는가 — 선택 기준부터 내부 동작 원리까지 정리했다.',
  '# React 상태관리 완벽 분석 — useState부터 TanStack Query까지

> 상태관리 라이브러리를 선택하기 전에 "이 상태가 어디에 속하는가"를 먼저 결정해야 한다.

---

## 상태의 4가지 유형

```
1. 로컬 UI 상태     → useState, useReducer
2. 전역 클라이언트 상태  → Zustand, Jotai, Redux
3. 서버 상태        → TanStack Query, SWR
4. URL 상태        → useSearchParams, useRouter
```

이 구분이 흐려지면 상태관리가 복잡해진다. 서버 데이터를 Zustand에 넣거나, URL로 관리해야 할 상태를 전역 스토어에 넣는 실수가 흔하다.

---

## 1. useState — 로컬 상태의 기본

```typescript
const [count, setCount] = useState(0);
const [user, setUser] = useState<User | null>(null);

// 초기값이 비싼 연산이면 함수로 전달 (lazy initialization)
const [items, setItems] = useState(() => JSON.parse(localStorage.getItem("items") ?? "[]"));
```

### 함수형 업데이트

```typescript
// 나쁜 예: 클로저 문제 — 이전 state가 stale할 수 있음
setCount(count + 1);

// 좋은 예: 항상 최신 state를 기반으로 업데이트
setCount(prev => prev + 1);

// 연속 호출 시 차이가 명확함
// 나쁜 예: 결과가 1 (마지막 count + 1만 적용됨)
setCount(count + 1);
setCount(count + 1);

// 좋은 예: 결과가 2 (prev를 순서대로 참조)
setCount(prev => prev + 1);
setCount(prev => prev + 1);
```

### 객체 state 업데이트

```typescript
const [form, setForm] = useState({ name: "", email: "", age: 0 });

// 나쁜 예: 불변성 위반
form.name = "nywoo";
setForm(form); // React가 같은 참조라서 변경 감지 못함

// 좋은 예: 새 객체 생성
setForm(prev => ({ ...prev, name: "nywoo" }));
```

---

## 2. useReducer — 복잡한 로컬 상태

state 업데이트 로직이 여러 곳에 분산되거나, 다음 state가 이전 state에 복잡하게 의존할 때 useReducer가 적합하다.

```typescript
type CartItem = { id: string; name: string; qty: number; price: number };

type CartState = {
  items: CartItem[];
  coupon: string | null;
};

type CartAction =
  | { type: "ADD_ITEM"; item: CartItem }
  | { type: "REMOVE_ITEM"; id: string }
  | { type: "UPDATE_QTY"; id: string; qty: number }
  | { type: "APPLY_COUPON"; code: string }
  | { type: "CLEAR" };

function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case "ADD_ITEM": {
      const existing = state.items.find(i => i.id === action.item.id);
      if (existing) {
        return {
          ...state,
          items: state.items.map(i =>
            i.id === action.item.id ? { ...i, qty: i.qty + 1 } : i
          ),
        };
      }
      return { ...state, items: [...state.items, action.item] };
    }
    case "REMOVE_ITEM":
      return { ...state, items: state.items.filter(i => i.id !== action.id) };
    case "UPDATE_QTY":
      return {
        ...state,
        items: state.items.map(i =>
          i.id === action.id ? { ...i, qty: action.qty } : i
        ),
      };
    case "APPLY_COUPON":
      return { ...state, coupon: action.code };
    case "CLEAR":
      return { items: [], coupon: null };
    default:
      return state;
  }
}

// 사용
function Cart() {
  const [state, dispatch] = useReducer(cartReducer, { items: [], coupon: null });

  const total = state.items.reduce((sum, i) => sum + i.price * i.qty, 0);

  return (
    <div>
      {state.items.map(item => (
        <div key={item.id}>
          {item.name}
          <button onClick={() => dispatch({ type: "REMOVE_ITEM", id: item.id })}>
            삭제
          </button>
        </div>
      ))}
      <button onClick={() => dispatch({ type: "CLEAR" })}>초기화</button>
    </div>
  );
}
```

**useReducer vs useState 선택 기준:**

| 상황 | 선택 |
|------|------|
| 단순 값 (boolean, string, number) | useState |
| 독립적인 값 여러 개 | useState 여러 개 |
| 연관된 값들이 함께 바뀜 | useReducer |
| 업데이트 로직이 복잡하거나 많음 | useReducer |
| 테스트가 필요한 복잡한 로직 | useReducer (reducer는 순수 함수라 테스트 쉬움) |

---

## 3. Context API — 전역 상태의 함정

```typescript
// ThemeContext 예시
const ThemeContext = createContext<"light" | "dark">("light");

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<"light" | "dark">("light");
  return (
    <ThemeContext.Provider value={theme}>
      {children}
    </ThemeContext.Provider>
  );
}
```

### Context의 치명적 단점: 구독 단위

Context는 **값 전체**를 구독한다. Context에 { user, theme, settings }가 있을 때 `theme`만 바뀌어도 `user`만 쓰는 컴포넌트까지 리렌더링된다.

```typescript
// 나쁜 예: 모든 것을 하나의 Context에
const AppContext = createContext({ user, theme, settings, cart });

// 좋은 예: 관심사별로 Context 분리
const UserContext = createContext(user);
const ThemeContext = createContext(theme);
const CartContext = createContext(cart);
```

**결론:** Context는 자주 바뀌지 않는 값(theme, locale, auth user)에 적합하다. 자주 바뀌는 상태에는 Zustand나 Jotai를 써야 한다.

---

## 4. Zustand — 가장 실용적인 전역 상태

설치 및 설정이 거의 없고, 사용법이 직관적이다. 2024~2025년 가장 많이 선택되는 전역 상태 라이브러리다.

```typescript
import { create } from "zustand";
import { persist, devtools } from "zustand/middleware";

interface AuthState {
  user: User | null;
  token: string | null;
  login: (user: User, token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  devtools(
    persist(
      (set) => ({
        user: null,
        token: null,
        login: (user, token) => set({ user, token }, false, "auth/login"),
        logout: () => set({ user: null, token: null }, false, "auth/logout"),
      }),
      {
        name: "auth-storage", // localStorage 키
        partialize: (state) => ({ token: state.token }), // token만 저장
      }
    ),
    { name: "AuthStore" }
  )
);
```

### 선택적 구독 (핵심 장점)

```typescript
// user만 구독: user가 바뀔 때만 리렌더링
const user = useAuthStore(state => state.user);

// token만 구독
const token = useAuthStore(state => state.token);

// 여러 값: shallow 비교로 불필요한 리렌더링 방지
import { useShallow } from "zustand/react/shallow";
const { user, token } = useAuthStore(
  useShallow(state => ({ user: state.user, token: state.token }))
);
```

Context와 달리 Zustand는 **선택한 값만 구독**한다. `user`만 구독하는 컴포넌트는 `token`이 바뀌어도 리렌더링되지 않는다.

### 비동기 액션

```typescript
interface PostStore {
  posts: Post[];
  loading: boolean;
  error: string | null;
  fetchPosts: () => Promise<void>;
}

export const usePostStore = create<PostStore>()((set) => ({
  posts: [],
  loading: false,
  error: null,
  fetchPosts: async () => {
    set({ loading: true, error: null });
    try {
      const res = await fetch("/api/posts");
      const posts = await res.json();
      set({ posts, loading: false });
    } catch (e) {
      set({ error: "불러오기 실패", loading: false });
    }
  },
}));
```

단, 서버 데이터는 TanStack Query로 관리하는 게 낫다. 캐싱, 재검증, 중복 요청 제거 등을 자동으로 처리해주기 때문이다.

---

## 5. Jotai — 원자 단위 상태 (Atomic State)

Zustand가 "스토어 전체"를 만드는 방식이라면, Jotai는 **atom 단위**로 상태를 쪼개는 방식이다. Recoil의 사상을 계승하지만 더 가볍다.

```typescript
import { atom, useAtom, useAtomValue, useSetAtom } from "jotai";

// 기본 atom
const countAtom = atom(0);
const userAtom = atom<User | null>(null);

// 파생 atom (computed)
const doubleCountAtom = atom(get => get(countAtom) * 2);

// 비동기 atom
const postsAtom = atom(async () => {
  const res = await fetch("/api/posts");
  return res.json() as Promise<Post[]>;
});

// 사용
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const double = useAtomValue(doubleCountAtom);
  const setUser = useSetAtom(userAtom); // 읽기 없이 쓰기만 할 때

  return (
    <div>
      <p>count: {count}</p>
      <p>double: {double}</p>
      <button onClick={() => setCount(c => c + 1)}>+1</button>
    </div>
  );
}
```

**Zustand vs Jotai 선택 기준:**

| 상황 | 선택 |
|------|------|
| 전통적인 스토어 패턴 선호 | Zustand |
| 상태가 독립적인 여러 조각 | Jotai |
| 파생 상태(computed)가 많음 | Jotai |
| persist, devtools 즉시 필요 | Zustand |
| 번들 크기 최소화 (8KB vs 3KB) | Jotai |

---

## 6. Redux Toolkit — 엔터프라이즈 선택

Redux는 과거에 보일러플레이트가 많았지만, Redux Toolkit(RTK)으로 많이 개선됐다.

```typescript
import { createSlice, createAsyncThunk, configureStore } from "@reduxjs/toolkit";

// Thunk for async
export const fetchPosts = createAsyncThunk("posts/fetchAll", async () => {
  const res = await fetch("/api/posts");
  return res.json() as Promise<Post[]>;
});

const postsSlice = createSlice({
  name: "posts",
  initialState: {
    items: [] as Post[],
    status: "idle" as "idle" | "loading" | "succeeded" | "failed",
    error: null as string | null,
  },
  reducers: {
    addPost(state, action: PayloadAction<Post>) {
      state.items.push(action.payload); // Immer 덕분에 직접 변경 가능
    },
    removePost(state, action: PayloadAction<string>) {
      state.items = state.items.filter(p => p.id !== action.payload);
    },
  },
  extraReducers(builder) {
    builder
      .addCase(fetchPosts.pending, (state) => { state.status = "loading"; })
      .addCase(fetchPosts.fulfilled, (state, action) => {
        state.status = "succeeded";
        state.items = action.payload;
      })
      .addCase(fetchPosts.rejected, (state, action) => {
        state.status = "failed";
        state.error = action.error.message ?? "오류 발생";
      });
  },
});

export const { addPost, removePost } = postsSlice.actions;

// RTK Query (TanStack Query와 유사한 서버 상태 관리)
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

export const postsApi = createApi({
  reducerPath: "postsApi",
  baseQuery: fetchBaseQuery({ baseUrl: "/api" }),
  tagTypes: ["Post"],
  endpoints: (builder) => ({
    getPosts: builder.query<Post[], void>({
      query: () => "/posts",
      providesTags: ["Post"],
    }),
    createPost: builder.mutation<Post, Partial<Post>>({
      query: (body) => ({ url: "/posts", method: "POST", body }),
      invalidatesTags: ["Post"], // 생성 후 목록 자동 갱신
    }),
  }),
});

export const { useGetPostsQuery, useCreatePostMutation } = postsApi;
```

**Redux를 선택해야 하는 경우:**
- 대규모 팀, 복잡한 상태 로직
- Redux DevTools의 타임트래블 디버깅이 필요
- 기존 Redux 프로젝트 유지보수

---

## 7. TanStack Query — 서버 상태의 표준

서버에서 오는 데이터는 전역 스토어가 아닌 TanStack Query로 관리한다.

```typescript
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

// 조회
function usePostsQuery(tag?: string) {
  return useQuery({
    queryKey: ["posts", { tag }],   // 캐시 키: tag가 바뀌면 별도 캐시
    queryFn: () => fetchPosts(tag),
    staleTime: 1000 * 60 * 5,      // 5분간 fresh (재요청 안 함)
    gcTime: 1000 * 60 * 10,        // 10분 후 캐시에서 제거
    placeholderData: keepPreviousData, // 페이지네이션 시 이전 데이터 유지
  });
}

// 생성/수정/삭제
function useCreatePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePostDto) =>
      fetch("/api/posts", { method: "POST", body: JSON.stringify(data) }).then(r => r.json()),

    // Optimistic Update: 응답 전에 UI 먼저 반영
    onMutate: async (newPost) => {
      await queryClient.cancelQueries({ queryKey: ["posts"] });
      const snapshot = queryClient.getQueryData<Post[]>(["posts"]);

      queryClient.setQueryData<Post[]>(["posts"], old => [
        ...(old ?? []),
        { ...newPost, id: "temp-id" },
      ]);

      return { snapshot }; // rollback용
    },

    onError: (err, variables, context) => {
      // 실패 시 롤백
      queryClient.setQueryData(["posts"], context?.snapshot);
    },

    onSettled: () => {
      // 성공/실패 관계없이 서버에서 최신 데이터 재조회
      queryClient.invalidateQueries({ queryKey: ["posts"] });
    },
  });
}
```

### Suspense 모드

```typescript
// React 18 Suspense와 통합
function PostList() {
  const { data: posts } = useSuspenseQuery({
    queryKey: ["posts"],
    queryFn: fetchPosts,
  });
  // 로딩 체크 불필요 — Suspense가 처리
  return posts.map(post => <PostCard key={post.id} post={post} />);
}

function Page() {
  return (
    <Suspense fallback={<PostListSkeleton />}>
      <ErrorBoundary fallback={<ErrorMessage />}>
        <PostList />
      </ErrorBoundary>
    </Suspense>
  );
}
```

---

## 상태관리 선택 가이드

```
상태가 어디에 속하는가?

서버 데이터? → TanStack Query
↓ No

URL에 반영해야 하는가? (필터, 페이지, 탭)
→ useSearchParams / useRouter
↓ No

여러 컴포넌트가 공유하는가?
↓ Yes                  ↓ No
전역 상태               로컬 상태
↓                      ↓
업데이트 로직이         단순한가?
복잡한가?              → useState
↓ Yes    ↓ No
Redux    Zustand       복잡한가?
         Jotai         → useReducer
```

---

## 정리

| 라이브러리 | 번들 크기 | 학습 곡선 | 적합한 상황 |
|-----------|---------|---------|-----------|
| useState | 0 (내장) | 낮음 | 단순 로컬 상태 |
| useReducer | 0 (내장) | 중간 | 복잡한 로컬 상태 |
| Context | 0 (내장) | 낮음 | 자주 안 바뀌는 전역 값 |
| Zustand | ~3KB | 낮음 | 대부분의 전역 상태 |
| Jotai | ~3KB | 낮음 | 원자적/파생 상태 |
| Redux Toolkit | ~40KB | 높음 | 대규모/복잡 앱 |
| TanStack Query | ~12KB | 중간 | 서버 상태 (필수) |',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_react);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

-- =============================================
-- 2편: Vue 상태관리 + React vs Vue 비교
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Vue 상태관리 완벽 분석 + React vs Vue 상태관리 완전 비교',
  'vue-state-management-vs-react',
  'Vue 3 Composition API의 ref/reactive/computed부터 Pinia 심화까지, 그리고 React와 Vue의 상태관리 철학 차이를 코드 레벨에서 1:1로 비교했다.',
  '# Vue 상태관리 완벽 분석 + React vs Vue 완전 비교

> React는 상태를 "외부에서 주입"하는 방향, Vue는 상태를 "반응형으로 선언"하는 방향으로 설계됐다.

---

## Vue 3 반응형 시스템의 핵심

Vue 3는 Proxy 기반 반응형 시스템을 사용한다. 상태가 바뀌면 그 상태를 참조하는 뷰가 **자동으로** 업데이트된다.

### ref vs reactive

```typescript
import { ref, reactive, computed, watch, watchEffect } from "vue";

// ref: 원시값 또는 단일 값에 사용
const count = ref(0);
count.value++;          // .value로 접근
console.log(count.value); // 0 → 1

// reactive: 객체에 사용 (깊은 반응형)
const user = reactive({
  name: "nywoo",
  profile: { age: 28, role: "admin" },
});
user.name = "newname";        // 직접 변경 (React처럼 setter 불필요)
user.profile.age = 29;        // 중첩 객체도 반응형

// 주의: reactive를 구조 분해하면 반응형을 잃는다
const { name } = user;        // 반응형 잃음!
const { name: nameRef } = toRefs(user); // toRefs로 해결
```

**ref vs reactive 선택 기준:**

```typescript
// ref: 원시값, 단일 참조, 컴포저블에서 반환할 때
const isOpen = ref(false);
const count = ref(0);
const selectedId = ref<string | null>(null);

// reactive: 연관된 여러 값을 그룹화할 때
const form = reactive({
  email: "",
  password: "",
  rememberMe: false,
});
```

---

## computed — 파생 상태

```typescript
const items = ref([
  { id: 1, name: "MacBook", price: 2000000, category: "laptop" },
  { id: 2, name: "AirPods", price: 300000, category: "audio" },
  { id: 3, name: "iPad", price: 1200000, category: "tablet" },
]);

const selectedCategory = ref("all");

// computed: 의존하는 값이 바뀔 때만 재계산
const filteredItems = computed(() => {
  if (selectedCategory.value === "all") return items.value;
  return items.value.filter(i => i.category === selectedCategory.value);
});

const totalPrice = computed(() =>
  filteredItems.value.reduce((sum, i) => sum + i.price, 0)
);

// 쓰기 가능한 computed
const fullName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (val: string) => {
    const [first, ...rest] = val.split(" ");
    firstName.value = first;
    lastName.value = rest.join(" ");
  },
});

fullName.value = "kim nywoo"; // setter 호출
```

---

## watch vs watchEffect

```typescript
const query = ref("");
const results = ref<Post[]>([]);

// watch: 특정 소스를 명시적으로 감시
watch(query, async (newQuery, oldQuery) => {
  if (newQuery === oldQuery) return;
  results.value = await searchPosts(newQuery);
}, {
  immediate: true,    // 즉시 실행 (초기값으로도 실행)
  deep: true,         // 중첩 객체 변경 감지
  debounce: 300,      // vue-use의 watchDebounced 사용 시
});

// watchEffect: 내부에서 참조하는 모든 반응형 데이터를 자동 추적
watchEffect(async () => {
  // query.value와 selectedTag.value를 자동 감지
  results.value = await searchPosts(query.value, selectedTag.value);
});

// watch vs watchEffect 선택
// watch: 이전/다음 값 비교 필요, 특정 소스만 감시
// watchEffect: 여러 의존성을 자동 추적, 즉시 실행 기본
```

---

## Composables — Vue의 로직 재사용 패턴

React의 Custom Hook과 동일한 개념이다. `use`로 시작하는 함수로 상태 로직을 캡슐화한다.

```typescript
// composables/usePosts.ts
import { ref, computed } from "vue";

export function usePosts() {
  const posts = ref<Post[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const selectedTag = ref<string | null>(null);

  const filteredPosts = computed(() =>
    selectedTag.value
      ? posts.value.filter(p => p.tags.includes(selectedTag.value!))
      : posts.value
  );

  async function fetchPosts() {
    loading.value = true;
    error.value = null;
    try {
      const res = await fetch("/api/posts");
      posts.value = await res.json();
    } catch (e) {
      error.value = "불러오기 실패";
    } finally {
      loading.value = false;
    }
  }

  return {
    posts: readonly(posts),
    filteredPosts,
    loading: readonly(loading),
    error: readonly(error),
    selectedTag,
    fetchPosts,
  };
}

// 컴포넌트에서 사용
const { filteredPosts, loading, fetchPosts, selectedTag } = usePosts();
onMounted(fetchPosts);
```

---

## Pinia — Vue 3 공식 상태관리

Vuex의 후계자. Vue 3 + TypeScript에 최적화됐으며, Composition API 스타일을 지원한다.

### Option Store (Vuex 유사)

```typescript
import { defineStore } from "pinia";

export const useCartStore = defineStore("cart", {
  state: () => ({
    items: [] as CartItem[],
    coupon: null as string | null,
  }),

  getters: {
    totalPrice: (state) =>
      state.items.reduce((sum, i) => sum + i.price * i.qty, 0),
    itemCount: (state) =>
      state.items.reduce((sum, i) => sum + i.qty, 0),
    discountedPrice(): number {
      // getter 안에서 다른 getter 참조 가능
      return this.coupon === "SAVE10"
        ? this.totalPrice * 0.9
        : this.totalPrice;
    },
  },

  actions: {
    addItem(item: CartItem) {
      const existing = this.items.find(i => i.id === item.id);
      if (existing) {
        existing.qty++;
      } else {
        this.items.push(item);
      }
    },

    async applyCoupon(code: string) {
      const res = await fetch(`/api/coupons/${code}`);
      if (!res.ok) throw new Error("유효하지 않은 쿠폰");
      this.coupon = code;
    },
  },
});
```

### Setup Store (Composition API 스타일, 권장)

```typescript
export const useAuthStore = defineStore("auth", () => {
  // state
  const user = ref<User | null>(null);
  const token = ref<string | null>(null);

  // getters (computed)
  const isLoggedIn = computed(() => !!user.value);
  const isAdmin = computed(() => user.value?.role === "admin");

  // actions
  async function login(email: string, password: string) {
    const res = await fetch("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json();
    user.value = data.user;
    token.value = data.token;
  }

  function logout() {
    user.value = null;
    token.value = null;
  }

  return { user, token, isLoggedIn, isAdmin, login, logout };
});

// 컴포넌트에서
const authStore = useAuthStore();
const { user, isLoggedIn } = storeToRefs(authStore); // 구조분해 시 반응형 유지
```

### Pinia Plugins (persist)

```typescript
// main.ts
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

// 스토어에 적용
export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(null);
  return { token };
}, {
  persist: {
    pick: ["token"], // token만 localStorage에 저장
  },
});
```

---

## VueUse — Composables 생태계

React의 react-use와 같은 위치. 반응형 상태를 다루는 200개 이상의 Composable 모음이다.

```typescript
import {
  useLocalStorage,
  useSessionStorage,
  useDebouncedRef,
  useMediaQuery,
  useFetch,
  useIntersectionObserver,
} from "@vueuse/core";

// localStorage 자동 동기화
const theme = useLocalStorage<"light" | "dark">("theme", "light");
theme.value = "dark"; // 자동으로 localStorage에 저장됨

// debounced ref
const searchQuery = useDebouncedRef("", 300);

// 미디어 쿼리
const isMobile = useMediaQuery("(max-width: 768px)");

// Intersection Observer
const { isIntersecting, stop } = useIntersectionObserver(
  targetRef,
  ([{ isIntersecting }]) => {
    if (isIntersecting) loadMore();
  }
);
```

---

## React vs Vue 상태관리 1:1 비교

### 로컬 상태

```typescript
// React
const [count, setCount] = useState(0);
setCount(prev => prev + 1);

// Vue
const count = ref(0);
count.value++;
```

### 파생 상태

```typescript
// React — useMemo (수동 의존성 선언)
const doubled = useMemo(() => count * 2, [count]);

// Vue — computed (자동 의존성 추적)
const doubled = computed(() => count.value * 2);
```

### 사이드 이펙트

```typescript
// React — 의존성 배열 수동 관리
useEffect(() => {
  document.title = `Count: ${count}`;
}, [count]);

// Vue — watchEffect (자동 추적)
watchEffect(() => {
  document.title = `Count: ${count.value}`;
});
```

### 전역 상태

```typescript
// React (Zustand)
const useStore = create((set) => ({
  count: 0,
  increment: () => set(state => ({ count: state.count + 1 })),
}));
const count = useStore(state => state.count);

// Vue (Pinia)
const useStore = defineStore("counter", () => {
  const count = ref(0);
  const increment = () => count.value++;
  return { count, increment };
});
const store = useStore();
```

### 서버 상태

```typescript
// React — TanStack Query
const { data, isLoading } = useQuery({
  queryKey: ["posts"],
  queryFn: fetchPosts,
});

// Vue — TanStack Query (Vue 버전 존재)
const { data, isLoading } = useQuery({
  queryKey: ["posts"],
  queryFn: fetchPosts,
});
// TanStack Query는 React/Vue/Solid/Svelte 모두 지원
```

---

## 철학적 차이

### React: 명시적, 단방향

```
상태 변경 → setState 호출 → React가 리렌더링 결정
→ 개발자가 모든 것을 명시적으로 선언
→ 리렌더링 제어가 필요하면 memo/useMemo/useCallback 직접 사용
```

### Vue: 선언적, 자동 추적

```
상태 변경 → Proxy가 감지 → 해당 DOM만 자동 업데이트
→ 개발자는 상태를 선언하기만 하면 됨
→ 리렌더링 최적화가 자동 (종속된 부분만 업데이트)
```

| 측면 | React | Vue |
|------|-------|-----|
| 반응형 방식 | 수동 setState | Proxy 자동 추적 |
| 의존성 선언 | 명시적 (deps 배열) | 자동 추적 |
| 상태 변경 | 불변성 (새 객체) | 직접 변경 가능 |
| 최적화 | memo/useCallback 수동 | 자동 (fine-grained) |
| 유연성 | 높음 (JS 친화적) | 중간 (Vue 규칙 내) |
| 학습 곡선 | 중간 | 낮음 |
| 생태계 | 압도적으로 큼 | 중간 |

---

## 어떤 것을 선택해야 하는가?

**React를 선택해야 하는 경우:**
- 팀 규모가 크고 생태계/커뮤니티 리소스가 중요
- React Native로 모바일도 함께 개발
- Meta/Vercel 등 대형 오픈소스와 통합
- TypeScript 타입 추론이 중요한 복잡한 앱

**Vue를 선택해야 하는 경우:**
- 빠른 온보딩이 필요 (러닝 커브 낮음)
- 기존 HTML/JS 코드베이스와 점진적 통합
- 중소 규모 팀, 빠른 프로토타입
- Nuxt.js로 풀스택 개발

**핵심:** 상태관리 도구보다 "어떤 상태가 어디에 있어야 하는가"를 잘 결정하는 것이 더 중요하다. 도구는 그 결정을 구현하는 수단일 뿐이다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_react);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_vue);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_ts);

RAISE NOTICE '상태관리 완벽분석 시리즈 2편 삽입 완료. author: %', author;

END $STATE$;
