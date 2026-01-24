defmodule FactoryManDemo.Factories.Tags do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Tags.Tag

  factory :tag do
    %Tag{
      id: params[:id],
      name: Map.get(params, :name, "sample-tag-#{System.os_time()}"),
      posts: params[:posts] || []
    }
  end
end
