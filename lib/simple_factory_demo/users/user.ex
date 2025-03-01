defmodule SimpleFactoryDemo.Users.User do
  @moduledoc "The User schema."

  use Ecto.Schema
  import Ecto.Changeset
  alias SimpleFactoryDemo.Authors.Author

  schema "users" do
    field :username, :string

    has_one :author, Author
  end

  def changeset(user \\ %__MODULE__{}, attrs) do
    fields = required_fields = [:username]

    user
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> unique_constraint(:username)
  end
end
