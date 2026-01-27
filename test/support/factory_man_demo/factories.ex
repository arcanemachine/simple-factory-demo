defmodule FactoryManDemo.Factories do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  factory :user, struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end

  factory :extended_user, struct: User do
    base_params = %{username: Map.get(params, :username, "extended-user-#{System.os_time()}")}

    base_params |> Map.merge(params) |> build_user_params()
  end

  factory Author do
    base_params = %{
      user: params[:user] || build_user(),
      name: "Some author"
    }

    Map.merge(base_params, params)
  end
end
