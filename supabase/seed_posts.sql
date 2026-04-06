-- =============================================
-- 포스트 시드 데이터
-- 실행 전: AUTHOR_ID를 실제 admin 유저 UUID로 교체
-- Supabase > Authentication > Users 에서 확인
-- =============================================

DO $$
DECLARE
  author UUID;
  tag_claude UUID;
  tag_jenkins UUID;
  tag_docker UUID;
  tag_aws UUID;
  tag_js UUID;
  tag_react UUID;
  tag_auth UUID;
  post_id UUID;
BEGIN

-- =============================================
-- 1. admin 유저 프로필에서 author ID 가져오기
-- =============================================
SELECT id INTO author FROM profiles WHERE role = 'admin' LIMIT 1;

IF author IS NULL THEN
  RAISE EXCEPTION 'admin 유저가 없습니다. Authentication > Users에서 먼저 생성하고 profiles.role을 admin으로 업데이트하세요.';
END IF;

-- =============================================
-- 2. 태그 생성
-- =============================================
INSERT INTO tags (name) VALUES ('Claude Code') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Jenkins') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('Docker') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('AWS') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('JavaScript') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('React') ON CONFLICT (name) DO NOTHING;
INSERT INTO tags (name) VALUES ('인증/보안') ON CONFLICT (name) DO NOTHING;

SELECT id INTO tag_claude FROM tags WHERE name = 'Claude Code';
SELECT id INTO tag_jenkins FROM tags WHERE name = 'Jenkins';
SELECT id INTO tag_docker FROM tags WHERE name = 'Docker';
SELECT id INTO tag_aws FROM tags WHERE name = 'AWS';
SELECT id INTO tag_js FROM tags WHERE name = 'JavaScript';
SELECT id INTO tag_react FROM tags WHERE name = 'React';
SELECT id INTO tag_auth FROM tags WHERE name = '인증/보안';

-- =============================================
-- 3. 포스트 1: Claude Code
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Claude Code로 AI 페어 프로그래밍 제대로 활용하는 법',
  'how-to-use-claude-code-effectively',
  'Claude Code는 단순 코드 자동완성 도구가 아니다. CLAUDE.md, @ 멘션, 단계적 요청법까지 — 시니어와 페어 프로그래밍하는 수준으로 활용하는 법을 정리했다.',
  '# Claude Code로 AI 페어 프로그래밍 제대로 활용하는 법

> Claude Code는 단순한 코드 자동완성 도구가 아니다. 제대로 쓰는 방법을 알면 실제 시니어 개발자와 페어 프로그래밍하는 수준의 경험을 얻을 수 있다.

---

## Claude Code가 뭔가요?

Claude Code는 Anthropic이 만든 CLI 기반의 AI 코딩 에이전트다. 단순히 텍스트를 생성하는 챗봇과 달리, **실제 파일 시스템에 접근하고, 코드를 읽고, 수정하고, 터미널 명령을 실행**할 수 있다.

터미널에서 `claude` 명령어 하나로 실행되며, 현재 작업 디렉토리의 코드베이스를 통째로 컨텍스트로 활용한다. 즉, "이 프로젝트에서 인증 관련 버그 찾아줘"라고 하면 실제로 소스를 뒤져서 답을 준다.

### 주요 특징

- **파일 읽기/쓰기/생성/삭제** 능력 (권한 확인 후 실행)
- **bash 명령 실행** (테스트 돌리기, 빌드, git 작업 등)
- **전체 코드베이스 컨텍스트** 인식
- **CLAUDE.md**를 통한 프로젝트별 규칙 주입
- **멀티 에이전트 오케스트레이션** 지원 (서브 에이전트에 작업 위임 가능)

### 일반 ChatGPT vs Claude Code

| 항목 | ChatGPT (웹) | Claude Code |
|------|-------------|-------------|
| 파일 접근 | 불가 (업로드 필요) | 직접 읽기/쓰기 |
| 코드 실행 | 샌드박스 제한 | 로컬 터미널 직접 실행 |
| 컨텍스트 | 대화 내 붙여넣기 | 프로젝트 전체 |
| 지속성 | 대화 종료 시 소멸 | CLAUDE.md로 영속 |

---

## 설치 및 시작

```bash
# npm으로 설치 (Node.js 18+ 필요)
npm install -g @anthropic-ai/claude-code

# 프로젝트 디렉토리에서 실행
cd my-project
claude
```

최초 실행 시 Anthropic API 키 또는 Claude.ai 계정으로 인증한다.

---

## 효과적인 프롬프트 작성법

### 1. 목표 → 제약 → 출력 형식 순서로 작성

**나쁜 예:**
```
로그인 기능 만들어줘
```

**좋은 예:**
```
Next.js 15 App Router 기반 프로젝트에서 Supabase Auth를 이용한 이메일/비밀번호 로그인 기능을 구현해줘.
- Server Action 사용 (API Route 사용하지 말 것)
- 에러는 useFormState로 처리
- 로그인 성공 시 /dashboard로 redirect
- TypeScript 타입 명시 필수
```

### 2. 단계적으로 쪼개서 요청하기

```
# 1단계: 설계 먼저
"인증 시스템 전체 구조를 설계해줘. 코드는 아직 작성하지 마."

# 2단계: 설계 확인 후 구현
"방금 설계한 구조대로 로그인 폼 컴포넌트부터 만들어줘."

# 3단계: 테스트
"방금 만든 컴포넌트에 대한 Jest 테스트 작성해줘."
```

### 3. 예시 코드를 레퍼런스로 제공하기

```
src/components/PostCard.tsx 스타일 그대로 참고해서
TagBadge 컴포넌트 만들어줘.
```

---

## 컨텍스트 잘 주는 방법

### @ 멘션으로 파일 지정

```
@src/lib/supabase.ts 이 파일 보고 클라이언트 초기화 방식 설명해줘.
```

```
@src/app/blog/page.tsx @src/lib/posts.ts
이 두 파일을 보고 데이터 패칭 구조 파악해서 캐싱 전략 개선해줘.
```

### 현재 상태 먼저 설명하기

```
현재 상황:
- Next.js 15 + Supabase 조합의 블로그 프로젝트
- 포스트 목록은 정적으로 잘 불러오는 상태
- 문제: 태그 필터링 시 URL 쿼리 파라미터가 변경돼도 페이지가 재렌더링 안 됨

이 문제 원인 분석해줘.
```

---

## CLAUDE.md 활용법

`CLAUDE.md`는 Claude Code가 실행될 때 **자동으로 읽는 프로젝트 규칙 파일**이다.

### 기본 구조

```markdown
# 프로젝트명 — Claude Code 규칙

## 기술 스택
- 프레임워크: Next.js 15 (App Router)
- 언어: TypeScript 5
- DB: Supabase (PostgreSQL)

## 코드 규칙
- Tailwind 클래스만 사용. inline style, CSS module 금지
- any 사용 금지
- 코드 작성 전 항상 설계 먼저 설명하고 승인 받을 것

## 브랜치 전략
- main: 배포용. 직접 커밋 금지
- feat/기능명: 기능 단위 작업
```

### CLAUDE.md 계층 구조

CLAUDE.md는 **디렉토리별로 중첩 적용**된다.

```
my-project/
├── CLAUDE.md              # 전체 프로젝트 규칙
├── src/
│   ├── components/
│   │   └── CLAUDE.md      # 컴포넌트 전용 규칙
│   └── lib/
│       └── CLAUDE.md      # 라이브러리 코드 규칙
```

### 팀 공유 vs 개인 설정 분리

