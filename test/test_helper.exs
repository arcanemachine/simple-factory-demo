# Start the demo application for tests
{:ok, _} = FactoryManDemo.Application.start(:normal, [])

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FactoryManDemo.Repo, :manual)
