defmodule SugarscapeTest do
  use ExUnit.Case
  doctest Sugarscape

  test "greets the world" do
    assert Sugarscape.hello() == :world
  end
end
