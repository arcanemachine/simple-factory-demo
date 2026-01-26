import Config

config :factory_man_demo, ecto_repos: [FactoryManDemo.Repo]

config :factory_man_demo, FactoryManDemo.Repo,
  username: "postgres",
  password: "your_postgres_password",
  database: "factory_man_demo",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :logger, level: System.get_env("LOGGER_LEVEL", "warning") |> String.to_existing_atom()
