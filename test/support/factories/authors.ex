defmodule FactoryManDemo.Factories.Authors do
  use FactoryMan, extends: FactoryManDemo.Factory

  # alias FactoryManDemo.Authors.Author
  # alias FactoryManDemo.Factories.Users

  # factory :author do
  #   %Author{
  #     user: params[:user] || Users.build_user(),
  #     id: params[:id],
  #     name: Map.get(params, :name, "Some author")
  #   }
  # end
end
