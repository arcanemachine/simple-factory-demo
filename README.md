# FactoryManDemo

A demo repo for the [FactoryMan](https://github.com/arcanemachine/simple-factory/) project.

This repo shows how you can use FactoryMan to build factories for your Elixir projects.

See [this directory](https://github.com/arcanemachine/simple-factory-demo/blob/main/test/support/factories/) for examples of the repo in action.

## Getting started

This repo can be cloned as a way of examining the mechanics of FactoryMan:

- Clone the repo: `https://github.com/arcanemachine/simple-factory-demo`

- Navigate to the repo: `cd simple-factory-demo`

- Install the dependencies: `mix deps.get`

- Set up the database: `mix ecto.setup`
  - NOTE: You will need to modify the config to work with your Postgres instance. If you skip this step, you can still `build` factories, you just won't be able to `insert` them into the database.

- Open a shell in the `:test` Mix environment: `MIX_ENV=test iex -S mix`

- This repo models a simple blog. You can create Users, Authors, Posts, and Tags:

```elixir
post = FactoryManDemo.Factories.Posts.insert!(:post)
%FactoryManDemo.Posts.Post{
  __meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  id: 1,
  author_id: 1,
  title: "A post",
  content: "A post content",
  inserted_at: ~N[2025-03-02 22:05:43],
  updated_at: ~N[2025-03-02 22:05:43],
  author: %FactoryManDemo.Authors.Author{
    __meta__: #Ecto.Schema.Metadata<:loaded, "authors">,
    id: 1,
    user_id: 1,
    name: "Allison Anderson",
    user: #Ecto.Association.NotLoaded<association :user is not loaded>,
    posts: #Ecto.Association.NotLoaded<association :posts is not loaded>
  },
  tags: [
    %FactoryManDemo.Tags.Tag{
      __meta__: #Ecto.Schema.Metadata<:loaded, "tags">,
      id: 1,
      name: "hello",
      posts: #Ecto.Association.NotLoaded<association :posts is not loaded>
    }
  ]
}
```
