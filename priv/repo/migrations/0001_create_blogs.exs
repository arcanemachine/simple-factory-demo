defmodule SimpleFactoryDemo.Repo.Migrations.CreateBlogs do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table("users") do
      add :username, :citext, null: false
    end

    create unique_index("users", [:username])

    create table("authors") do
      add :user_id, references("users"), null: false
      add :name, :string, null: false
    end

    create unique_index("authors", [:user_id])

    create table("posts") do
      add :author_id, references("authors"), null: false
      add :title, :string, null: false
      add :content, :text, null: false
      timestamps()
    end

    create table("tags") do
      add :name, :citext, null: false
    end

    create table("posts_tags", primary_key: false) do
      add :post_id, references("posts", on_delete: :delete_all), primary_key: true
      add :tag_id, references("tags", on_delete: :delete_all), primary_key: true
    end
  end
end
