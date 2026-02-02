defmodule FactoryManDemo.Factories do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.EmbeddedSchema
  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  # Insertable struct factory
  deffactory user(params \\ %{}), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Struct factory (params only, no struct builder)
  deffactory params_only_user(params \\ %{}), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Non-insertable struct factory
  deffactory non_insertable_user(params \\ %{}), struct: User, insert_struct?: false do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Insertable struct factory without fallback to default values
  deffactory user_without_default_fallback(params), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Embedded schema (no insert)
  deffactory embedded_schema(params \\ %{}), struct: EmbeddedSchema do
    base_params = %{some_field: "some value"}

    Map.merge(base_params, params)
  end

  # Factory that extends another factory
  deffactory extended_user(params \\ %{}), struct: User do
    base_params = %{username: Map.get(params, :username, "extended-user-#{System.os_time()}")}

    base_params |> Map.merge(params) |> build_user_params()
  end

  # Factory that has a nested factory
  deffactory author(params \\ %{}), struct: Author do
    base_params = %{
      user: params[:user] || build_user_struct(),
      name: "Some author"
    }

    Map.merge(base_params, params)
  end
end
