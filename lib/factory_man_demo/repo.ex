defmodule FactoryManDemo.Repo do
  use Ecto.Repo,
    otp_app: :simple_factory_demo,
    adapter: Ecto.Adapters.Postgres
end