- `CLAUDE.md` — git 커밋. 팀 전체 공유
- `CLAUDE.local.md` — `.gitignore`. 개인 환경별 설정

---

## 실전 팁

### 대화 방식: 탐색 → 설계 → 구현 → 검증

```
1. 탐색: "현재 auth 관련 파일들 전부 파악해줘."
2. 설계: "파악한 구조 기반으로 소셜 로그인 추가 설계안 만들어줘."
3. 구현: "설계안 그대로 Google OAuth 부분만 먼저 구현해줘."
4. 검증: "방금 구현한 코드 잠재적 버그나 엣지케이스 검토해줘."
```

### 코드 리뷰 요청법

```
@src/lib/posts.ts 이 파일을 다음 관점에서 리뷰해줘:
1. 성능 (불필요한 DB 쿼리, N+1 문제)
2. 보안 (SQL injection 가능성, 권한 체크 누락)
3. 타입 안전성 (any 사용, 타입 추론 실패 가능 지점)
```

### 디버깅 활용법

```
다음 에러가 발생하고 있어:
Error: Cannot read properties of undefined (reading ''id'')
  at PostCard (src/components/PostCard.tsx:23:18)

재현 조건: 태그 필터 적용 후 새로고침 시 발생
@src/components/PostCard.tsx @src/app/blog/page.tsx 보고 원인 찾아줘.
```

### /commands 활용

```
/clear     # 대화 컨텍스트 초기화
/compact   # 긴 대화를 요약해서 컨텍스트 절약
/cost      # 토큰/비용 확인
/model     # 모델 변경
```

---

## 주의사항

### 1. 맹목적 신뢰 금지

Claude Code가 생성한 코드는 **반드시 직접 검토**해야 한다. 특히 보안 관련 코드, DB 마이그레이션, 환경변수 처리는 꼭 확인하자.

### 2. 컨텍스트 윈도우 관리

긴 대화는 컨텍스트 윈도우를 소모해 후반부 응답 품질이 떨어진다.

- 큰 기능 단위로 새 대화 시작
- `/compact`로 요약 활용
- CLAUDE.md에 중요 규칙 기록해서 반복 설명 최소화

### 3. 시크릿 관리

`.claudeignore` 파일로 민감한 파일 접근을 차단할 수 있다.

```
# .claudeignore
.env
.env.local
secrets/
```

---

## 정리

Claude Code를 잘 쓰는 핵심은 **정확한 컨텍스트 + 명확한 요청 + 단계적 접근**이다. CLAUDE.md를 잘 관리하면 매 대화마다 반복 설명 없이도 일관된 코드 품질을 유지할 수 있다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_claude);

-- =============================================
-- 4. 포스트 2: Jenkins
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Jenkins 시작부터 실전까지 — CI/CD 파이프라인 완전 정복',
  'jenkins-cicd-pipeline-complete-guide',
  'Jenkins를 Docker로 설치하는 법부터 Jenkinsfile 작성, GitHub Webhook 연동, Node.js 프로젝트 실전 파이프라인까지 한 번에 정리했다.',
  '# Jenkins 시작부터 실전까지 — CI/CD 파이프라인 완전 정복

> Jenkins는 가장 오래되고 가장 널리 쓰이는 오픈소스 CI/CD 도구다. 설정이 다소 복잡하지만 자유도와 플러그인 생태계가 압도적이다.

---

## CI/CD가 뭔가요?

**CI (Continuous Integration, 지속적 통합)**
코드를 변경할 때마다 자동으로 빌드하고 테스트해서, 버그를 빨리 발견하는 개발 방식이다.

**CD (Continuous Delivery / Continuous Deployment, 지속적 배포)**
CI를 통과한 코드를 자동으로 스테이징 또는 프로덕션 환경에 배포하는 과정이다.

- **Continuous Delivery**: 배포 준비는 자동, 실제 배포는 수동 승인
- **Continuous Deployment**: 테스트 통과 시 프로덕션까지 완전 자동 배포

### CI/CD 없는 세계

```
개발자A 코드 push → 개발자B 수동 pull → 수동 빌드 → 수동 테스트
→ 수동 서버 접속 → 수동 배포 → 버그 발견 → 처음부터 반복
```

### CI/CD 있는 세계

```
개발자A 코드 push → Jenkins 자동 감지 → 빌드 → 테스트 → 배포
→ Slack 알림 → 끝
```

---

## Jenkins가 뭔가요?

Jenkins는 2011년 처음 릴리스된 오픈소스 자동화 서버다. Java로 작성되었으며, **Jenkinsfile**(파이프라인 코드)을 통해 CI/CD 워크플로를 정의한다.

### Jenkins vs GitHub Actions vs GitLab CI

| 항목 | Jenkins | GitHub Actions | GitLab CI |
|------|---------|---------------|-----------|
| 호스팅 | 자체 서버 필요 | GitHub 제공 | GitLab 제공 |
| 비용 | 서버 비용만 | 무료 (제한) | 무료 (제한) |
| 플러그인 | 1,800+ | Marketplace | 내장 |
| 설정 난이도 | 높음 | 낮음 | 중간 |
| 자유도 | 최고 | 중간 | 중간 |

---

## Docker로 Jenkins 설치하기

```bash
# Jenkins 전용 네트워크 및 볼륨 생성
docker network create jenkins
docker volume create jenkins-data

# Jenkins 컨테이너 실행
docker run \
  --name jenkins \
  --restart=on-failure \
  --detach \
  --network jenkins \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  jenkins/jenkins:lts-jdk21
```

### 파이프라인에서 Docker 명령이 필요한 경우

```dockerfile
# Dockerfile.jenkins
FROM jenkins/jenkins:lts-jdk21

USER root

RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg lsb-release

RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && apt-get install -y docker-ce-cli

USER jenkins
```

```bash
docker build -t my-jenkins -f Dockerfile.jenkins .

docker run \
  --name jenkins --restart=on-failure --detach \
  --network jenkins \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  my-jenkins
```

### 초기 설정

1. `http://localhost:8080` 접속
2. 초기 비밀번호 확인: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. **Install suggested plugins** 선택
4. 관리자 계정 생성

---

## Jenkinsfile 기본 구조

**Declarative Pipeline** 방식이 현재 표준이다.

```groovy
pipeline {
    agent any

    environment {
        NODE_VERSION = ''20''
        APP_NAME = ''my-app''
    }

    stages {
        stage(''Checkout'') {
            steps {
                checkout scm
            }
        }

        stage(''Build'') {
            steps {
                sh ''npm ci''
                sh ''npm run build''
            }
        }

        stage(''Test'') {
            steps {
                sh ''npm test''
            }
        }

        stage(''Deploy'') {
            when {
                branch ''main''
            }
            steps {
                sh ''./scripts/deploy.sh''
            }
        }
    }

    post {
        success { echo ''빌드 성공!'' }
        failure { echo ''빌드 실패!'' }
        always { cleanWs() }
    }
}
```

### 병렬 실행

```groovy
stage(''Test'') {
    parallel {
        stage(''Unit Test'') {
            steps { sh ''npm run test:unit'' }
        }
        stage(''Lint'') {
            steps { sh ''npm run lint'' }
        }
        stage(''TypeScript'') {
            steps { sh ''npx tsc --noEmit'' }
        }
    }
}
```

### 크리덴셜 사용

```groovy
stage(''Deploy'') {
    steps {
        withCredentials([
            string(credentialsId: ''aws-access-key'', variable: ''AWS_ACCESS_KEY''),
            string(credentialsId: ''aws-secret-key'', variable: ''AWS_SECRET_KEY'')
        ]) {
            sh ''aws s3 sync ./dist s3://my-bucket''
        }
    }
}
```

