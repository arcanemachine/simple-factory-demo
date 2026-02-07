defmodule FactoryManDemo.EmbeddedSchema do
  use Ecto.Schema

  embedded_schema do
    field :some_field, :string
  end
end
