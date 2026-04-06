import { createClient } from "@/lib/supabase/server";
import BlogList from "./BlogList";

export const revalidate = 60;

export default async function BlogPage() {
  const supabase = await createClient();

  const { data: posts } = await supabase
    .from("posts")
    .select(`
      id, title, slug, summary, published, view_count, created_at,
      profiles(username),
      post_tags(tags(id, name))
    `)
    .eq("published", true)
    .order("created_at", { ascending: false });

  return <BlogList initialPosts={posts ?? []} />;
}
