defmodule SimpleFactoryDemo.Users do
  @moduledoc "The Users context."

  alias SimpleFactoryDemo.Users.User
  alias SimpleFactoryDemo.Repo

  def insert_user(attrs), do: attrs |> User.changeset() |> Repo.insert()

  def get_user(user_id) when is_integer(user_id), do: Repo.get(User, user_id)

  def update_user(%User{} = user, attrs), do: user |> User.changeset(attrs) |> Repo.update()

  def delete_user(%User{} = user), do: Repo.delete(user)
end
