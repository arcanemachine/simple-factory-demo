defmodule SimpleFactoryDemo.Posts.Post do
  @moduledoc "The Post schema."

  use Ecto.Schema

  import Ecto.Changeset

  alias SimpleFactoryDemo.Authors.Author
  alias SimpleFactoryDemo.Tags.Tag

  schema "posts" do
    field :author_id, :id
    field :title, :string
    field :content, :string
    timestamps()

    belongs_to :author, Author, define_field: false

    many_to_many :tags, Tag, join_through: "posts_tags", unique: true
  end

  def changeset(post \\ %__MODULE__{}, attrs) do
    fields = required_fields = [:author_id, :title, :content]

    post
    |> cast(attrs, fields)
    |> foreign_key_constraint(:user_id)
    |> validate_required(required_fields)
    |> cast_assoc(:tags)
  end
end
