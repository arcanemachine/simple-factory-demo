defmodule SimpleFactoryDemo.Factories.Users do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Authors.Author
  alias SimpleFactoryDemo.Users.User

  factory(
    name: :user,
    build:
      quote do
        def build_user(params \\ %{}) do
          %User{
            id: params[:id],
            username: Map.get(params, :username, "user-#{System.os_time(:second)}"),
            author: params[:author]
          }
        end
      end
  )

end
