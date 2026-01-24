defmodule SimpleFactoryDemo.Factories.Authors do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Authors.Author
  alias SimpleFactoryDemo.Factories.Users

  factory(
    name: :author,
    build:
      quote do
        def build_author(params \\ %{}) do
          %Author{
            user: params[:user] || Users.build_user(),
            id: params[:id],
            name: Map.get(params, :name, "Some author")
          }
        end
      end
  )
end
