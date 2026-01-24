import Config

config :simple_factory_demo, ecto_repos: [SimpleFactoryDemo.Repo]

config :simple_factory_demo, SimpleFactoryDemo.Repo,
  database: "simple_factory_demo",
  username: "postgres",
  password: "your_postgres_password",
  hostname: System.get_env("POSTGRES_HOST", "localhost")

import_config "#{config_env()}.exs"
