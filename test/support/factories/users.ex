defmodule SimpleFactoryDemo.Factories.Users do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Authors.Author
  alias SimpleFactoryDemo.Users.User

  factory(
    name: :user,
    build:
      (
        @doc "Hello world"
        def build_user(params \\ %{}) do
          %User{
            id: params[:id],
            username: Map.get(params, :username, "user-#{System.os_time(:second)}"),
            author: params[:author]
          }
        end
      )
  )

  factory(
    name: :author,
    build:
      def build_author(params \\ %{}) do
        %Author{
          # Assocs
          user: params[:user] || build_user(),

          # Fields
          id: params[:id],
          name: Map.get(params, :name, "Some author")
        }
      end
  )
end
