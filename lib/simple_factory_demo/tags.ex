defmodule SimpleFactoryDemo.Tags do
  @moduledoc "The Tags context."

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Tags.Tag

  def insert_tag(attrs), do: attrs |> Tag.changeset() |> Repo.insert()

  def get_tag(name), do: Repo.get_by(Tag, name: name)

  def delete_tag(%Tag{} = tag), do: Repo.delete(tag)
end
