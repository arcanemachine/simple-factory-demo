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
        after_build: fn user, base_hook ->
          # Call base hook first (module-level hook)
          user = base_hook.(user)
          # Then apply factory-specific logic
          %{user | username: String.upcase(user.username)}
        end
      ]
    end
  end

end
