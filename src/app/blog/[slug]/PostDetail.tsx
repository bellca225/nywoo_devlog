"use client";

import { motion } from "framer-motion";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Eye, Calendar, ArrowLeft } from "lucide-react";
import Link from "next/link";

interface Post {
  id: string;
  title: string;
  slug: string;
  content: string;
  summary: string | null;
  view_count: number;
  created_at: string;
  profiles: { username: string }[] | null;
  post_tags: { tags: { id: string; name: string }[] | null }[];
}

export default function PostDetail({ post }: { post: Post }) {
  return (
    <div className="max-w-3xl mx-auto px-6 pt-28 pb-20">
      {/* 뒤로가기 */}
      <motion.div
        initial={{ opacity: 0, x: -8 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
        className="mb-8"
      >
        <Link
          href="/blog"
          className="inline-flex items-center gap-1.5 text-sm text-zinc-400 hover:text-black dark:hover:text-white transition"
        >
          <ArrowLeft size={14} /> Blog
        </Link>
      </motion.div>

      {/* 헤더 */}
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="mb-10"
      >
        {/* 태그 */}
        <div className="flex flex-wrap gap-2 mb-4">
          {post.post_tags.flatMap((pt) =>
            Array.isArray(pt.tags)
              ? pt.tags.map((tag) => (
                  <span
                    key={tag.id}
                    className="text-xs px-2 py-1 rounded-md bg-black/5 dark:bg-white/10 text-zinc-500"
                  >
                    {tag.name}
                  </span>
                ))
              : []
          )}
        </div>

        <h1 className="text-3xl md:text-4xl font-bold leading-tight mb-4">
          {post.title}
        </h1>

        {post.summary && (
          <p className="text-zinc-400 text-lg leading-relaxed mb-6">{post.summary}</p>
        )}

        <div className="flex items-center gap-4 text-sm text-zinc-400 pb-6 border-b border-black/10 dark:border-white/10">
          <span className="flex items-center gap-1.5">
            <Calendar size={14} />
            {new Date(post.created_at).toLocaleDateString("ko-KR", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </span>
          <span className="flex items-center gap-1.5">
            <Eye size={14} /> {post.view_count}
          </span>
        </div>
      </motion.div>

      {/* 본문 */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2, duration: 0.4 }}
        className="prose prose-zinc dark:prose-invert max-w-none
          prose-headings:font-bold prose-headings:tracking-tight
          prose-code:before:content-none prose-code:after:content-none
          prose-code:bg-black/5 prose-code:dark:bg-white/10
          prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded
          prose-pre:bg-zinc-950 prose-pre:border prose-pre:border-white/10"
      >
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{post.content}</ReactMarkdown>
      </motion.div>
    </div>
  );
}
