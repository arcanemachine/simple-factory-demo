defmodule SimpleFactoryDemoTest do
  use ExUnit.Case
  doctest SimpleFactoryDemo

  test "greets the world" do
    assert SimpleFactoryDemo.hello() == :world
  end
end
