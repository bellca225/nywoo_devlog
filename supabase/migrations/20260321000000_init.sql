-- =============================================
-- nywoo_devlog 스키마
-- Supabase SQL Editor에서 실행
-- =============================================

-- 프로필 테이블 (auth.users 확장)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'viewer')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 태그 테이블
CREATE TABLE tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 포스트 테이블
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT NOT NULL,
  summary TEXT,                    -- AI 자동 생성 요약
  cover_image_url TEXT,
  published BOOLEAN DEFAULT FALSE,
  view_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 포스트-태그 연결 테이블
CREATE TABLE post_tags (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- =============================================
-- RLS 정책
-- =============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_tags ENABLE ROW LEVEL SECURITY;

-- profiles: 본인만 수정 가능, 읽기는 누구나
CREATE POLICY "프로필 공개 읽기" ON profiles FOR SELECT USING (true);
CREATE POLICY "본인 프로필만 수정" ON profiles FOR UPDATE USING (auth.uid() = id);

-- posts: 발행된 글은 누구나 읽기, 작성/수정/삭제는 admin만
CREATE POLICY "발행된 포스트 공개 읽기" ON posts FOR SELECT
  USING (published = true OR auth.uid() = author_id);
CREATE POLICY "관리자만 포스트 작성" ON posts FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "본인 포스트만 수정" ON posts FOR UPDATE
  USING (auth.uid() = author_id);
CREATE POLICY "본인 포스트만 삭제" ON posts FOR DELETE
  USING (auth.uid() = author_id);

-- tags: 누구나 읽기, admin만 작성
CREATE POLICY "태그 공개 읽기" ON tags FOR SELECT USING (true);
CREATE POLICY "관리자만 태그 작성" ON tags FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- post_tags: 누구나 읽기
CREATE POLICY "포스트태그 공개 읽기" ON post_tags FOR SELECT USING (true);
CREATE POLICY "관리자만 포스트태그 작성" ON post_tags FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "관리자만 포스트태그 삭제" ON post_tags FOR DELETE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================
-- 트리거: updated_at 자동 갱신
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================
-- 트리거: 회원가입 시 프로필 자동 생성
-- =============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'viewer')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
