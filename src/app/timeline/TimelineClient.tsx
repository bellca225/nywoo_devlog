"use client";

import dynamic from "next/dynamic";
import { motion } from "framer-motion";

const ParticleBackground = dynamic(() => import("./ParticleBackground"), {
  ssr: false,
});

interface CareerItem {
  period: string;
  company: string;
  role: string;
  stacks: string[];
  current?: boolean;
}

const CAREERS: CareerItem[] = [
  {
    period: "2024.10 – 현재",
    company: "다비치안경체인",
    role: "프론트엔드 개발",
    stacks: ["Nuxt", "Vue3", "TypeScript", "Java Spring", "Thymeleaf", "React", "Next.js"],
    current: true,
  },
  {
    period: "2022.12 – 2024.09",
    company: "위스마트",
    role: "프론트엔드 개발",
    stacks: ["Vue3", "Vite", "Vuetify", "TypeScript", "Java Spring"],
  },
  {
    period: "2021.02 – 2022.06",
    company: "에프원소프트",
    role: "풀스택 개발",
    stacks: ["ASP.NET", "C#", "JavaScript", "MS-SQL"],
  },
  {
    period: "2018.11 – 2020.04",
    company: "디오컴퍼니",
    role: "디자인 · 마케팅",
    stacks: ["Figma", "Photoshop", "Illustrator"],
  },
  {
    period: "2017.07 – 2018.11",
    company: "아이카코리아",
    role: "시각 디자인",
    stacks: ["Illustrator", "Photoshop"],
  },
];

const LEARNING = ["Three.js"];

const stackColor: Record<string, string> = {
  "Vue3": "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
  "Nuxt": "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
  "Vite": "bg-purple-500/10 text-purple-400 border-purple-500/20",
  "Vuetify": "bg-blue-500/10 text-blue-400 border-blue-500/20",
  "TypeScript": "bg-blue-600/10 text-blue-400 border-blue-600/20",
  "JavaScript": "bg-yellow-500/10 text-yellow-400 border-yellow-500/20",
  "React": "bg-cyan-500/10 text-cyan-400 border-cyan-500/20",
  "Next.js": "bg-zinc-500/10 text-zinc-300 border-zinc-500/20",
  "Java Spring": "bg-green-600/10 text-green-400 border-green-600/20",
  "Thymeleaf": "bg-green-500/10 text-green-400 border-green-500/20",
  "ASP.NET": "bg-indigo-500/10 text-indigo-400 border-indigo-500/20",
  "C#": "bg-indigo-600/10 text-indigo-400 border-indigo-600/20",
  "MS-SQL": "bg-red-500/10 text-red-400 border-red-500/20",
  "Figma": "bg-pink-500/10 text-pink-400 border-pink-500/20",
  "Photoshop": "bg-blue-700/10 text-blue-400 border-blue-700/20",
  "Illustrator": "bg-orange-500/10 text-orange-400 border-orange-500/20",
  "Three.js": "bg-zinc-500/10 text-zinc-300 border-zinc-500/20",
};

const defaultColor = "bg-zinc-500/10 text-zinc-400 border-zinc-500/20";

export default function TimelineClient() {
  return (
    <>
      <ParticleBackground />

      <div className="max-w-3xl mx-auto px-6 pt-28 pb-24">
        {/* 헤더 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-16"
        >
          <h1 className="text-4xl font-bold mb-3">Career Timeline</h1>
          <p className="text-zinc-400">디자인에서 개발로, 8년간의 성장 기록</p>
        </motion.div>

        {/* 타임라인 */}
        <div className="relative">
          {/* 세로 선 */}
          <div className="absolute left-4 top-0 bottom-0 w-px bg-black/10 dark:bg-white/10" />

          <div className="flex flex-col gap-10">
            {CAREERS.map((item, i) => (
              <motion.div
                key={item.company}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.1 + 0.2, duration: 0.5 }}
                className="relative pl-12"
              >
                {/* 도트 */}
                <div
                  className={`absolute left-0 top-1.5 w-8 h-8 rounded-full border flex items-center justify-center
                    ${item.current
                      ? "border-white bg-white"
                      : "border-black/20 dark:border-white/20 bg-white dark:bg-black"
                    }`}
                >
                  <div
                    className={`w-2.5 h-2.5 rounded-full ${item.current ? "bg-black animate-pulse" : "bg-zinc-400"}`}
                  />
                </div>

                {/* 카드 */}
                <div className="group rounded-2xl border border-black/10 dark:border-white/10 p-6 bg-white/50 dark:bg-black/50 backdrop-blur-sm hover:border-black/30 dark:hover:border-white/30 transition-all duration-300">
                  <div className="flex items-start justify-between gap-4 mb-4">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <h2 className="text-lg font-semibold">{item.company}</h2>
                        {item.current && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-black dark:bg-white text-white dark:text-black font-medium">
                            재직 중
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-zinc-400">{item.role}</p>
                    </div>
                    <span className="text-xs text-zinc-400 whitespace-nowrap pt-1">{item.period}</span>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    {item.stacks.map((stack) => (
                      <span
                        key={stack}
                        className={`text-xs px-2.5 py-1 rounded-lg border font-medium ${stackColor[stack] ?? defaultColor}`}
                      >
                        {stack}
                      </span>
                    ))}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* 학습 중 섹션 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8, duration: 0.5 }}
          className="mt-16 rounded-2xl border border-dashed border-black/20 dark:border-white/20 p-6"
        >
          <p className="text-xs font-medium text-zinc-400 mb-3 uppercase tracking-widest">학습 중</p>
          <div className="flex flex-wrap gap-2">
            {LEARNING.map((stack) => (
              <span
                key={stack}
                className={`text-xs px-2.5 py-1 rounded-lg border font-medium ${stackColor[stack] ?? defaultColor}`}
              >
                {stack}
              </span>
            ))}
          </div>
        </motion.div>
      </div>
    </>
  );
}
