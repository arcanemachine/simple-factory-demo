defmodule FactoriesTest do
  use ExUnit.Case
  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Factories.{Users, Authors, Posts, Tags}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "Users.build_user/0 creates a user struct" do
    user = Users.build_user()
    assert %SimpleFactoryDemo.Users.User{} = user
    assert user.username
  end

  test "Users.insert_user!/0 persists a user" do
    user = Users.insert_user!()
    assert user.id
    assert Repo.get(SimpleFactoryDemo.Users.User, user.id)
  end

  test "Authors.build_author/0 creates an author with a user" do
    author = Authors.build_author()
    assert %SimpleFactoryDemo.Authors.Author{} = author
    assert author.name
    assert %SimpleFactoryDemo.Users.User{} = author.user
  end

  test "Authors.insert_author!/0 persists an author and user" do
    author = Authors.insert_author!()
    assert author.id
    assert author.user_id
    assert Repo.get(SimpleFactoryDemo.Authors.Author, author.id)
  end

  test "Posts.build_post/0 creates a post with author and user" do
    post = Posts.build_post()
    assert %SimpleFactoryDemo.Posts.Post{} = post
    assert post.title
    assert post.content
    assert %SimpleFactoryDemo.Authors.Author{} = post.author
  end

  test "Posts.insert_post!/0 persists a post with nested author and user" do
    post = Posts.insert_post!()
    assert post.id
    assert post.author_id
    assert Repo.get(SimpleFactoryDemo.Posts.Post, post.id)
  end

  test "Tags.build_tag/0 creates a tag struct" do
    tag = Tags.build_tag()
    assert %SimpleFactoryDemo.Tags.Tag{} = tag
    assert tag.name
  end

  test "Tags.insert_tag!/0 persists a tag" do
    tag = Tags.insert_tag!()
    assert tag.id
    assert Repo.get(SimpleFactoryDemo.Tags.Tag, tag.id)
  end

  test "can create post with custom tags" do
    tag1 = Tags.insert_tag!(%{name: "test1"})
    tag2 = Tags.insert_tag!(%{name: "test2"})

    post = Posts.build_post(%{title: "Tagged Post"})
    |> Map.put(:tags, [tag1, tag2])
    |> Repo.insert!()

    assert post.id
    loaded_post = Repo.get(SimpleFactoryDemo.Posts.Post, post.id) |> Repo.preload(:tags)
    assert length(loaded_post.tags) == 2
  end

  test "can create full nested structure" do
    user = Users.insert_user!(%{username: "test_user"})
    author = Authors.insert_author!(%{name: "Test Author", user: user})
    tag = Tags.insert_tag!(%{name: "nested"})

    post = Posts.build_post(%{title: "Nested Test", author: author})
    |> Map.put(:tags, [tag])
    |> Repo.insert!()

    assert post.id
    assert post.author_id == author.id

    loaded_post = Repo.get(SimpleFactoryDemo.Posts.Post, post.id) |> Repo.preload([:tags, author: :user])
    assert loaded_post.author.user.username == "test_user"
    assert hd(loaded_post.tags).name == "nested"
  end

  test "after_insert hook resets associations to NotLoaded" do
    author = Authors.insert_author!()

    assert author.id
    assert author.user_id
    refute Ecto.assoc_loaded?(author.user)
    refute Ecto.assoc_loaded?(author.posts)
  end

  test "build does not trigger after_insert hook, keeps associations loaded" do
    author = Authors.build_author()

    assert is_nil(author.id)
    assert %SimpleFactoryDemo.Users.User{} = author.user
    assert Ecto.assoc_loaded?(author.user)
  end

  test "after_insert hook resets nested associations" do
    post = Posts.insert_post!()

    assert post.id
    assert post.author_id
    refute Ecto.assoc_loaded?(post.author)
    refute Ecto.assoc_loaded?(post.tags)
  end
end
