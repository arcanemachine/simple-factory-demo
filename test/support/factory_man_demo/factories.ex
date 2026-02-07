defmodule FactoryManDemo.Factories do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.EmbeddedSchema
  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  # Non-struct factory
  deffactory non_struct(params \\ %{}) do
    base_params = %{
      name: "name-#{System.os_time()}",
      age: Enum.random(1..100)
    }

    Map.merge(base_params, params)
  end

  # Factory with custom `params` var name
  deffactory with_custom_param_name(attrs \\ %{}) do
    base_attrs = %{
      name: "name-#{System.os_time()}",
      age: Enum.random(1..100)
    }

    Map.merge(base_attrs, attrs)
  end

  # Factory with custom "after_build_params" hook
  deffactory with_after_build_params_hook(params \\ %{}),
    hooks: [after_build_params: &__MODULE__.after_build_params/1] do
    base_params = %{
      name: "name-#{System.os_time()}",
      age: Enum.random(1..100)
    }

    Map.merge(base_params, params)
  end

  @doc "Puts a 'hello world' key-value pair into the params map."
  def after_build_params(params), do: params |> Map.put(:hello, :world)

  # Params-only struct factory (has params builder function, but no struct builder function)
  deffactory params_only(params \\ %{}), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Non-insertable struct factory
  deffactory non_insertable(params \\ %{}), struct: User, insert?: false do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Insertable struct factory without fallback to default values
  deffactory no_default_fallback(params), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  # Embedded schema (no insert)
  deffactory embedded_schema(params \\ %{}), struct: EmbeddedSchema do
    base_params = %{some_field: "some value"}

    Map.merge(base_params, params)
  end

  # Factory that extends another factory
  @doc "Hello world"
  deffactory user(params \\ %{}), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

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

  # Factory demonstrating lazy evaluation with 0-arity functions
  deffactory lazy_user(params \\ %{}), struct: User do
    base_params = %{
      username: "user-#{System.os_time()}",
      # 0-arity: called with no arguments, evaluated at build time
      lazy_timestamp: fn -> System.os_time() end
    }

    Map.merge(base_params, params)
  end

  # Factory demonstrating lazy evaluation with 1-arity functions
  deffactory user_with_derived(params \\ %{}), struct: User do
    base_params = %{
      username: "user-#{System.os_time()}",
      # 1-arity: receives the parent struct being built
      display_name: fn user -> "Display: #{user.username}" end
    }

    Map.merge(base_params, params)
  end

  # Factory with both 0-arity and 1-arity lazy functions
  deffactory lazy_author(params \\ %{}), struct: Author do
    base_params = %{
      name: "Author-#{System.os_time()}",
      # 0-arity: build a user at build time
      user: fn -> build_user_struct() end,
      # 1-arity: access other fields of the author being built
      bio: fn author -> "Bio for #{author.name}" end
    }

    Map.merge(base_params, params)
  end
end
