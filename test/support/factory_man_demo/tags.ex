defmodule FactoryManDemo.Tags do
  @moduledoc "The Tags context."

  alias FactoryManDemo.Repo
  alias FactoryManDemo.Tags.Tag

  def insert_tag(attrs), do: attrs |> Tag.changeset() |> Repo.insert()

  def get_tag(name), do: Repo.get_by(Tag, name: name)

  def delete_tag(%Tag{} = tag), do: Repo.delete(tag)
end
