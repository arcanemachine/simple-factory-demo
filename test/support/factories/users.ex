defmodule SimpleFactoryDemo.Factories.Users do
  # , repo: Repo
  import SimpleFactoryDemo.Factory

  get_parent_factory_opts()

  # def hello2, do: hello()

  # alias SimpleFactoryDemo.Users.User

  # @factory_repo Repo

  # import SimpleFactoryDemo.Factory

  # factory(User, hello: :people, something: :else)
  # factory(User, hello: :people)

  # def build_user(params), do: build(params)

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
