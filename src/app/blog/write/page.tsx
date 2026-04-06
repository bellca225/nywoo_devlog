"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { createClient } from "@/lib/supabase/client";
import { useAuthStore } from "@/store/authStore";
import { Loader2 } from "lucide-react";

export default function WritePage() {
  const router = useRouter();
  const { user, profile } = useAuthStore();
  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [summary, setSummary] = useState("");
  const [content, setContent] = useState("");
  const [tags, setTags] = useState("");
  const [published, setPublished] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  if (!user || profile?.role !== "admin") {
    return (
      <div className="max-w-3xl mx-auto px-6 pt-28 text-center text-zinc-400">
        관리자만 접근할 수 있어요.
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    const supabase = createClient();

    // 1. 포스트 생성
    const { data: post, error: postError } = await supabase
      .from("posts")
      .insert({
        author_id: user.id,
        title,
        slug: slug || title.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, ""),
        summary,
        content,
        published,
      })
      .select()
      .single();

    if (postError) {
      setError(postError.message);
      setLoading(false);
      return;
    }

    // 2. 태그 처리
    if (tags.trim()) {
      const tagNames = tags.split(",").map((t) => t.trim()).filter(Boolean);

      for (const name of tagNames) {
        // upsert 태그
        const { data: tag } = await supabase
          .from("tags")
          .upsert({ name }, { onConflict: "name" })
          .select()
          .single();

        if (tag) {
          await supabase.from("post_tags").insert({ post_id: post.id, tag_id: tag.id });
        }
      }
    }

    router.push(`/blog/${post.slug}`);
    router.refresh();
  };

  return (
    <div className="max-w-3xl mx-auto px-6 pt-28 pb-20">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <h1 className="text-3xl font-bold mb-8">새 포스트 작성</h1>

        <form onSubmit={handleSubmit} className="flex flex-col gap-5">
          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium">제목</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              className="px-4 py-2.5 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition"
              placeholder="포스트 제목"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium">Slug (비우면 자동 생성)</label>
            <input
              value={slug}
              onChange={(e) => setSlug(e.target.value)}
              className="px-4 py-2.5 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition"
              placeholder="my-post-slug"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium">요약</label>
            <input
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
              className="px-4 py-2.5 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition"
              placeholder="포스트 한 줄 요약"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium">태그 (쉼표로 구분)</label>
            <input
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              className="px-4 py-2.5 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition"
              placeholder="JavaScript, React, TypeScript"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium">본문 (Markdown)</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              required
              rows={20}
              className="px-4 py-3 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm font-mono focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition resize-none"
              placeholder="## 제목&#10;&#10;내용을 마크다운으로 작성하세요..."
            />
          </div>

          <label className="flex items-center gap-2 text-sm cursor-pointer">
            <input
              type="checkbox"
              checked={published}
              onChange={(e) => setPublished(e.target.checked)}
              className="rounded"
            />
            바로 발행
          </label>

          {error && <p className="text-sm text-red-500">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="flex items-center justify-center gap-2 py-2.5 rounded-xl bg-black dark:bg-white text-white dark:text-black text-sm font-medium hover:opacity-80 transition disabled:opacity-50"
          >
            {loading ? <Loader2 size={16} className="animate-spin" /> : "저장"}
          </button>
        </form>
      </motion.div>
    </div>
  );
}
