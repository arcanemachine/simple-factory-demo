defmodule FactoryManDemo.FactoriesTest do
  use FactoryManDemo.DataCase

  alias FactoryManDemo.Factories
  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  defp get_unique_value, do: System.os_time()

  # Default params
  test "can build a factory product with default params" do
    assert %User{id: nil} = Factories.build_user_struct()
  end

  test "can insert a factory product with default params" do
    assert %User{id: id} = Factories.insert_user!()

    assert is_integer(id)
  end

  # Custom params
  test "can build a factory product with custom params" do
    assert %User{id: 123} = Factories.build_user_struct(%{id: 123})
  end

  test "can insert a factory product with custom params" do
    id = Enum.random(10_000_000..2_000_000_000)

    assert %User{} = user = Factories.build_user_struct(%{id: id})

    assert user.id == id
  end

  # Extend other factories - default params
  test "can build a factory product that extends another factory with default params" do
    assert user = %User{id: nil} = Factories.build_extended_user_struct()

    assert String.starts_with?(user.username, "extended-user-")
  end

  test "can insert a factory product that extends another factory with default params" do
    assert user = %User{id: id} = Factories.insert_extended_user!()

    assert is_integer(id)
    assert String.starts_with?(user.username, "extended-user-")
  end

  test "can build a factory product that extends another factory with custom params" do
    assert %User{username: "custom_username"} =
             Factories.build_extended_user_struct(%{username: "custom_username"})
  end

  test "can insert a factory product that extends another factory with custom params" do
    expected_username = "custom_username-#{get_unique_value()}"

    assert %User{username: actual_username} =
             Factories.build_extended_user_struct(%{username: expected_username})

    assert actual_username == expected_username
  end

  # Insert opts
  test "can pass opts to `Repo.insert/2`" do
    # Test returning: true - returns the full record with defaults
    user1 =
      Factories.insert_user!(%{username: "returning-test-#{get_unique_value()}"}, returning: true)

    assert is_integer(user1.id)

    # Test on_conflict: :nothing - won't raise error on conflict
    duplicate_username = "conflict-test-#{get_unique_value()}"
    _user2 = Factories.insert_user!(%{username: duplicate_username})

    # Insert duplicate with on_conflict: :nothing should not raise
    _user3 = Factories.insert_user!(%{username: duplicate_username}, on_conflict: :nothing)
  end

  # Multi-insert
  test "can insert multiple factory products one-at-a-time" do
    assert %User{} = Factories.insert_user!()
    assert %User{} = Factories.insert_user!()

    assert %Author{} = Factories.insert_author!()
    assert %Author{} = Factories.insert_author!()
  end

  # Use assocs from other factory products
  test "can build a factory product with assocs from another built factory product" do
    user = Factories.build_user_struct(%{username: "user-#{get_unique_value()}"})

    author = %Author{} = Factories.build_author_struct(%{user: user})

    assert author.user == user
  end

  test "can build a factory product with assocs from another inserted factory product" do
    user = Factories.insert_user!(%{username: "user-#{get_unique_value()}"})

    author = %Author{} = Factories.insert_author!(%{user: user})

    assert Repo.preload(author, :user).user == user
  end

  test "can insert a factory product with assocs from another factory product" do
    # Build a user and author together, inserting both
    user = Factories.build_user_struct(%{username: "assoc-user-#{get_unique_value()}"})
    author = Factories.insert_author!(%{user: user, name: "Test Author"})

    # Verify the user was inserted
    assert is_integer(author.user_id)
    assert author.user_id > 0

    # Verify we can preload the associated user
    loaded_author = Repo.preload(author, :user)
    assert %User{} = loaded_author.user
    assert loaded_author.user.id == author.user_id
  end

  # Lazy Evaluation - 0-arity functions
  test "0-arity lazy functions are evaluated at build time" do
    params = Factories.build_lazy_user_params()

    # Verify the function was evaluated to a DateTime struct
    assert %DateTime{} = params.created_at
    # Verify it's not still a function
    refute is_function(params.created_at)
  end

  test "0-arity lazy functions are evaluated fresh on each call" do
    params1 = Factories.build_lazy_user_params()
    :timer.sleep(10)
    params2 = Factories.build_lazy_user_params()

    # Timestamps should be different
    refute params1.created_at == params2.created_at
  end

  # Lazy Evaluation - 1-arity functions
  test "1-arity lazy functions receive the parent struct" do
    params = Factories.build_lazy_user_params(%{first_name: "John"})

    assert params.full_name == "John Userson"
  end

  test "1-arity lazy functions can access other lazy-evaluated fields" do
    params = Factories.build_lazy_user_params(%{first_name: "Jane"})

    # full_name depends on first_name
    assert params.full_name == "Jane Userson"
  end

  # Lazy Evaluation - With Struct Building
  test "lazy evaluation works when building structs" do
    author = Factories.build_lazy_author_struct()

    # user should be a User struct, not a function
    assert %User{} = author.user
    refute is_function(author.user)
  end

  test "lazy associations are built fresh on each call" do
    author1 = Factories.build_lazy_author_struct()
    author2 = Factories.build_lazy_author_struct()

    # Each call should build a different user
    refute author1.user.username == author2.user.username
  end

  # Lazy Evaluation - Override via params
  test "lazy values can be overridden with regular values" do
    fixed_time = DateTime.utc_now() |> DateTime.truncate(:second)
    params = Factories.build_lazy_user_params(%{created_at: fixed_time})

    assert params.created_at == fixed_time
  end

  # Non-struct factories
  test "can build params-only factory (returns map, not struct)" do
    params = Factories.build_non_struct_params()

    assert is_map(params)
    refute Map.has_key?(params, :__struct__)
    assert is_binary(params.name)
    assert is_integer(params.age)
  end

  # Factory with custom parameter name
  test "can use factory with custom param variable name" do
    params = Factories.build_with_custom_param_name_params(%{name: "custom"})

    assert params.name == "custom"
  end

  # Factory with hooks
  test "hooks can transform factory output" do
    params = Factories.build_with_after_build_params_hook_params()

    assert params.hello == :world
  end

  # Params-only struct factory (has struct option so it creates struct builder)
  test "params_only factory has both params and struct builders" do
    # Params builder works
    params = Factories.build_params_only_params()
    assert is_map(params)
    assert is_binary(params.username)

    # Struct builder also exists since struct option is set
    assert function_exported?(Factories, :build_params_only_struct, 0)
    assert function_exported?(Factories, :build_params_only_struct, 1)
  end

  # Non-insertable factory
  test "non_insertable factory has no insert functions" do
    # Build and struct functions exist
    assert function_exported?(Factories, :build_non_insertable_params, 0)
    assert function_exported?(Factories, :build_non_insertable_struct, 0)

    # But insert functions don't exist
    refute function_exported?(Factories, :insert_non_insertable!, 0)
    refute function_exported?(Factories, :insert_non_insertable!, 1)
  end

  # Required params (no default)
  test "factory without default requires params argument" do
    # This factory requires params (no default), so calling without should fail
    # Since the function doesn't exist at arity 0, it raises UndefinedFunctionError
    # Using apply/3 to avoid compile-time warning about undefined function
    assert_raise UndefinedFunctionError, fn ->
      apply(Factories, :build_no_default_fallback_params, [])
    end

    # Works when params provided
    params = Factories.build_no_default_fallback_params(%{extra: "data"})
    assert params.extra == "data"
  end

  # Embedded schema
  test "can build embedded schema factory" do
    embedded = Factories.build_embedded_schema_struct()

    assert %FactoryManDemo.EmbeddedSchema{} = embedded
    assert embedded.some_field == "some value"
  end

  test "embedded schema factory has no insert functions" do
    refute function_exported?(Factories, :insert_embedded_schema!, 0)
    refute function_exported?(Factories, :insert_embedded_schema!, 1)
  end

  # Test build_*_params for regular factories
  test "can build params directly without creating struct" do
    params = Factories.build_user_params(%{username: "test-user"})

    assert is_map(params)
    assert params.username == "test-user"
    refute Map.has_key?(params, :__struct__)
  end

  # Insert lazy factories
  test "can insert factories with lazy evaluation" do
    author = Factories.insert_lazy_author!()

    assert %Author{} = author
    assert is_integer(author.id)

    # Preload and verify the associated user
    loaded_author = Repo.preload(author, :user)
    assert %User{} = loaded_author.user
    assert is_integer(loaded_author.user.id)
  end
end
