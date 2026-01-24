defmodule FactoryManDemo.Factories.Posts do
  use FactoryMan, extends: FactoryManDemo.Factory

  alias FactoryManDemo.Posts.Post
  alias FactoryManDemo.Factories.Authors

  factory :post do
    %Post{
      author: params[:author] || Authors.build_author(),
      id: params[:id],
      title: Map.get(params, :title, "Sample Post Title"),
      content: Map.get(params, :content, "This is sample post content."),
      tags: params[:tags] || []
    }
  end
end
