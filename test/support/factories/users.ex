defmodule FactoryManDemo.Factories.Users do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Users.User

  factory :user do
    %User{
      id: params[:id],
      username: Map.get(params, :username, "user-#{System.os_time()}"),
      author: params[:author]
    }
  end

end
