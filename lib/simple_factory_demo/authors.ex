defmodule SimpleFactoryDemo.Authors do
  @moduledoc "The Authors context."

  alias SimpleFactoryDemo.Authors.Author
  alias SimpleFactoryDemo.Repo

  def insert_author(attrs), do: attrs |> Author.changeset() |> Repo.insert()

  def get_author(author_id), do: Repo.get(Author, author_id)

  def update_author(%Author{} = author, attrs),
    do: author |> Author.changeset(attrs) |> Repo.update()

  def delete_author(%Author{} = author), do: Repo.delete(author)
end
