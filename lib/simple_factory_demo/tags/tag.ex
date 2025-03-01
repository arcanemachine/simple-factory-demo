defmodule SimpleFactoryDemo.Tags.Tag do
  @moduledoc "The Tag schema."

  use Ecto.Schema
  import Ecto.Changeset
  alias SimpleFactoryDemo.Posts.Post

  schema "tags" do
    field :name, :string

    many_to_many :posts, Post,
      join_through: "posts_tags",
      unique: true
  end

  def changeset(tag \\ %__MODULE__{}, attrs) do
    fields = required_fields = [:name]

    tag
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> unique_constraint(:name)
    |> put_change(:name, slugify(attrs[:name]))
  end

  defp slugify(text) when is_binary(text) do
    # Taken from: https://mudssrali.com/blog/slugify-a-string-in-elixir

    text
    |> String.downcase()
    |> String.trim()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "  ")
    |> String.replace(~r/[\s-]+/, "-", global: true)
  end

  defp slugify(_), do: ""
end
