defmodule FactoryManDemo.Factory do
  use FactoryMan,
    repo: FactoryManDemo.Repo,
    hooks: [after_insert: &__MODULE__.after_insert_handler/1]

  @doc "Reset all assocs so that the `struct`'s structure matches a basic database query result."
  def after_insert_handler(%_{} = struct),
    do: Ecto.reset_fields(struct, struct.__struct__.__schema__(:associations))
end
