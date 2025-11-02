defmodule SimpleFactoryDemo.Factories.Users do
  # use SimpleFactory, strategy: {SimpleFactory.Strategies.Ecto, repo: SimpleFactoryDemo.Repo}

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  factory User do
    name :user_factory

    # repo Repo

    actions [
      build: fn attrs -> struct(User, attrs) end,
      insert: fn attrs -> struct(User, attrs) |> User.changeset() |> Repo.insert() end,
      # insert: fn attrs -> apply_action(:build, attrs) |> User.changeset() |> Repo.insert() end,
      insert!: fn attrs -> struct(User, attrs) |> User.changeset() |> Repo.insert!() end
    ]

    params fn attrs -> do
      %{
        id: attrs[:id],
        username: attrs[:username] || Faker.Internet.username(),
        author: attrs[:author]
      }
    end

    changeset [{User, :changeset, 2}]
  end
end