---

## 주요 플러그인

| 플러그인 | 기능 |
|---------|------|
| **Git** | Git 저장소 연동 |
| **GitHub Integration** | PR/Push 이벤트 트리거 |
| **Pipeline** | Jenkinsfile 지원 |
| **Blue Ocean** | 파이프라인 시각화 UI |
| **Docker Pipeline** | 파이프라인에서 Docker 사용 |
| **Credentials Binding** | 시크릿 안전 사용 |
| **Slack Notification** | Slack 빌드 알림 |
| **NodeJS** | Node.js 버전 관리 |

---

## GitHub 연동

### 1. Credentials 등록

`Jenkins 관리` → `Credentials` → `System` → `Global credentials` → `Add Credentials`

- Kind: `Username with password`
- Username: GitHub 사용자명
- Password: GitHub Personal Access Token (repo, admin:repo_hook 권한)

### 2. Multibranch Pipeline 생성

1. `새 Item` → `Multibranch Pipeline`
2. Branch Sources → GitHub 선택
3. Credentials 연결, Repository URL 입력
4. Save → 자동 브랜치 스캔

### 3. GitHub Webhook 설정

```
Payload URL: http://your-jenkins-url:8080/github-webhook/
Content type: application/json
Trigger: push event
```

---

## Node.js 실전 파이프라인

```groovy
pipeline {
    agent any

    tools {
        nodejs ''NodeJS-20''
    }

    environment {
        CI = ''true''
        DEPLOY_ENV = "${env.BRANCH_NAME == ''main'' ? ''production'' : ''staging''}"
    }

    stages {
        stage(''Install'') {
            steps {
                sh ''npm ci''
            }
        }

        stage(''Lint & Type Check'') {
            parallel {
                stage(''ESLint'') {
                    steps { sh ''npm run lint'' }
                }
                stage(''TypeScript'') {
                    steps { sh ''npx tsc --noEmit'' }
                }
            }
        }

        stage(''Test'') {
            steps {
                sh ''npm test -- --coverage --watchAll=false''
            }
        }

        stage(''Build'') {
            steps {
                sh ''npm run build''
            }
        }

        stage(''Docker Build & Push'') {
            when {
                anyOf { branch ''main''; branch ''develop'' }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: ''dockerhub-credentials'',
                        usernameVariable: ''DOCKER_USER'',
                        passwordVariable: ''DOCKER_PASS''
                    )
                ]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker build -t \$DOCKER_USER/my-app:\${GIT_COMMIT:0:7} .
                        docker push \$DOCKER_USER/my-app:\${GIT_COMMIT:0:7}
                    """
                }
            }
        }

        stage(''Deploy'') {
            when { branch ''main'' }
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: ''deploy-server-ssh'',
                        keyFileVariable: ''SSH_KEY''
                    )
                ]) {
                    sh """
                        ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \
                            deploy@prod-server.example.com \
                            "cd /app && docker pull my-app:\${GIT_COMMIT:0:7} && docker-compose up -d"
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(color: ''good'', message: "빌드 성공: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            slackSend(color: ''danger'', message: "빌드 실패: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        always { cleanWs() }
    }
}
```

---

## 자주 쓰는 명령어

### Docker로 관리하는 경우

```bash
docker ps -f name=jenkins        # 상태 확인
docker logs -f jenkins           # 로그 실시간 확인
docker restart jenkins           # 재시작
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword  # 초기 비밀번호
```

### Jenkins CLI

```bash
# CLI jar 다운로드
curl -o jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar

# 빌드 트리거
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:TOKEN build my-job

# 안전하게 재시작
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:TOKEN safe-restart
```

### 유용한 환경변수 (Jenkinsfile)

| 변수 | 값 |
|------|-----|
| `env.BUILD_NUMBER` | 빌드 번호 |
| `env.BUILD_URL` | 빌드 결과 URL |
| `env.BRANCH_NAME` | 현재 브랜치명 |
| `env.GIT_COMMIT` | 현재 커밋 SHA |

---

## 정리

Jenkins는 설정 비용이 GitHub Actions보다 높지만, **온프레미스 환경, 복잡한 파이프라인, 레거시 연동**이 필요한 상황에서 아직도 최선의 선택이다. Jenkinsfile을 코드로 관리하고 플러그인 생태계를 잘 활용하면, 어떤 기술 스택에도 맞는 CI/CD 파이프라인을 구성할 수 있다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_jenkins);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_docker);

-- =============================================
-- 5. 포스트 3: Docker & Cloud
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'Docker와 클라우드 개념 완전 정리 — 컨테이너부터 AWS까지',
  'docker-and-cloud-fundamentals-complete-guide',
  'VM과 컨테이너의 차이, 이미지/볼륨/네트워크 핵심 개념, Dockerfile 멀티스테이지 빌드, Docker Compose, AWS EC2/S3/RDS/ECR 연동까지 한 번에 정리했다.',
  '# Docker와 클라우드 개념 완전 정리 — 컨테이너부터 AWS까지

> 현대 백엔드 개발에서 Docker와 클라우드는 필수 소양이다. 개념부터 실전 연동까지 한 번에 정리한다.

---

## Docker가 뭔가요?

Docker는 **컨테이너(Container)** 기술을 기반으로 하는 오픈소스 플랫폼이다. 애플리케이션과 그 실행에 필요한 모든 것(런타임, 라이브러리, 설정 등)을 하나의 패키지로 묶어, **어떤 환경에서도 동일하게 실행**되도록 해준다.

### "내 PC에선 되는데요" 문제 해결

```
개발자 PC: Node.js 18 → 정상 동작
서버: Node.js 16 → 동작 안 함

Docker 사용 시:
개발자 PC: Node.js 18 컨테이너 → 정상 동작
서버: Node.js 18 컨테이너 → 동일하게 정상 동작
```

---

## Docker vs VM (가상 머신)

### 핵심 차이

| 항목 | VM | Docker 컨테이너 |
|------|-----|----------------|
| OS 포함 여부 | 각 VM마다 Guest OS 포함 | Host OS 공유 |
| 시작 시간 | 수십 초 ~ 수 분 | 수 초 이하 |
| 크기 | 수 GB | 수십 ~ 수백 MB |
| 격리 수준 | 강함 (하드웨어 레벨) | 중간 (프로세스 레벨) |
| 성능 오버헤드 | 높음 | 매우 낮음 |

Docker 컨테이너는 Guest OS가 없기 때문에 가볍고 빠르지만, 호스트 OS의 커널을 공유한다.

---

## 핵심 개념

### 이미지 (Image)

컨테이너를 만들기 위한 **읽기 전용 템플릿**이다. 클래스(Class)에 비유하면 이미지는 클래스, 컨테이너는 인스턴스다.

```bash
docker pull node:20-alpine   # Docker Hub에서 다운로드
docker images                # 이미지 목록
docker rmi node:20-alpine    # 이미지 삭제
```

### 컨테이너 (Container)

이미지를 실행한 인스턴스다.

```bash
docker run --name my-app -p 3000:3000 -d my-node-app  # 실행
docker ps                # 실행 중인 컨테이너 목록
docker ps -a             # 전체 목록 (중지 포함)
docker exec -it my-app /bin/sh  # 내부 쉘 접속
docker logs -f my-app    # 로그 실시간 확인
docker stop my-app       # 중지
docker rm my-app         # 삭제
docker rm -f my-app      # 강제 삭제
```

### 볼륨 (Volume)

