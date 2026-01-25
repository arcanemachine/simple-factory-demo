defmodule FactoryManDemo.Factories.Users do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Users.User

  factory :user do
    build do
      %User{
        id: Map.get(params, :id),
        username: Map.get(params, :username, "user-#{System.os_time()}"),
        author: Map.get(params, :author)
      }
    end

    hooks do
      [
        after_build: fn user ->
          # Custom hook: upcase the username
          %{user | username: String.upcase(user.username)}
        end
      ]
    end
  end

end
