import Config

config :factory_man_demo, ecto_repos: [FactoryManDemo.Repo]

config :factory_man_demo, FactoryManDemo.Repo,
  database: "factory_man_demo",
  username: "postgres",
  password: "your_postgres_password",
  hostname: System.get_env("POSTGRES_HOST", "localhost")

import_config "#{config_env()}.exs"
