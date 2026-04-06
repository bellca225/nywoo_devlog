import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import PostDetail from "./PostDetail";

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: Props) {
  const { slug } = await params;
  const supabase = await createClient();
  const { data } = await supabase
    .from("posts")
    .select("title, summary")
    .eq("slug", slug)
    .single();

  if (!data) return { title: "Not Found" };
  return { title: data.title, description: data.summary };
}

export default async function PostPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createClient();

  const { data: post } = await supabase
    .from("posts")
    .select(`
      *,
      profiles(username),
      post_tags(tags(id, name))
    `)
    .eq("slug", slug)
    .eq("published", true)
    .single();

  if (!post) notFound();

  // 조회수 증가 (fire and forget)
  supabase
    .from("posts")
    .update({ view_count: post.view_count + 1 })
    .eq("id", post.id);

  return <PostDetail post={post} />;
}
