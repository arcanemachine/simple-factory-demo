defmodule FactoryManDemo.Factories do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  factory :user do
    %{username: "user-#{System.os_time()}"}
    |> Map.merge(params)
    |> then(&struct(User, &1))
  end

  factory :extended_user do
    %{username: Map.get(params, :username, "extended-user-#{System.os_time()}")}
    |> Map.merge(params)
    |> then(&build_user/1)
  end

  factory :author do
    defaults = %{
      user: Map.get_lazy(params, :user, fn -> build_user() end),
      name: Map.get(params, :name, "Some author")
    }

    struct(Author, Map.merge(defaults, params))
  end
end
