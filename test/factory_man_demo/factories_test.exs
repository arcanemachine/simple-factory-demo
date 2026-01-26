defmodule FactoryManDemo.FactoriesTest do
  use FactoryManDemo.DataCase

  alias FactoryManDemo.Factories
  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  defp get_unique_value, do: System.os_time()

  # Default params
  test "can build a factory product with default params" do
    assert %User{id: nil} = Factories.build_user()
  end

  test "can insert a factory product with default params" do
    assert %User{id: id} = Factories.insert_user!()

    assert is_integer(id)
  end

  # Custom params
  test "can build a factory product with custom params" do
    assert %User{id: 123} = Factories.build_user(%{id: 123})
  end

  test "can insert a factory product with custom params" do
    id = Enum.random(10_000_000..2_000_000_000)

    assert %User{} = user = Factories.build_user(%{id: id})

    assert user.id == id
  end

  # Extend other factories - default params
  test "can build a factory product that extends another factory with default params" do
    assert user = %User{id: nil} = Factories.build_extended_user()

    assert String.starts_with?(user.username, "extended-user-")
  end

  test "can insert a factory product that extends another factory with default params" do
    assert user = %User{id: id} = Factories.insert_extended_user!()

    assert is_integer(id)
    assert String.starts_with?(user.username, "extended-user-")
  end

  test "can build a factory product that extends another factory with custom params" do
    assert %User{username: "custom_username"} =
             Factories.build_extended_user(%{username: "custom_username"})
  end

  test "can insert a factory product that extends another factory with custom params" do
    expected_username = "custom_username-#{get_unique_value()}"

    assert %User{username: actual_username} =
             Factories.build_extended_user(%{username: expected_username})

    assert actual_username == expected_username
  end

  # Insert opts
  test "can pass opts to `Repo.insert/2`" do
    # returning: true
    # on_conflict: replace
    raise "FIXME: TODO"
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
    user = Factories.build_user(%{username: "user-#{get_unique_value()}"})

    author = %Author{} = Factories.build_author(%{user: user})

    assert author.user == user
  end

  test "can build a factory product with assocs from another inserted factory product" do
    user = Factories.insert_user!(%{username: "user-#{get_unique_value()}"})

    author = %Author{} = Factories.insert_author!(%{user: user})

    assert Repo.preload(author, :user).user == user
  end

  test "can insert a factory product with assocs from another factory product" do
    # asse
  end
end
