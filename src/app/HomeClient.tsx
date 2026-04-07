"use client";

import { motion, type Variants } from "framer-motion";
import Link from "next/link";
import { ArrowRight, BookOpen, CalendarDays, Eye } from "lucide-react";

const fadeUp: Variants = {
  hidden: { opacity: 0, y: 24 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.1, duration: 0.5, ease: [0.25, 0.1, 0.25, 1] },
  }),
};

interface Stats {
  postCount: number;
  studyDays: number;
  totalViews: number;
}

interface RecentPost {
  id: string;
  title: string;
  slug: string;
  summary: string | null;
  created_at: string;
  post_tags: { tags: { id: string; name: string }[] | null }[];
}

interface Props {
  stats: Stats;
  recentPosts: RecentPost[];
}

const statItems = (stats: Stats) => [
  { icon: BookOpen, label: "포스트", value: String(stats.postCount) },
  { icon: CalendarDays, label: "공부 일수", value: `${stats.studyDays}일` },
  { icon: Eye, label: "총 조회수", value: stats.totalViews.toLocaleString() },
];

export default function HomeClient({ stats, recentPosts }: Props) {
  return (
    <div className="pt-16">
      {/* Hero */}
      <section className="max-w-5xl mx-auto px-6 pt-24 pb-20">
        <motion.div
          variants={fadeUp} initial="hidden" animate="show" custom={0}
          className="inline-block mb-6 px-3 py-1 text-xs font-medium rounded-full border border-black/20 dark:border-white/20 text-zinc-500"
        >
          프론트엔드 개발자 성장 기록
        </motion.div>

        <motion.h1
          variants={fadeUp} initial="hidden" animate="show" custom={1}
          className="text-5xl md:text-7xl font-bold tracking-tight leading-tight mb-6"
        >
          배우고, 기록하고,
          <br />
          <span className="text-zinc-400">성장한다.</span>
        </motion.h1>

        <motion.p
          variants={fadeUp} initial="hidden" animate="show" custom={2}
          className="text-lg text-zinc-500 max-w-xl mb-10"
        >
          비동기, 인증, 상태관리, 인프라까지 — 5년차 프론트엔드 개발자가
          부족한 기초를 채우는 과정을 공개합니다.
        </motion.p>

        <motion.div
          variants={fadeUp} initial="hidden" animate="show" custom={3}
          className="flex flex-wrap gap-4"
        >
          <Link
            href="/blog"
            className="flex items-center gap-2 px-6 py-3 bg-black dark:bg-white text-white dark:text-black rounded-full text-sm font-medium hover:opacity-80 transition-opacity"
          >
            블로그 보기 <ArrowRight size={16} />
          </Link>
          <Link
            href="/#timeline"
            className="flex items-center gap-2 px-6 py-3 rounded-full border border-black/20 dark:border-white/20 text-sm font-medium hover:bg-black/5 dark:hover:bg-white/10 transition-colors"
          >
            커리어 타임라인
          </Link>
        </motion.div>
      </section>

      {/* Stats */}
      <section className="border-y border-black/10 dark:border-white/10">
        <div className="max-w-5xl mx-auto px-6 py-10 grid grid-cols-3 divide-x divide-black/10 dark:divide-white/10">
          {statItems(stats).map(({ icon: Icon, label, value }, i) => (
            <motion.div
              key={label}
              variants={fadeUp} initial="hidden" animate="show" custom={i + 4}
              className="flex flex-col items-center gap-1 px-4"
            >
              <Icon size={20} className="text-zinc-400 mb-1" />
              <span className="text-3xl font-bold">{value}</span>
              <span className="text-xs text-zinc-400">{label}</span>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Recent Posts */}
      <section className="max-w-5xl mx-auto px-6 py-20">
        <motion.div
          variants={fadeUp} initial="hidden" animate="show" custom={7}
          className="flex items-center justify-between mb-10"
        >
          <h2 className="text-2xl font-bold">최근 포스트</h2>
          <Link
            href="/blog"
            className="text-sm text-zinc-400 hover:text-black dark:hover:text-white transition-colors flex items-center gap-1"
          >
            전체 보기 <ArrowRight size={14} />
          </Link>
        </motion.div>

        {recentPosts.length === 0 ? (
          <p className="text-zinc-400 text-sm">아직 포스트가 없어요.</p>
        ) : (
          <div className="grid md:grid-cols-3 gap-6">
            {recentPosts.map((post, i) => {
              const tags = post.post_tags.flatMap((pt) =>
                Array.isArray(pt.tags) ? pt.tags : []
              );
              return (
                <motion.article
                  key={post.id}
                  variants={fadeUp} initial="hidden" animate="show" custom={i + 8}
                  whileHover={{ y: -4, transition: { duration: 0.2 } }}
                  className="group p-6 rounded-2xl border border-black/10 dark:border-white/10 hover:border-black/30 dark:hover:border-white/30 transition-colors cursor-pointer"
                >
                  <Link href={`/blog/${post.slug}`}>
                    {tags[0] && (
                      <span className="text-xs font-medium px-2 py-1 rounded-md bg-black/5 dark:bg-white/10 text-zinc-500 mb-4 inline-block">
                        {tags[0].name}
                      </span>
                    )}
                    <h3 className="font-semibold mb-2 group-hover:text-zinc-600 dark:group-hover:text-zinc-300 transition-colors">
                      {post.title}
                    </h3>
                    {post.summary && (
                      <p className="text-sm text-zinc-400 leading-relaxed mb-4 line-clamp-2">
                        {post.summary}
                      </p>
                    )}
                    <span className="text-xs text-zinc-400">
                      {new Date(post.created_at).toLocaleDateString("ko-KR")}
                    </span>
                  </Link>
                </motion.article>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
