defmodule Sugarscape.EnvironmentTest do
  use ExUnit.Case
  alias Sugarscape.Environment

  doctest Environment

  @grid_size {50, 50}

  test "shifting x coordinates" do
    assert Environment.shift_coordinate(@grid_size, {1, 1}, :x, 0) == {1, 1}
    assert Environment.shift_coordinate(@grid_size, {49, 50}, :x, 2) == {1, 50}
    assert Environment.shift_coordinate(@grid_size, {50, 50}, :x, 4) == {4, 50}
    assert Environment.shift_coordinate(@grid_size, {2, 50}, :x, -2) == {50, 50}
    assert Environment.shift_coordinate(@grid_size, {2, 50}, :x, -3) == {49, 50}
  end

  test "shifting y coordinates" do
    assert Environment.shift_coordinate(@grid_size, {50, 50}, :y, 0) == {50, 50}
    assert Environment.shift_coordinate(@grid_size, {49, 50}, :y, 2) == {49, 2}
    assert Environment.shift_coordinate(@grid_size, {50, 50}, :y, 4) == {50, 4}
  end
end
