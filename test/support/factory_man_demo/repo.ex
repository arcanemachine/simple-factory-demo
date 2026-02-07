defmodule FactoryManDemo.Repo do
  use Ecto.Repo,
    otp_app: :factory_man,
    adapter: Ecto.Adapters.Postgres
end
