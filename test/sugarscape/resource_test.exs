defmodule Sugarscape.ResourceTest do
  use ExUnit.Case
  alias Sugarscape.Resource

  doctest Resource

  test "calculating new resource level" do
    resource =
      Resource.new(0, 4, 1)
      |> Resource.calculate_new_level()

    assert resource.level == 1
  end

  test "calculating new resource level when reaching capacity" do
    resource =
      Resource.new(3, 4, 1)
      |> Resource.calculate_new_level()

    assert resource.level == 4
  end

  test "calculating new resource level when already at capacity" do
    resource =
      Resource.new(4, 4, 1)
      |> Resource.calculate_new_level()

    assert resource.level == 4
  end
end