컨테이너가 삭제되면 내부 데이터도 사라진다. **볼륨**으로 데이터를 영속 저장한다.

```bash
docker volume create my-data      # 볼륨 생성
docker volume ls                  # 볼륨 목록
docker run -v my-data:/app/data my-app   # 볼륨 사용
docker run -v $(pwd)/data:/app/data my-app  # Bind Mount
docker volume prune               # 미사용 볼륨 삭제
```

| 항목 | Named Volume | Bind Mount |
|------|-------------|------------|
| 관리 주체 | Docker | 사용자 |
| 이식성 | 높음 | 낮음 |
| 주 용도 | DB 데이터 영속 저장 | 개발 시 코드 동기화 |

### 네트워크 (Network)

같은 사용자 정의 bridge 네트워크에 있는 컨테이너끼리는 컨테이너 이름으로 통신한다.

```bash
docker network create my-network
docker run --network my-network --name app my-app
docker run --network my-network --name db postgres
# app에서 db로 연결: postgresql://db:5432/mydb
```

---

## Dockerfile 작성법

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `FROM` | 베이스 이미지 지정 |
| `WORKDIR` | 작업 디렉토리 설정 |
| `COPY` | 파일 복사 |
| `RUN` | 빌드 시 명령 실행 |
| `ENV` | 환경변수 설정 |
| `EXPOSE` | 포트 문서화 |
| `CMD` | 컨테이너 시작 명령 |
| `USER` | 실행 사용자 지정 |

### Node.js 프로젝트 멀티스테이지 빌드

```dockerfile
# 1단계: 빌드
FROM node:20-alpine AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# 2단계: 프로덕션 이미지
FROM node:20-alpine AS runner

WORKDIR /app

# 보안: root가 아닌 사용자로 실행
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

멀티스테이지 빌드로 이미지 크기: ~1.2GB → ~150MB

### .dockerignore

```
node_modules
.next
.git
.env
.env.local
coverage
```

---

## Docker Compose

여러 컨테이너를 **하나의 YAML 파일로 정의하고 관리**한다.

```yaml
version: ''3.8''

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

### 주요 명령어

```bash
docker compose up -d           # 시작
docker compose up -d --build   # 이미지 새로 빌드 후 시작
docker compose down            # 중지
docker compose down -v         # 볼륨까지 삭제
docker compose ps              # 상태 확인
docker compose logs -f app     # 로그 확인
docker compose exec app /bin/sh  # 컨테이너 접속
```

---

## AWS 핵심 서비스

### EC2 (Elastic Compute Cloud)

가상 서버를 제공하는 서비스. 클라우드에서 컴퓨터 한 대를 빌리는 것과 같다.

- **인스턴스 타입**: t3.micro (무료 티어), t3.small, m5.large 등
- **AMI**: EC2 인스턴스의 OS + 초기 설정 템플릿
- **보안 그룹**: 방화벽. 인바운드/아웃바운드 규칙 설정
- **키 페어**: SSH 접속용 RSA 키

```bash
ssh -i my-key.pem ec2-user@ec2-xx-xx-xx-xx.compute-1.amazonaws.com
```

### S3 (Simple Storage Service)

파일을 버킷에 저장하는 객체 스토리지.

```bash
aws s3 ls                       # 버킷 목록
aws s3 cp file.txt s3://my-bucket/  # 업로드
aws s3 sync ./dist s3://my-bucket/  # 디렉토리 동기화
```

### RDS (Relational Database Service)

관리형 관계형 DB. 자동 백업, 장애 복구, Multi-AZ 고가용성 지원.

### 기타 주요 서비스

| 서비스 | 용도 |
|--------|------|
| **VPC** | 가상 사설 네트워크 |
| **CloudFront** | CDN |
| **ECR** | Docker 이미지 저장소 |
| **ECS** | 컨테이너 오케스트레이션 |
| **Lambda** | 서버리스 함수 |
| **IAM** | 권한 관리 |

---

## Docker + AWS 연동 실전

### ECR에 이미지 푸시

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 \
  | docker login --username AWS --password-stdin \
    123456789.dkr.ecr.ap-northeast-2.amazonaws.com

# 이미지 태그 & 푸시
docker tag my-app:latest 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:latest
docker push 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:latest
```

### EC2에 Docker 설치

```bash
# Amazon Linux 2023 기준
sudo dnf update -y
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

### EC2에서 ECR 이미지 실행

```bash
docker run -d \
  --name my-app \
  -p 80:3000 \
  -e DATABASE_URL="postgresql://user:pass@rds-endpoint:5432/mydb" \
  --restart unless-stopped \
  123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:latest
```

### CI/CD + Docker + AWS 자동 배포 흐름

```
git push main
    ↓
GitHub Actions / Jenkins
    ↓ docker build → ECR push
    ↓ EC2 SSH 접속
    ↓ ECR pull → docker compose up
    ↓ Slack 알림
```

---

## 보안 체크리스트

### Docker
- [ ] root 사용자로 컨테이너 실행 금지
- [ ] `.dockerignore`로 `.env` 제외
- [ ] 공식 베이스 이미지 사용
- [ ] 주기적 이미지 업데이트

### AWS
- [ ] root 계정 MFA 활성화
- [ ] IAM 최소 권한 원칙
- [ ] EC2 보안 그룹: SSH 포트는 특정 IP만
- [ ] RDS 퍼블릭 접근 비활성화

---

## 정리

Docker는 **일관된 실행 환경**을 제공하고, 클라우드는 **확장 가능한 인프라**를 제공한다. `docker run` → `Dockerfile` → `docker compose` 순서로 손에 익히면서 AWS EC2에 직접 배포해보는 경험을 쌓으면 전체 그림이 빠르게 잡힌다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_docker);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_aws);

-- =============================================
-- 6. 포스트 4: 비동기 프로그래밍
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  '비동기 프로그래밍 완전 정복 — 이벤트 루프부터 async/await까지',
  'async-programming-complete-guide',
  '콜백, Promise, async/await, 이벤트 루프까지 — JavaScript 비동기의 핵심을 예제 코드와 함께 완전히 정리했다.',
  '# 비동기 프로그래밍 완전 정복 — 이벤트 루프부터 async/await까지

> JavaScript는 싱글 스레드 언어다. 그럼에도 어떻게 동시에 여러 작업을 처리하는 것처럼 보일까? 비동기의 핵심을 파헤친다.

---

## JavaScript는 왜 비동기가 필요한가?

JavaScript는 **싱글 스레드**다. 한 번에 하나의 작업만 실행할 수 있다.

```javascript
// 동기 코드: fetch가 완료될 때까지 모든 게 멈춤
const response = fetch(''https://api.example.com/data''); // 이게 3초 걸리면?
console.log(''이 코드는 3초 후에 실행됨'');
renderUI(); // UI도 3초간 멈춤 (사용자는 빈 화면 봄)
```

이런 문제를 해결하기 위해 **비동기 프로그래밍**이 등장했다.

---

## 이벤트 루프 (Event Loop)

JavaScript의 비동기 처리를 이해하려면 이벤트 루프를 알아야 한다.

### 구성 요소

```
┌─────────────────────────────────────────────┐
│              JavaScript Engine               │
│                                              │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │    Call Stack     │  │    Heap          │  │
│  │                  │  │  (메모리 할당)   │  │
│  │  main()          │  │                 │  │
│  │  setTimeout cb   │  │                 │  │
│  └──────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│              Web APIs (브라우저 제공)         │
│  setTimeout, fetch, DOM events, ...          │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  Microtask Queue  │  Macrotask Queue (Task)   │
│  (Promise .then)  │  (setTimeout, setInterval)│
└──────────────────────────────────────────────┘
```

