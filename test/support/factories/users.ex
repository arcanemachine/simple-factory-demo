defmodule SimpleFactoryDemo.Factories.Users do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Users.User

  factory(User,
    build:
      (
        def build_user(params \\ %{})

        def build_user(%{hello: :world}) do
          # struct(User, params)
          :a
        end

        def build_user(params) do
          struct(User, params)
        end
      )
  )

  # def build_user(params \\ %{}) do
  #   super(params) |> IO.inspect(label: :fixme1)
  # end

  # def hello, do: Factory.get_opts()

  # Factory.factory(User)

  # def hello2, do: hello()

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
