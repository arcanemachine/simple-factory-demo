defmodule SimpleFactoryDemo.Factories.Users do
  use SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  factory(User, repo: Repo)

  def build_user(params), do: build(params)

  # build: fn params ->
  #   %{
  #     id: params[:id],
  #     username: params[:username] || Faker.Internet.username(),
  #     author: params[:author]
  #   }
  # end

  # factory User,
  #   repo: Repo,
  #   params: fn params do
  #     %{
  #       id: params[:id],
  #       username: params[:username] || Faker.Internet.username(),
  #       author: params[:author]
  #     }
  #   end

  # factory User do
  #   name :user_factory

  #   # repo Repo

  #   actions [
  #     build: fn attrs -> struct(User, attrs) end,
  #     insert: fn attrs -> struct(User, attrs) |> User.changeset() |> Repo.insert() end,
  #     # insert: fn attrs -> apply_action(:build, attrs) |> User.changeset() |> Repo.insert() end,
  #     insert!: fn attrs -> struct(User, attrs) |> User.changeset() |> Repo.insert!() end
  #   ]

  #   params fn attrs -> do
  #     %{
  #       id: attrs[:id],
  #       username: attrs[:username] || Faker.Internet.username(),
  #       author: attrs[:author]
  #     }
  #   end

  #   changeset [{User, :changeset, 2}]
  # end
end
