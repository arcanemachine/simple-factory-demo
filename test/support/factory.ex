defmodule SimpleFactoryDemo.Factory do
  use SimpleFactory, repo: SimpleFactory.Repo

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  factory(User, repo: Repo)
end
