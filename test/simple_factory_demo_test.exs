defmodule FactoryManDemoTest do
  use ExUnit.Case
  doctest FactoryManDemo

  test "greets the world" do
    assert FactoryManDemo.hello() == :world
  end
end
