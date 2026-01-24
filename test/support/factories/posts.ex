defmodule SimpleFactoryDemo.Factories.Posts do
  use FactoryMan, extends: SimpleFactoryDemo.Factory

  alias SimpleFactoryDemo.Posts.Post
  alias SimpleFactoryDemo.Factories.Authors

  factory(
    name: :post,
    build:
      quote do
        def build_post(params \\ %{}) do
          %Post{
            author: params[:author] || Authors.build_author(),
            id: params[:id],
            title: Map.get(params, :title, "Sample Post Title"),
            content: Map.get(params, :content, "This is sample post content."),
            tags: params[:tags] || []
          }
        end
      end
  )
end
