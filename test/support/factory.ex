defmodule FactoryManDemo.Factory do
  use FactoryMan,
    repo: FactoryManDemo.Repo,
    # actions: [:build, :insert],
    hooks: [
      before_build: &__MODULE__.before_build_handler/1,
      after_insert: &__MODULE__.after_insert_handler/1
    ]

  @doc "An example custom build handler"
  def before_build_handler(params), do: params |> Map.put(:id, :world)

  @doc "Reset all assocs so that the `struct`'s structure matches a basic database query result."
  def after_insert_handler(%_{} = struct),
    do: Ecto.reset_fields(struct, struct.__struct__.__schema__(:associations))
end
