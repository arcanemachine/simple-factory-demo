defmodule SimpleFactoryDemo.Factory do
  import SimpleFactory

  alias SimpleFactoryDemo.Repo
  alias SimpleFactoryDemo.Users.User

  factory User, Repo do
    :ok
  end

  # factory "user_factory" do
  #   hello: :world
  # end
end
