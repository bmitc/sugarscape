defmodule Sugarscape.Environment do
  @moduledoc """
  Provides the Environment struct
  """

  alias Sugarscape.Grid
  alias Sugarscape.Resource

  @enforce_keys [:grid]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          grid: Grid.t(Resource.t())
        }

  @type coordinate :: {non_neg_integer(), non_neg_integer()}

  @left_lower_quadrant_center {16, 36}
  @right_upper_quadrant_center {40, 10}

  @spec new_gaussian(pos_integer, pos_integer) :: __MODULE__.t()
  def new_gaussian(width, height) do
    %__MODULE__{
      grid: Grid.new(width, height, &(assign_level(&1, &2) |> Resource.new()))
    }
  end

  @spec flatten(__MODULE__.t()) :: [%{x: pos_integer, y: pos_integer, level: pos_integer}]
  def flatten(environment) do
    environment.grid
    |> Grid.map(fn _x, _y, resource -> %{level: resource.level} end)
  end

  @spec assign_level(number, number) :: number
  defp assign_level(x, y) do
    amplitude = 4

    {quadrant2_x, quadrant2_y} = @right_upper_quadrant_center
    {quadrant3_x, quadrant3_y} = @left_lower_quadrant_center

    distance_to_quadrant2_center =
      :math.sqrt(:math.pow(x - quadrant2_x, 2) + :math.pow(y - quadrant2_y, 2))

    distance_to_quadrant3_center =
      :math.sqrt(:math.pow(x - quadrant3_x, 2) + :math.pow(y - quadrant3_y, 2))

    if distance_to_quadrant2_center <= distance_to_quadrant3_center do
      gaussian(x, y, quadrant2_x, quadrant2_y, amplitude)
    else
      gaussian(x, y, quadrant3_x, quadrant3_y, amplitude)
    end
    |> round()
  end

  # @spec get_quadrant(number, number, coordinate) :: atom
  # defp get_quadrant(x, y, {size_x, size_y} = _grid_size) do
  #   cond do
  #     x <= size_x / 2 and y <= size_y / 2 -> :quadrant_one
  #     x >= size_x / 2 and y <= size_y / 2 -> :quadrant_two
  #     x <= size_x / 2 and y >= size_y / 2 -> :quadrant_three
  #     true -> :quadrant_four
  #   end
  # end

  @spec gaussian(number, number, number, number, number) :: number
  defp gaussian(x, y, center_x, center_y, amplitude) do
    spread_x = 10
    spread_y = 10

    x_component = :math.pow(x - center_x, 2) / (2 * :math.pow(spread_x, 2))
    y_component = :math.pow(y - center_y, 2) / (2 * :math.pow(spread_y, 2))

    (x_component + y_component)
    |> Kernel.*(-1)
    |> :math.exp()
    |> Kernel.*(amplitude)
  end
end
