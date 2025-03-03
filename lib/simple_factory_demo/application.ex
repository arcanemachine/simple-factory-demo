defmodule SimpleFactoryDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SimpleFactoryDemo.Repo
    ]

    opts = [strategy: :one_for_one, name: SimpleFactoryDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