### 실행 순서

```javascript
console.log(''1'');  // Call Stack

setTimeout(() => {
  console.log(''2'');  // Macrotask Queue
}, 0);

Promise.resolve().then(() => {
  console.log(''3'');  // Microtask Queue
});

console.log(''4'');  // Call Stack

// 출력 순서: 1 → 4 → 3 → 2
```

**핵심 규칙:**
1. Call Stack이 비면 Microtask Queue를 먼저 전부 처리
2. Microtask Queue가 비면 Macrotask Queue에서 하나 처리
3. 반복

---

## 콜백 (Callback)

비동기 처리의 초기 방식. 함수를 인자로 넘겨 완료 후 실행한다.

```javascript
function fetchData(url, callback) {
  setTimeout(() => {
    const data = { id: 1, name: ''nywoo'' };
    callback(null, data);  // 성공
    // callback(new Error(''실패''), null);  // 에러
  }, 1000);
}

fetchData(''https://api.example.com'', (error, data) => {
  if (error) {
    console.error(error);
    return;
  }
  console.log(data);
});
```

### 콜백 지옥 (Callback Hell)

```javascript
// 중첩이 깊어질수록 읽기 어려워짐
getUser(userId, (err, user) => {
  if (err) return handleError(err);
  getPosts(user.id, (err, posts) => {
    if (err) return handleError(err);
    getComments(posts[0].id, (err, comments) => {
      if (err) return handleError(err);
      // 더 깊어지면...
    });
  });
});
```

---

## Promise

콜백 지옥을 해결하기 위해 ES6에서 도입된 패턴이다.

### 기본 구조

```javascript
const promise = new Promise((resolve, reject) => {
  // 비동기 작업
  setTimeout(() => {
    const success = true;
    if (success) {
      resolve({ id: 1, name: ''nywoo'' });  // 성공
    } else {
      reject(new Error(''데이터를 가져오지 못했습니다''));  // 실패
    }
  }, 1000);
});

promise
  .then(data => console.log(data))     // 성공 처리
  .catch(error => console.error(error)) // 에러 처리
  .finally(() => console.log(''완료''));  // 항상 실행
```

### Promise 체이닝

```javascript
// 콜백 지옥을 체이닝으로 해결
getUser(userId)
  .then(user => getPosts(user.id))
  .then(posts => getComments(posts[0].id))
  .then(comments => console.log(comments))
  .catch(err => handleError(err));
```

### Promise 메서드

```javascript
// 여러 Promise를 동시에 실행
const [users, posts] = await Promise.all([
  fetchUsers(),
  fetchPosts()
]);

// 가장 먼저 완료된 것 사용
const fastest = await Promise.race([
  fetchFromServer1(),
  fetchFromServer2()
]);

// 모두 완료될 때까지 기다림 (성공/실패 모두)
const results = await Promise.allSettled([
  fetch(''/api/a''),
  fetch(''/api/b''),
  fetch(''/api/c'')
]);

results.forEach(result => {
  if (result.status === ''fulfilled'') {
    console.log(result.value);
  } else {
    console.error(result.reason);
  }
});
```

---

## async / await

Promise를 더 동기 코드처럼 읽히게 만드는 ES2017 문법이다.

```javascript
// Promise 체이닝
function getUserData(userId) {
  return getUser(userId)
    .then(user => getPosts(user.id))
    .then(posts => getComments(posts[0].id));
}

// async/await으로 동일한 코드
async function getUserData(userId) {
  const user = await getUser(userId);
  const posts = await getPosts(user.id);
  const comments = await getComments(posts[0].id);
  return comments;
}
```

### 에러 처리

```javascript
async function fetchUser(id) {
  try {
    const response = await fetch(`/api/users/${id}`);

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const user = await response.json();
    return user;
  } catch (error) {
    console.error(''유저 조회 실패:'', error);
    throw error;  // 상위로 에러 전파
  }
}
```

### 병렬 실행 (중요!)

```javascript
// 잘못된 방법: 순차 실행 (2초 + 2초 = 4초)
const user = await fetchUser(1);    // 2초 대기
const posts = await fetchPosts(1);  // 2초 대기

// 올바른 방법: 병렬 실행 (max(2초, 2초) = 2초)
const [user, posts] = await Promise.all([
  fetchUser(1),
  fetchPosts(1)
]);
```

---

## 실전 패턴

### 재시도 로직

```javascript
async function fetchWithRetry(url, retries = 3, delay = 1000) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return await response.json();
    } catch (error) {
      if (attempt === retries) throw error;
      console.log(`시도 ${attempt} 실패, ${delay}ms 후 재시도...`);
      await new Promise(resolve => setTimeout(resolve, delay));
      delay *= 2;  // 지수 백오프
    }
  }
}
```

### 타임아웃

```javascript
function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error(`${ms}ms 타임아웃`)), ms)
  );
  return Promise.race([promise, timeout]);
}

const data = await withTimeout(fetch(''/api/slow''), 5000);
```

### 순차 실행 (배열)

```javascript
const userIds = [1, 2, 3, 4, 5];

// 순차 실행 (DB 부하 제어 시)
for (const id of userIds) {
  const user = await fetchUser(id);
  await processUser(user);
}

// 병렬 실행 (빠르지만 동시 요청 많음)
const users = await Promise.all(userIds.map(fetchUser));
```

---

## React에서의 비동기

### useEffect와 비동기

```javascript
// 잘못된 방법: useEffect에 async 직접 전달
useEffect(async () => {
  const data = await fetchData(); // 작동하지만 경고 발생
}, []);

// 올바른 방법
useEffect(() => {
  const load = async () => {
    try {
      const data = await fetchData();
      setData(data);
    } catch (error) {
      setError(error);
    } finally {
      setLoading(false);
    }
  };
  load();
}, []);
```

### 커스텀 훅으로 추상화

```typescript
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;  // cleanup으로 메모리 누수 방지

    const load = async () => {
      try {
        const response = await fetch(url);
        const json = await response.json();
        if (!cancelled) setData(json);
      } catch (err) {
        if (!cancelled) setError(err as Error);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    load();
    return () => { cancelled = true; };
  }, [url]);

  return { data, loading, error };
}
```

### TanStack Query (권장)

위 패턴을 직접 구현하는 대신, TanStack Query를 사용하면 캐싱, 재시도, 로딩 상태를 자동으로 관리해준다.

```typescript
const { data, isLoading, error } = useQuery({
  queryKey: [''user'', userId],
  queryFn: () => fetchUser(userId),
  staleTime: 5 * 60 * 1000,  // 5분간 fresh 상태 유지
});
```

---

## 흔한 실수

### 1. await 빠뜨리기

```javascript
// 실수: Promise 객체가 data에 들어감
const data = fetchUser(1);
console.log(data.name);  // undefined

// 올바름
const data = await fetchUser(1);
console.log(data.name);  // ''nywoo''
```

### 2. 에러 처리 누락

```javascript
// 에러가 발생하면 전체 앱이 죽을 수 있음
const data = await fetch(''/api/data'').then(r => r.json());

// try-catch 또는 .catch() 필수
try {
  const data = await fetch(''/api/data'').then(r => r.json());
} catch (error) {
  // 적절한 에러 처리
}
```

### 3. 불필요한 순차 실행

```javascript
// 느림: 3초 소요
const a = await fetchA();  // 1초
const b = await fetchB();  // 1초
const c = await fetchC();  // 1초

// 빠름: 1초 소요
const [a, b, c] = await Promise.all([fetchA(), fetchB(), fetchC()]);
```

