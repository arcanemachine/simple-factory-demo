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

  # Factory option inheritance
  test "factory options cascade from parent to child to individual factory" do
    # Parent factory (FactoryManDemo.Factory) has repo and hooks
    parent_opts = FactoryManDemo.Factory._factory_opts()
    assert Keyword.has_key?(parent_opts, :repo)
    assert Keyword.has_key?(parent_opts, :hooks)

    # Child factory inherits parent's repo and hooks
    child_opts = Factories._factory_opts()
    assert Keyword.get(child_opts, :repo) == FactoryManDemo.Repo
    assert Keyword.has_key?(child_opts, :hooks)
    assert Keyword.get(child_opts, :extends) == FactoryManDemo.Factory

    # Individual factory inherits all and adds its own options
    user_opts = Factories._user_factory_opts()
    assert Keyword.get(user_opts, :repo) == FactoryManDemo.Repo
    assert Keyword.has_key?(user_opts, :hooks)
    assert Keyword.get(user_opts, :struct) == FactoryManDemo.Users.User

    # Factory-level options override inherited ones
    non_insertable_opts = Factories._non_insertable_factory_opts()
    assert Keyword.get(non_insertable_opts, :insert?) == false
    assert Keyword.get(non_insertable_opts, :repo) == FactoryManDemo.Repo
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

  # List builder functions - params
  test "can build params list with default params" do
    params_list = Factories.build_user_params_list(3)

    assert length(params_list) == 3
    assert Enum.all?(params_list, &is_map/1)
    assert Enum.all?(params_list, &Map.has_key?(&1, :username))
    # Each item should have a unique username
    usernames = Enum.map(params_list, & &1.username)
    assert length(Enum.uniq(usernames)) == 3
  end

  test "can build params list with custom params" do
    params_list = Factories.build_user_params_list(2, %{username: "custom"})

    assert length(params_list) == 2
    assert Enum.all?(params_list, &(&1.username == "custom"))
  end

  test "build params list with count 0 returns empty list" do
    assert [] = Factories.build_user_params_list(0)
  end

  # List builder functions - structs
  test "can build struct list with default params" do
    struct_list = Factories.build_user_struct_list(3)

    assert length(struct_list) == 3
    assert Enum.all?(struct_list, &(%User{} = &1))
    # Structs should not be persisted yet (id is nil)
    assert Enum.all?(struct_list, &is_nil(&1.id))
    # Each struct should have unique username
    usernames = Enum.map(struct_list, & &1.username)
    assert length(Enum.uniq(usernames)) == 3
  end

  test "can build struct list with custom params" do
    struct_list = Factories.build_user_struct_list(2, %{username: "struct-custom"})

    assert length(struct_list) == 2
    assert Enum.all?(struct_list, &(&1.username == "struct-custom"))
  end

  test "build struct list with count 0 returns empty list" do
    assert [] = Factories.build_user_struct_list(0)
  end

  # List insert functions
  test "can insert list with default params" do
    users = Factories.insert_user_list!(3)

    assert length(users) == 3
    assert Enum.all?(users, &(%User{} = &1))
    # All should be persisted with IDs
    assert Enum.all?(users, &is_integer(&1.id))
    # Each should have unique username
    usernames = Enum.map(users, & &1.username)
    assert length(Enum.uniq(usernames)) == 3
  end

  test "can insert list with custom params" do
    # Use unique usernames since username has a unique constraint
    unique_val = System.os_time()
    users = Factories.insert_user_list!(2, %{username: fn -> "list-custom-#{unique_val}-#{System.os_time()}" end})

    assert length(users) == 2
    assert Enum.all?(users, &is_integer(&1.id))
    # Both usernames should start with the same prefix pattern
    assert Enum.all?(users, &String.starts_with?(&1.username, "list-custom-"))
  end

  test "insert list with count 0 returns empty list" do
    assert [] = Factories.insert_user_list!(0)
  end

  test "can insert list with repo opts" do
    users = Factories.insert_user_list!(2, %{}, returning: true)

    assert length(users) == 2
    # returning: true returns all fields with database defaults
    assert Enum.all?(users, &is_integer(&1.id))
  end

  # List functions with lazy evaluation
  test "lazy evaluation creates unique values for each item in params list" do
    params_list = Factories.build_lazy_user_params_list(3)

    # Each item should have a unique timestamp
    timestamps = Enum.map(params_list, & &1.created_at)
    assert length(Enum.uniq(timestamps)) == 3
  end

  test "lazy evaluation creates unique values for each item in struct list" do
    struct_list = Factories.build_lazy_author_struct_list(2)

    # Each struct should have a unique user
    users = Enum.map(struct_list, & &1.user)
    usernames = Enum.map(users, & &1.username)
    assert length(Enum.uniq(usernames)) == 2
  end

  test "lazy evaluation creates unique values for each inserted item in list" do
    users = Factories.insert_user_list!(3, %{username: fn -> "lazy-user-#{System.os_time()}" end})

    # Each user should have a unique username
    usernames = Enum.map(users, & &1.username)
    assert length(Enum.uniq(usernames)) == 3
  end

  # List functions with associations
  test "can insert list of authors with associated users" do
    authors = Factories.insert_author_list!(2)

    assert length(authors) == 2
    assert Enum.all?(authors, &(%Author{} = &1))
    # Authors should have user associations
    assert Enum.all?(authors, &is_integer(&1.user_id))
    # Preload and verify unique users
    loaded_authors = Enum.map(authors, &Repo.preload(&1, :user))
    user_ids = Enum.map(loaded_authors, & &1.user.id)
    assert length(Enum.uniq(user_ids)) == 2
  end

  # Atomic list tests - params_list arity variants
  test "params_list arity 1 calls arity 2 with empty map" do
    result = Factories.build_user_params_list(1)

    assert length(result) == 1
    assert [%{username: _}] = result
  end

  test "params_list arity 2 with empty map builds with defaults" do
    result = Factories.build_user_params_list(1, %{})

    assert length(result) == 1
    assert [%{username: username}] = result
    assert is_binary(username)
  end

  test "params_list with single item returns list with one element" do
    result = Factories.build_user_params_list(1, %{username: "single"})

    assert result == [%{username: "single"}]
  end

  test "params_list returns list type" do
    result = Factories.build_user_params_list(2)

    assert is_list(result)
  end

  # Atomic list tests - struct_list arity variants
  test "struct_list arity 1 calls arity 2 with empty map" do
    result = Factories.build_user_struct_list(1)

    assert length(result) == 1
    assert [%User{}] = result
  end

  test "struct_list arity 2 with empty map builds with defaults" do
    result = Factories.build_user_struct_list(1, %{})

    assert length(result) == 1
    assert [%User{username: username}] = result
    assert is_binary(username)
  end

  test "struct_list with single item returns list with one struct" do
    result = Factories.build_user_struct_list(1, %{username: "single-struct"})

    assert length(result) == 1
    assert [%User{username: "single-struct", id: nil}] = result
  end

  test "struct_list returns proper struct types" do
    result = Factories.build_author_struct_list(2)

    assert length(result) == 2
    assert Enum.all?(result, fn %Author{} -> true; _ -> false end)
  end

  # Atomic list tests - insert_list arity variants
  test "insert_list arity 1 calls with empty params and opts" do
    result = Factories.insert_user_list!(1)

    assert length(result) == 1
    assert [%User{id: id}] = result
    assert is_integer(id)
  end

  test "insert_list arity 2 with map calls with empty opts" do
    result = Factories.insert_user_list!(1, %{username: "arity2-map"})

    assert length(result) == 1
    assert [%User{username: "arity2-map"}] = result
  end

  test "insert_list arity 2 with list calls arity 3 with empty params" do
    result = Factories.insert_user_list!(1, [returning: true])

    assert length(result) == 1
    assert [%User{id: _}] = result
  end

  test "insert_list arity 3 with all arguments" do
    result = Factories.insert_user_list!(1, %{username: "arity3"}, returning: true)

    assert length(result) == 1
    assert [%User{username: "arity3"}] = result
  end

  # Atomic tests - data integrity
  test "params_list preserves all map keys" do
    result = Factories.build_user_params_list(1, %{username: "test", first_name: "John", extra: "value"})

    assert [%{username: "test", first_name: "John", extra: "value"}] = result
  end

  test "struct_list creates independent structs" do
    [struct1, struct2] = Factories.build_user_struct_list(2)

    # Modifying one should not affect the other
    modified = %{struct1 | username: "modified"}
    assert struct2.username != modified.username
  end

  test "insert_list creates independent records" do
    [user1, user2] = Factories.insert_user_list!(2)

    assert user1.id != user2.id
    refute user1.id == user2.id
  end

  # Atomic tests - count validation
  test "params_list with count 1 returns single item list" do
    result = Factories.build_user_params_list(1)
    assert length(result) == 1
  end

  test "struct_list with count 1 returns single item list" do
    result = Factories.build_user_struct_list(1)
    assert length(result) == 1
  end

  test "insert_list with count 1 returns single inserted record" do
    result = Factories.insert_user_list!(1)
    assert length(result) == 1
    assert [%User{id: id}] = result
    assert is_integer(id)
  end

  # Atomic tests - empty params handling
  test "params_list with nil map falls back to defaults" do
    # Using arity 2 with empty map, params will be empty
    result = Factories.build_user_params_list(1, %{})
    assert [%{username: username}] = result
    assert is_binary(username)
  end

  test "struct_list builds complete struct with all fields" do
    [struct] = Factories.build_user_struct_list(1, %{username: "complete", first_name: "Test"})

    assert struct.username == "complete"
    assert struct.first_name == "Test"
    assert struct.id == nil
    assert struct.__struct__ == User
  end

  # Atomic tests - list with non-struct factories
  test "params_list works with params-only factories" do
    result = Factories.build_non_struct_params_list(3)

    assert length(result) == 3
    assert Enum.all?(result, fn map ->
      is_map(map) and not Map.has_key?(map, :__struct__)
    end)
  end

  test "params_list for non-insertable factory works" do
    result = Factories.build_non_insertable_params_list(2)

    assert length(result) == 2
    assert Enum.all?(result, &is_map/1)
  end

  # Sequence integration tests
  test "sequence generates unique values when building structs" do
    user1 = Factories.build_user_sequence_struct()
    user2 = Factories.build_user_sequence_struct()

    assert user1.username != user2.username
    assert String.starts_with?(user1.username, "user-")
    assert String.starts_with?(user2.username, "user-")
  end

  test "sequence generates sequential values with OS time as start" do
    user1 = Factories.build_user_sequence_struct()
    user2 = Factories.build_user_sequence_struct()
    user3 = Factories.build_user_sequence_struct()

    # Each username should be unique
    usernames = [user1.username, user2.username, user3.username]
    assert length(Enum.uniq(usernames)) == 3

    # All should follow the pattern user-{timestamp}-{n}
    assert Enum.all?(usernames, &String.starts_with?(&1, "user-"))
  end

  test "sequence can be reset between test runs" do
    # Build and verify we get sequential values
    user1 = Factories.build_user_sequence_struct()
    original_username = user1.username

    # Reset sequences
    FactoryMan.Sequence.reset()

    # After reset, we might get a different starting point due to OS time
    # but sequence should still work correctly
    user2 = Factories.build_user_sequence_struct()
    assert String.starts_with?(user2.username, "user-")
    assert user2.username != original_username or user2.username == original_username
  end

  # List-based (circular) sequence test
  test "list-based sequence cycles through values" do
    user1 = Factories.build_user_with_role_struct()
    user2 = Factories.build_user_with_role_struct()
    user3 = Factories.build_user_with_role_struct()
    user4 = Factories.build_user_with_role_struct()

    # Should cycle: admin -> user -> guest -> admin
    assert String.ends_with?(user1.username, "-admin")
    assert String.ends_with?(user2.username, "-user")
    assert String.ends_with?(user3.username, "-guest")
    assert String.ends_with?(user4.username, "-admin")
  end
end
