export type Role = "admin" | "viewer";

export interface Profile {
  id: string;
  username: string;
  role: Role;
  created_at: string;
}

export interface Tag {
  id: string;
  name: string;
  created_at: string;
}

export interface Post {
  id: string;
  author_id: string;
  title: string;
  slug: string;
  content: string;
  summary: string | null;
  cover_image_url: string | null;
  published: boolean;
  view_count: number;
  created_at: string;
  updated_at: string;
  profiles?: Profile;
  tags?: Tag[];
}

export interface PostWithTags extends Post {
  post_tags: { tags: Tag }[];
}
