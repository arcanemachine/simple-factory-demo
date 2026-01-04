defmodule SimpleFactoryDemo.Factory do
  use FactoryMan,
    repo: SimpleFactoryDemo.Repo,
    hooks: [after_insert: &__MODULE__.after_insert_handler/1]

  @doc "Reset all assocs so that the item's structure matches a basic database query result."
  def after_insert_handler(%_{} = inserted_struct),
    do: Ecto.reset_fields(inserted_struct, inserted_struct.__struct__.__schema__(:associations))
end
