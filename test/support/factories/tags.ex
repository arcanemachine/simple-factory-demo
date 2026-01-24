defmodule SimpleFactoryDemo.Factories.Tags do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Tags.Tag

  factory :tag do
    %Tag{
      id: params[:id],
      name: Map.get(params, :name, "sample-tag-#{System.os_time()}"),
      posts: params[:posts] || []
    }
  end
end
