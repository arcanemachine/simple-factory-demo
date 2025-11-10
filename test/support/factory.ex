defmodule SimpleFactoryDemo.Factory do
  use FactoryMan, repo: SimpleFactoryDemo.Repo

  @factory_opts |> IO.inspect(label: __MODULE__)
end
