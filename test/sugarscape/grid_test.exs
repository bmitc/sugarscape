defmodule Sugarscape.GridTest do
  use ExUnit.Case
  alias Sugarscape.Grid

  doctest Grid

  test "new grid is in lexicographic order, ordered first by the x-coordinate" do
    grid = Grid.new(2, 3, &Function.identity/1)

    expected_data = [
      %{x: 1, y: 1, data: {1, 1}},
      %{x: 2, y: 1, data: {2, 1}},
      %{x: 1, y: 2, data: {1, 2}},
      %{x: 2, y: 2, data: {2, 2}},
      %{x: 1, y: 3, data: {1, 3}},
      %{x: 2, y: 3, data: {2, 3}}
    ]

    assert grid.data == expected_data
  end

  test "grid size" do
    grid = Grid.new(7, 4, &Function.identity/1)

    assert Grid.size(grid) == {7, 4}
    assert Grid.width(grid) == 7
    assert Grid.height(grid) == 4
  end

  test "mapping over a grid" do
    mapped_grid =
      Grid.new(2, 3, fn {x, y} -> x + y end)
      |> Grid.map(fn _x, _y, data -> %{new_data: Integer.to_string(data)} end)

    expected_map_list = [
      %{x: 1, y: 1, new_data: "2"},
      %{x: 1, y: 2, new_data: "3"},
      %{x: 1, y: 3, new_data: "4"},
      %{x: 2, y: 1, new_data: "3"},
      %{x: 2, y: 2, new_data: "4"},
      %{x: 2, y: 3, new_data: "5"}
    ]

    assert Enum.sort(mapped_grid) == Enum.sort(expected_map_list)
  end

  test "indexing a grid" do
    grid = Grid.new(2, 3, &Function.identity/1)

    assert Grid.index(grid, {1, 2}) == {1, 2}
  end

  test "updating a grid element" do
    grid =
      Grid.new(2, 3, &Function.identity/1)
      |> Grid.update_at({2, 3}, fn {x, y} -> x * y end)

    assert Grid.index(grid, {2, 3}) == 6
  end
end