---

## 정리

| 방식 | 등장 시기 | 특징 |
|------|----------|------|
| Callback | 초창기 | 단순하지만 중첩 시 가독성 최악 |
| Promise | ES6 (2015) | 체이닝으로 가독성 개선 |
| async/await | ES2017 | 동기 코드처럼 읽힘, 현재 표준 |

비동기를 제대로 이해하면 성능 최적화, 에러 처리, 사용자 경험 개선 모두 가능해진다. `Promise.all`로 병렬 실행을 챙기고, 항상 에러 처리를 빠뜨리지 않는 것이 핵심이다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_js);

-- =============================================
-- 7. 포스트 5: JWT 로그인
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'JWT 로그인 흐름 직접 구현하기 — AccessToken, RefreshToken 전략',
  'jwt-auth-flow-implementation',
  'JWT가 뭔지부터 AccessToken/RefreshToken 발급, 저장 전략, 자동 갱신까지 — 보안을 고려한 인증 시스템의 전체 흐름을 직접 구현하며 정리했다.',
  '# JWT 로그인 흐름 직접 구현하기 — AccessToken, RefreshToken 전략

> JWT 기반 인증은 현대 웹 서비스의 표준이다. 단순히 "쿠키에 넣으면 되는 거 아니야?"를 넘어, 왜 이렇게 설계되었는지 이해하고 직접 구현해보자.

---

## JWT (JSON Web Token)이란?

JWT는 **서버와 클라이언트 간에 정보를 안전하게 전달하기 위한 토큰 형식**이다.

### 구조

JWT는 `.`으로 구분된 3개의 파트로 구성된다.

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9  (Header)
.
eyJzdWIiOiJ1c2VyXzEyMyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNjk5MDAwMDAwfQ  (Payload)
.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c  (Signature)
```

- **Header**: 알고리즘 정보 (`{ "alg": "HS256", "typ": "JWT" }`)
- **Payload**: 실제 데이터 (`{ "sub": "user_123", "role": "user", "exp": 1699003600 }`)
- **Signature**: `HMAC-SHA256(base64(header) + "." + base64(payload), secret_key)`

### 세션 방식 vs JWT 방식

| 항목 | 세션 | JWT |
|------|------|-----|
| 상태 저장 | 서버 (DB/메모리) | 클라이언트 (토큰) |
| 서버 부하 | 높음 (세션 조회) | 낮음 (토큰 검증만) |
| 수평 확장 | 어려움 (세션 공유 필요) | 쉬움 (상태 없음) |
| 즉시 무효화 | 가능 | 어려움 (만료 전까지 유효) |

---

## AccessToken vs RefreshToken

### 왜 두 가지가 필요한가?

AccessToken만 있다면:
- 만료 시간을 짧게 → 자주 로그인해야 해서 UX 나쁨
- 만료 시간을 길게 → 탈취 시 오랫동안 악용 가능

이 딜레마를 해결하기 위해 **두 토큰을 분리**한다.

| 토큰 | 만료 시간 | 용도 | 저장 위치 |
|------|----------|------|----------|
| **AccessToken** | 짧게 (15분~1시간) | API 요청 시 인증 | 메모리 (또는 쿠키) |
| **RefreshToken** | 길게 (7일~30일) | AccessToken 재발급 | HttpOnly Cookie |

### 전체 흐름

```
1. 로그인
   Client → Server: 이메일 + 비밀번호
   Server → Client: AccessToken (1시간) + RefreshToken (7일, HttpOnly Cookie)

2. API 요청
   Client → Server: Authorization: Bearer {AccessToken}
   Server: AccessToken 검증 → 응답

3. AccessToken 만료
   Client → Server: RefreshToken으로 재발급 요청
   Server: RefreshToken 검증 → 새 AccessToken 발급

4. RefreshToken 만료
   Client: 로그인 페이지로 리다이렉트
```

---

## 직접 구현하기 (Node.js + Express)

### 필요한 패키지

```bash
npm install jsonwebtoken bcryptjs cookie-parser
npm install -D @types/jsonwebtoken @types/bcryptjs
```

### 토큰 생성 및 검증 유틸

```typescript
// src/lib/jwt.ts
import jwt from ''jsonwebtoken'';

const ACCESS_TOKEN_SECRET = process.env.JWT_ACCESS_SECRET!;
const REFRESH_TOKEN_SECRET = process.env.JWT_REFRESH_SECRET!;

interface TokenPayload {
  userId: string;
  role: string;
}

export function generateAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, ACCESS_TOKEN_SECRET, { expiresIn: ''1h'' });
}

export function generateRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, REFRESH_TOKEN_SECRET, { expiresIn: ''7d'' });
}

export function verifyAccessToken(token: string): TokenPayload {
  return jwt.verify(token, ACCESS_TOKEN_SECRET) as TokenPayload;
}

export function verifyRefreshToken(token: string): TokenPayload {
  return jwt.verify(token, REFRESH_TOKEN_SECRET) as TokenPayload;
}
```

### 로그인 엔드포인트

```typescript
// POST /auth/login
app.post(''/auth/login'', async (req, res) => {
  const { email, password } = req.body;

  // 1. 유저 조회
  const user = await db.user.findUnique({ where: { email } });
  if (!user) {
    return res.status(401).json({ error: ''이메일 또는 비밀번호가 올바르지 않습니다'' });
  }

  // 2. 비밀번호 검증
  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    return res.status(401).json({ error: ''이메일 또는 비밀번호가 올바르지 않습니다'' });
  }

  // 3. 토큰 생성
  const payload = { userId: user.id, role: user.role };
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  // 4. RefreshToken을 DB에 저장 (화이트리스트)
  await db.refreshToken.create({
    data: { token: refreshToken, userId: user.id }
  });

  // 5. RefreshToken은 HttpOnly Cookie로 전송
  res.cookie(''refreshToken'', refreshToken, {
    httpOnly: true,   // JS에서 접근 불가 (XSS 방어)
    secure: true,     // HTTPS에서만 전송
    sameSite: ''strict'', // CSRF 방어
    maxAge: 7 * 24 * 60 * 60 * 1000  // 7일
  });

  // 6. AccessToken은 응답 바디로 전송
  res.json({ accessToken });
});
```

### AccessToken 검증 미들웨어

```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from ''express'';
import { verifyAccessToken } from ''../lib/jwt'';

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith(''Bearer '')) {
    return res.status(401).json({ error: ''인증이 필요합니다'' });
  }

  const token = authHeader.split('' '')[1];

  try {
    const payload = verifyAccessToken(token);
    req.user = payload;  // 이후 라우터에서 req.user로 접근
    next();
  } catch (error) {
    return res.status(401).json({ error: ''유효하지 않거나 만료된 토큰입니다'' });
  }
}
```

### AccessToken 재발급 엔드포인트

```typescript
// POST /auth/refresh
app.post(''/auth/refresh'', async (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  if (!refreshToken) {
    return res.status(401).json({ error: ''RefreshToken이 없습니다'' });
  }

  try {
    // 1. 토큰 서명 검증
    const payload = verifyRefreshToken(refreshToken);

    // 2. DB에서 유효한 토큰인지 확인 (화이트리스트)
    const stored = await db.refreshToken.findUnique({
      where: { token: refreshToken }
    });

    if (!stored) {
      return res.status(401).json({ error: ''유효하지 않은 RefreshToken입니다'' });
    }

    // 3. 새 AccessToken 발급
    const newAccessToken = generateAccessToken({
      userId: payload.userId,
      role: payload.role
    });

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    // RefreshToken 만료 또는 변조
    res.clearCookie(''refreshToken'');
    return res.status(401).json({ error: ''다시 로그인해주세요'' });
  }
});
```

### 로그아웃

```typescript
// POST /auth/logout
app.post(''/auth/logout'', authenticate, async (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  if (refreshToken) {
    // DB에서 RefreshToken 삭제
    await db.refreshToken.deleteMany({
      where: { token: refreshToken }
    });
  }

  res.clearCookie(''refreshToken'');
  res.json({ message: ''로그아웃 완료'' });
});
```

---

## 클라이언트 (React) 구현

### Axios 인터셉터로 자동 토큰 갱신

```typescript
// src/lib/api.ts
import axios from ''axios'';

