defmodule SimpleFactoryDemo.Factories.Tags do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Tags.Tag

  factory(
    name: :tag,
    build:
      quote do
        def build_tag(params \\ %{}) do
          %Tag{
            id: params[:id],
            name: Map.get(params, :name, "sample-tag-#{System.os_time(:second)}"),
            posts: params[:posts] || []
          }
        end
      end
  )
end
