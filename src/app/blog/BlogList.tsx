"use client";

import { useState, useMemo, useDeferredValue } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, Eye } from "lucide-react";

interface Post {
  id: string;
  title: string;
  slug: string;
  summary: string | null;
  view_count: number;
  created_at: string;
  profiles: { username: string }[] | null;
  post_tags: { tags: { id: string; name: string }[] | null }[];
}

export default function BlogList({ initialPosts }: { initialPosts: Post[] }) {
  const [selectedTag, setSelectedTag] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const deferredSearch = useDeferredValue(search);

  const allTags = useMemo(
    () =>
      Array.from(
        new Set(
          initialPosts.flatMap((p) =>
            p.post_tags.flatMap((pt) =>
              Array.isArray(pt.tags) ? pt.tags.map((t) => t.name) : []
            )
          )
        )
      ) as string[],
    [initialPosts]
  );

  const filtered = useMemo(
    () =>
      initialPosts.filter((post) => {
        const matchTag = selectedTag
          ? post.post_tags.some((pt) =>
              Array.isArray(pt.tags) && pt.tags.some((t) => t.name === selectedTag)
            )
          : true;
        const matchSearch = deferredSearch
          ? post.title.toLowerCase().includes(deferredSearch.toLowerCase()) ||
            post.summary?.toLowerCase().includes(deferredSearch.toLowerCase())
          : true;
        return matchTag && matchSearch;
      }),
    [initialPosts, selectedTag, deferredSearch]
  );

  return (
    <div className="max-w-5xl mx-auto px-6 pt-28 pb-20">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="mb-10"
      >
        <h1 className="text-4xl font-bold mb-2">Blog</h1>
        <p className="text-zinc-400">개발 공부, 트러블슈팅, 기술 정리</p>
      </motion.div>

      {/* 검색 */}
      <motion.input
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1 }}
        type="text"
        placeholder="검색..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="w-full mb-6 px-4 py-2.5 rounded-xl border border-black/20 dark:border-white/20 bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-black/20 dark:focus:ring-white/20 transition"
      />

      {/* 태그 필터 */}
      {allTags.length > 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.15 }}
          className="flex flex-wrap gap-2 mb-10"
        >
          <button
            onClick={() => setSelectedTag(null)}
            className={`px-3 py-1 rounded-full text-xs font-medium transition ${
              !selectedTag
                ? "bg-black dark:bg-white text-white dark:text-black"
                : "border border-black/20 dark:border-white/20 text-zinc-500 hover:border-black/50 dark:hover:border-white/50"
            }`}
          >
            전체
          </button>
          {allTags.map((tag) => (
            <button
              key={tag}
              onClick={() => setSelectedTag(tag === selectedTag ? null : tag)}
              className={`px-3 py-1 rounded-full text-xs font-medium transition ${
                selectedTag === tag
                  ? "bg-black dark:bg-white text-white dark:text-black"
                  : "border border-black/20 dark:border-white/20 text-zinc-500 hover:border-black/50 dark:hover:border-white/50"
              }`}
            >
              {tag}
            </button>
          ))}
        </motion.div>
      )}

      {/* 포스트 목록 */}
      {filtered.length === 0 ? (
        <p className="text-zinc-400 text-sm">포스트가 없어요.</p>
      ) : (
        <div className="flex flex-col divide-y divide-black/10 dark:divide-white/10">
          {filtered.map((post) => (
            <motion.article
              key={post.id}
              layout
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="group py-6"
            >
              <Link href={`/blog/${post.slug}`} className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="flex flex-wrap gap-2 mb-2">
                    {post.post_tags.flatMap((pt) =>
                      Array.isArray(pt.tags)
                        ? pt.tags.map((tag) => (
                            <span
                              key={tag.id}
                              className="text-xs px-2 py-0.5 rounded-md bg-black/5 dark:bg-white/10 text-zinc-500"
                            >
                              {tag.name}
                            </span>
                          ))
                        : []
                    )}
                  </div>
                  <h2 className="text-lg font-semibold mb-1 group-hover:text-zinc-500 dark:group-hover:text-zinc-400 transition">
                    {post.title}
                  </h2>
                  {post.summary && (
                    <p className="text-sm text-zinc-400 line-clamp-2">{post.summary}</p>
                  )}
                  <div className="flex items-center gap-3 mt-3 text-xs text-zinc-400">
                    <span>{new Date(post.created_at).toLocaleDateString("ko-KR")}</span>
                    <span className="flex items-center gap-1">
                      <Eye size={12} /> {post.view_count}
                    </span>
                  </div>
                </div>
                <ArrowRight
                  size={18}
                  className="mt-1 text-zinc-300 dark:text-zinc-600 group-hover:text-black dark:group-hover:text-white transition"
                />
              </Link>
            </motion.article>
          ))}
        </div>
      )}
    </div>
  );
}
