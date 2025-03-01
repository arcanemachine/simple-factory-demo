defmodule SimpleFactoryDemo.Authors.Author do
  @moduledoc "The Author schema."

  use Ecto.Schema

  import Ecto.Changeset

  alias SimpleFactoryDemo.Posts.Post
  alias SimpleFactoryDemo.Users.User

  schema "authors" do
    field :user_id, :id
    field :name, :string

    belongs_to :user, User, define_field: false

    has_many :posts, Post
  end

  def changeset(author \\ %__MODULE__{}, attrs) do
    fields = required_fields = [:user_id, :name]

    author
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
