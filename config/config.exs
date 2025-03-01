import Config

config :simple_factory_demo, ecto_repos: [SimpleFactoryDemo.Repo]

config :simple_factory_demo, SimpleFactoryDemo.Repo,
  database: "simple_factory_demo",
  username: "postgres_user",
  password: "postgres_password",
  hostname: "localhost"
