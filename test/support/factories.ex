defmodule FactoryManDemo.Factories do
  # use FactoryMan
  use FactoryMan, extends: FactoryManDemo.Factory

  # alias FactoryManDemo.Authors.Author
  alias FactoryManDemo.Users.User

  # factory user(params \\ %{}) do
  #   %User{
  #     id: params[:id],
  #     username: Map.get(params, :username, "user-#{System.os_time()}"),
  #     author: params[:author]
  #   }
  # end

  factory :user do
    defaults = %{username: "user-#{System.os_time()}"}

    struct(User, Map.merge(defaults, params))
  end

  factory :old_user do
    build_user() |> then(&%{username: "old-#{&1.username}"})
  end

  # factory :user do
  #   %{hello: params[:world]}
  # end

  # factory :user, params \\ %{}, actions: [:build] do

  # factory :user do
  #   %{hello: params[:world]}
  # end

  # factory :user, params \\ %{}, actions: [:build] do
  #   %{hello: params[:world]}
  # end

  # factory :user, params \\ %{} do
  #   action :build do
  #     %{hello: params[:world]}
  #   end
  # end

  # actions: [
  #   build(params) do
  #     :ok
  #   end,
  #   insert(params) do
  #     :ok
  #   end
  # ],
  # hooks: [before_build: &before_build/1] do
  # params
  # end

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
