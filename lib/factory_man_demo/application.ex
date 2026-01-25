defmodule FactoryManDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FactoryManDemo.Repo
    ]

    opts = [strategy: :one_for_one, name: FactoryManDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
