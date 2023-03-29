defmodule Sugarscape.CoordinateTest do
  use ExUnit.Case
  alias Sugarscape.Coordinate

  doctest Coordinate

  @grid_size {50, 50}

  test "distance between coordinates" do
    assert Coordinate.distance({1, 1}, {1, 1}) == 0
    assert Coordinate.distance({3, 1}, {3, 2}) == 1
    assert Coordinate.distance({5, 3}, {7, 3}) == 2
  end

  test "shifting x coordinates" do
    assert Coordinate.shift({1, 1}, @grid_size, :x, 0) == {1, 1}
    assert Coordinate.shift({49, 50}, @grid_size, :x, 2) == {1, 50}
    assert Coordinate.shift({50, 50}, @grid_size, :x, 4) == {4, 50}
    assert Coordinate.shift({2, 50}, @grid_size, :x, -2) == {50, 50}
    assert Coordinate.shift({2, 50}, @grid_size, :x, -3) == {49, 50}
  end

  test "shifting y coordinates" do
    assert Coordinate.shift({50, 50}, @grid_size, :y, 0) == {50, 50}
    assert Coordinate.shift({49, 50}, @grid_size, :y, 2) == {49, 2}
    assert Coordinate.shift({50, 50}, @grid_size, :y, 4) == {50, 4}
  end

  test "converting indices" do
    assert Coordinate.convert_to_index({1, 1}, 2) == 0
    assert Coordinate.convert_to_index({2, 1}, 2) == 1
    assert Coordinate.convert_to_index({1, 2}, 2) == 2
    assert Coordinate.convert_to_index({2, 2}, 2) == 3
  end
end
