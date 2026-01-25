defmodule FactoryManDemo.Repo do
  use Ecto.Repo,
    otp_app: :factory_man_demo,
    adapter: Ecto.Adapters.Postgres
end
