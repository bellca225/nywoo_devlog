import { createClient } from "@/lib/supabase/server";
import HomeClient from "./HomeClient";

export const revalidate = 60;

const STUDY_START_DATE = new Date("2026-03-21");

export default async function Home() {
  const supabase = await createClient();

  const [postsResult, viewsResult] = await Promise.all([
    supabase.from("posts").select("id", { count: "exact", head: true }).eq("published", true),
    supabase.from("posts").select("view_count").eq("published", true),
  ]);

  const postCount = postsResult.count ?? 0;
  const totalViews = (viewsResult.data ?? []).reduce((sum, p) => sum + (p.view_count ?? 0), 0);
  const studyDays = Math.max(
    1,
    Math.floor((Date.now() - STUDY_START_DATE.getTime()) / (1000 * 60 * 60 * 24)) + 1
  );

  const { data: recentPosts } = await supabase
    .from("posts")
    .select(`
      id, title, slug, summary, created_at,
      post_tags(tags(id, name))
    `)
    .eq("published", true)
    .order("created_at", { ascending: false })
    .limit(3);

  return (
    <HomeClient
      stats={{ postCount, studyDays, totalViews }}
      recentPosts={recentPosts ?? []}
    />
  );
}
