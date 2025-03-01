defmodule SimpleFactoryDemo.Posts do
  @moduledoc "The Posts context."

  import Ecto.Query

  alias SimpleFactoryDemo.Posts.Post
  alias SimpleFactoryDemo.Repo

  @doc "List all Posts by Author ID."
  def list_posts_by_author_id(author_id),
    do: Repo.all(from p in Post, where: p.author_id == ^author_id)

  @doc "List all Posts by Tag name."
  def list_posts_by_tag(tag_name),
    do: Repo.all(from p in Post, join: t in assoc(p, :tags), where: ilike(t.name, ^tag_name))

  def insert_post(attrs) do
    attrs
    |> Post.changeset()
    |> Repo.insert()
  end

  def get_post(post_id), do: Repo.get(Post, post_id)

  def update_post(%Post{} = post, attrs) do
    post
    |> Repo.preload(:tags)
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post), do: Repo.delete(post)
end
