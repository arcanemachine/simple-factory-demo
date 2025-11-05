defmodule SimpleFactoryDemo.Factory do
  import SimpleFactory

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  @factory_repo Repo

  factory(User, repo: Repo)

  # factory "user_factory" do
  #   hello: :world
  # end
end
