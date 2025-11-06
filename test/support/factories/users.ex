defmodule SimpleFactoryDemo.Factories.Users do
  use SimpleFactory

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  factory(User, repo: Repo)
end
