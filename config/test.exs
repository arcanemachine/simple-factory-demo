import Config

config :factory_man_demo, FactoryManDemo.Repo,
  database: "factory_man_demo_test",
  username: "postgres",
  password: "your_postgres_password",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox
