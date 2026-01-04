defmodule SimpleFactoryDemo.Factory do
  use FactoryMan,
    repo: SimpleFactoryDemo.Repo,
    after_insert: &__MODULE__.after_insert_handler/1

  @doc """
  After inserting a struct, reset all assoc fields so that the struct matches a new database query
  result.
  """
  def after_insert_handler(%_{} = inserted_struct),
    do: Ecto.reset_fields(inserted_struct, inserted_struct.__struct__.__schema__(:associations))
end
