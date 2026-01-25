defmodule FactoryManDemo.Factories do
  use FactoryMan, extends: FactoryManDemo.Factory

  # alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

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

  # factory(
  #   name: :author,
  #   build:
  #     quote do
  #       def build_author(params \\ %{}) do
  #         %Author{
  #           # Assocs
  #           user: params[:user] || build_user(),

  #           # Fields
  #           id: params[:id],
  #           name: Map.get(params, :name, "Some author")
  #         }
  #       end
  #     end
  # )

  # Other factories...
end
