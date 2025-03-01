defmodule SimpleFactoryDemo.PostsTags.PostTag do
  @doc "The PostTag schema."

  use Ecto.Schema

  alias SimpleFactoryDemo.Posts.Post
  alias SimpleFactoryDemo.Tags.Tag

  @primary_key false
  schema "posts_tags" do
    field :post_id, :id, primary_key: true
    field :tag_id, :id, primary_key: true

    belongs_to :post, Post, define_field: false
    belongs_to :tag, Tag, define_field: false
  end
end