const api = axios.create({
  baseURL: ''/api'',
  withCredentials: true,  // 쿠키 자동 전송
});

// 요청 인터셉터: AccessToken 자동 첨부
api.interceptors.request.use(config => {
  const token = localStorage.getItem(''accessToken'');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 응답 인터셉터: 401 시 자동 토큰 갱신
let isRefreshing = false;
let failedQueue: Array<{ resolve: Function; reject: Function }> = [];

api.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // 이미 갱신 중이면 큐에 추가
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then(token => {
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return api(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const { data } = await axios.post(''/auth/refresh'', {}, { withCredentials: true });
        const newToken = data.accessToken;

        localStorage.setItem(''accessToken'', newToken);

        // 큐에 있던 요청들 처리
        failedQueue.forEach(({ resolve }) => resolve(newToken));
        failedQueue = [];

        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        failedQueue.forEach(({ reject }) => reject(refreshError));
        failedQueue = [];
        localStorage.removeItem(''accessToken'');
        window.location.href = ''/login'';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export default api;
```

---

## 보안 고려사항

### AccessToken 저장 위치

| 저장 위치 | XSS 위험 | CSRF 위험 | 권장 |
|----------|---------|---------|------|
| localStorage | 높음 | 없음 | 비권장 |
| 메모리 (변수) | 없음 | 없음 | 권장 |
| HttpOnly Cookie | 없음 | 있음 | 상황에 따라 |

가장 안전한 방법: **AccessToken은 메모리(Zustand 등)에 저장, RefreshToken은 HttpOnly Cookie**

### CSRF 방어

RefreshToken을 쿠키에 저장할 경우 CSRF 공격 가능성이 있다.

```typescript
// SameSite=strict로 대부분의 CSRF 방어
res.cookie(''refreshToken'', token, {
  sameSite: ''strict'',  // 동일 사이트에서만 쿠키 전송
  secure: true,
  httpOnly: true
});

// 추가로 CSRF 토큰 사용 가능
```

### RefreshToken 탈취 대응: Rotation 전략

```typescript
// RefreshToken 사용 시 새 RefreshToken도 발급
const newRefreshToken = generateRefreshToken(payload);

// 기존 토큰 삭제, 새 토큰 저장
await db.refreshToken.update({
  where: { token: oldRefreshToken },
  data: { token: newRefreshToken }
});
```

---

## Supabase에서의 JWT

Supabase는 위 과정을 모두 자동으로 처리해준다.

```typescript
// Supabase가 알아서 해주는 것들:
// - AccessToken (1시간) + RefreshToken (60일) 발급
// - HttpOnly 쿠키로 RefreshToken 관리
// - 자동 토큰 갱신 (supabase-js가 처리)
// - RLS 정책으로 DB 레벨 권한 제어

const { data, error } = await supabase.auth.signInWithPassword({
  email: ''user@example.com'',
  password: ''password123''
});

// AccessToken 확인
const { data: { session } } = await supabase.auth.getSession();
console.log(session?.access_token);
```

Supabase를 쓰더라도 내부 동작을 이해하는 것이 중요하다. 직접 구현해보면 인증 흐름이 완전히 잡힌다.

---

## 정리

JWT 인증 시스템의 핵심:

1. **AccessToken은 짧게, RefreshToken은 길게**
2. **RefreshToken은 HttpOnly Cookie에 저장** (XSS 방어)
3. **RefreshToken은 DB 화이트리스트로 관리** (즉시 무효화 가능)
4. **클라이언트는 인터셉터로 자동 갱신 처리**
5. **CORS + SameSite + Secure 설정 필수**

직접 구현해보면 왜 Supabase, NextAuth 같은 라이브러리가 이렇게 설계되었는지 이해하게 된다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_auth);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_js);

-- =============================================
-- 8. 포스트 6: React 상태관리
-- =============================================
INSERT INTO posts (author_id, title, slug, summary, content, published, view_count)
VALUES (
  author,
  'React 상태관리 어떤 걸 써야 할까? — Zustand vs Jotai vs Redux',
  'react-state-management-comparison',
  '2026년 기준 React 상태관리의 선택지를 정리했다. 서버 상태 vs 클라이언트 상태의 구분부터 Zustand, Jotai, Redux Toolkit의 실전 비교까지.',
  '# React 상태관리 어떤 걸 써야 할까? — Zustand vs Jotai vs Redux

> 리덕스 써야 하나요? 주스탄드 써야 하나요? 이 고민의 답은 "상태의 종류를 먼저 구분하라"다.

---

## 먼저: 상태의 종류를 구분하자

많은 개발자가 모든 상태를 하나의 전역 스토어에 넣으려다 복잡성이 폭발하는 경험을 한다. 상태를 제대로 관리하려면 **종류부터 구분**해야 한다.

### 서버 상태 (Server State)

서버에서 가져오는 데이터. 비동기적이고, 캐싱이 필요하며, 여러 컴포넌트가 공유한다.

```
예: 유저 목록, 포스트 데이터, 상품 정보
특징: 항상 최신 데이터인지 확인 필요 (stale 가능)
```

### 클라이언트 상태 (Client State)

UI와 관련된 로컬 상태. 서버와 동기화할 필요 없다.

```
예: 모달 열림/닫힘, 사이드바 펼침 여부, 선택된 탭, 폼 입력값
특징: 순수하게 프론트엔드 영역
```

### 핵심 원칙

```
서버 상태 → TanStack Query (React Query)
클라이언트 전역 상태 → Zustand 또는 Jotai
로컬 컴포넌트 상태 → useState / useReducer
```

---

## TanStack Query (서버 상태의 정답)

서버 상태는 Zustand에 넣지 말고 TanStack Query를 쓰자.

```typescript
// 나쁜 방법: 서버 데이터를 Zustand에 넣기
const usePosts = create((set) => ({
  posts: [],
  loading: false,
  fetchPosts: async () => {
    set({ loading: true });
    const data = await getPosts();
    set({ posts: data, loading: false });
  }
}));

// 좋은 방법: TanStack Query 사용
const { data: posts, isLoading } = useQuery({
  queryKey: [''posts''],
  queryFn: getPosts,
  staleTime: 5 * 60 * 1000,  // 5분간 캐시 유지
});
```

TanStack Query가 자동으로 해주는 것들:
- 캐싱 및 자동 갱신
- 백그라운드 리패치
- 로딩/에러 상태
- 중복 요청 방지
- 낙관적 업데이트

---

## 클라이언트 상태 라이브러리 비교

### Zustand

가장 단순하고 직관적인 전역 상태 관리 라이브러리.

```typescript
import { create } from ''zustand'';

interface UIState {
  sidebarOpen: boolean;
  theme: ''light'' | ''dark'';
  user: User | null;
  toggleSidebar: () => void;
  setTheme: (theme: ''light'' | ''dark'') => void;
  setUser: (user: User | null) => void;
}

const useUIStore = create<UIState>((set) => ({
  sidebarOpen: false,
  theme: ''dark'',
  user: null,
  toggleSidebar: () => set(state => ({ sidebarOpen: !state.sidebarOpen })),
  setTheme: (theme) => set({ theme }),
  setUser: (user) => set({ user }),
}));

// 컴포넌트에서 사용
function Header() {
  const { sidebarOpen, toggleSidebar } = useUIStore();
  return <button onClick={toggleSidebar}>{sidebarOpen ? ''닫기'' : ''열기''}</button>;
}
```

**특징:**
- 보일러플레이트 거의 없음
- Flux/Redux 패턴 강제 없음
- TypeScript 지원 우수
- 번들 크기 작음 (~1KB)

### Jotai

"Atom" 단위로 상태를 관리. 리코일(Recoil)에 영향받은 라이브러리.

```typescript
import { atom, useAtom } from ''jotai'';

// 원자(atom) 단위로 상태 정의
const sidebarOpenAtom = atom(false);
const themeAtom = atom<''light'' | ''dark''>(''dark'');
const userAtom = atom<User | null>(null);

// 파생 상태 (derived atom)
const isAdminAtom = atom((get) => get(userAtom)?.role === ''admin'');

// 컴포넌트에서 사용
function Header() {
  const [sidebarOpen, setSidebarOpen] = useAtom(sidebarOpenAtom);
  const isAdmin = useAtomValue(isAdminAtom);

  return (
    <button onClick={() => setSidebarOpen(prev => !prev)}>
      {sidebarOpen ? ''닫기'' : ''열기''}
    </button>
  );
}
```

**특징:**
- useState와 사용법 유사 → 학습 곡선 낮음
- 원자 단위 구독 → 불필요한 리렌더링 없음
- Suspense와 자연스럽게 통합
- 코드 스플리팅에 유리

### Redux Toolkit

Redux의 복잡성을 대폭 줄인 공식 라이브러리.

```typescript
import { createSlice, PayloadAction } from ''@reduxjs/toolkit'';

const uiSlice = createSlice({
  name: ''ui'',
  initialState: {
    sidebarOpen: false,
    theme: ''dark'' as ''light'' | ''dark'',
  },
  reducers: {
    toggleSidebar: (state) => {
      state.sidebarOpen = !state.sidebarOpen;  // Immer로 불변성 자동 처리
    },
    setTheme: (state, action: PayloadAction<''light'' | ''dark''>) => {
      state.theme = action.payload;
    },
  },
});

export const { toggleSidebar, setTheme } = uiSlice.actions;

// 컴포넌트에서 사용
function Header() {
  const dispatch = useDispatch();
  const sidebarOpen = useSelector(state => state.ui.sidebarOpen);

  return (
    <button onClick={() => dispatch(toggleSidebar())}>
      {sidebarOpen ? ''닫기'' : ''열기''}
    </button>
  );
}
```

**특징:**
- 예측 가능한 단방향 데이터 흐름
- Redux DevTools 강력한 디버깅
- 대규모 팀/복잡한 상태에 적합
- 보일러플레이트 여전히 존재 (RTK Query, 미들웨어 등)

---

## 직접 비교

| 항목 | Zustand | Jotai | Redux Toolkit |
|------|---------|-------|---------------|
| 학습 곡선 | 낮음 | 낮음 | 중간~높음 |
| 번들 크기 | ~1KB | ~3KB | ~50KB |
| 보일러플레이트 | 거의 없음 | 없음 | 있음 |
| 디버깅 | 보통 | 보통 | 우수 (DevTools) |
| 파생 상태 | 직접 구현 | atom으로 우아하게 | selector |
| 대규모 앱 | 가능 | 가능 | 강점 |
| 2026 트렌드 | 🔥 가장 인기 | 상승세 | 레거시 많음 |

---

## 언제 무엇을 쓸까?

### Zustand를 선택해야 할 때

```
✅ 사이드 프로젝트, 중소 규모 앱
✅ Redux 대비 심플한 코드 원할 때
✅ 팀원이 적거나 혼자 개발
✅ 빠른 프로토타이핑
```

### Jotai를 선택해야 할 때

```
✅ 세밀한 최적화가 필요한 경우 (많은 atom, 자주 변경)
✅ Suspense를 적극 활용하는 프로젝트
✅ 컴포넌트 간 상태 공유가 복잡한 경우
✅ React 18+ 동시성 기능 활용
```

### Redux Toolkit을 선택해야 할 때

```
✅ 대규모 팀 (일관된 패턴 강제 필요)
✅ 복잡한 비즈니스 로직과 상태 흐름
✅ 강력한 디버깅 도구가 필수인 경우
✅ 레거시 Redux 마이그레이션
```

---

## 실전 예시: nywoo.dev 블로그에서의 사용

```typescript
// 이 블로그 프로젝트의 상태 분리 방식

// 1. 서버 상태 → TanStack Query
const { data: posts } = useQuery({
  queryKey: [''posts''],
  queryFn: fetchPosts,
});

// 2. 인증 전역 상태 → Zustand
const useAuthStore = create<AuthState>((set) => ({
  user: null,
  profile: null,
  isLoading: true,
  setUser: (user) => set({ user }),
  setProfile: (profile) => set({ profile }),
  reset: () => set({ user: null, profile: null }),
}));

// 3. 컴포넌트 로컬 상태 → useState
function BlogList() {
  const [search, setSearch] = useState('''');    // 검색어
  const [selectedTag, setSelectedTag] = useState<string | null>(null);
  // ...
}
```

---

## 흔한 실수

### 1. 서버 데이터를 전역 스토어에 넣기

```typescript
// 나쁜 예: 서버 데이터를 Zustand에 저장
const useStore = create((set) => ({
  posts: [],   // 서버에서 온 데이터인데 Zustand에 넣음
  fetchPosts: async () => { ... }
}));

// 좋은 예: TanStack Query 사용
const { data: posts } = useQuery({ queryKey: [''posts''], queryFn: fetchPosts });
```

### 2. 모든 상태를 전역으로 올리기

```typescript
// 나쁜 예: 컴포넌트 내부에서만 쓰는 상태도 전역으로
const useStore = create((set) => ({
  isModalOpen: false,  // 이 모달 하나만을 위한 전역 상태
}));

// 좋은 예: 해당 컴포넌트의 useState 사용
function PostCard() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  // ...
}
```

### 3. 스토어 분리 안 하기

```typescript
// 나쁜 예: 모든 걸 하나의 스토어에
const useStore = create((set) => ({
  user: null,
  posts: [],
  comments: [],
  ui: { sidebarOpen: false },
  // ...
}));

// 좋은 예: 도메인별로 분리
const useAuthStore = create(...)
const useUIStore = create(...)
```

---

## 정리

2026년 React 상태관리의 모범 답안:

```
클라이언트 전역 상태: Zustand (작~중 규모) | Jotai (세밀한 최적화)
서버 상태: TanStack Query (캐싱, 동기화)
로컬 상태: useState, useReducer
폼 상태: React Hook Form
```

"어떤 라이브러리를 쓸까?"보다 **"이 상태가 서버 상태인가 클라이언트 상태인가?"** 를 먼저 구분하는 습관이 더 중요하다.',
  true,
  0
)
RETURNING id INTO post_id;
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_react);
INSERT INTO post_tags (post_id, tag_id) VALUES (post_id, tag_js);

RAISE NOTICE '포스트 6개 삽입 완료. author: %', author;

END $$;
