defmodule Sugarscape.Environment do
  @moduledoc """
  Provides the Environment struct
  """

  alias Sugarscape.Agent
  alias Sugarscape.Grid
  alias Sugarscape.Perlin
  alias Sugarscape.Resource
  alias Sugarscape.Types

  alias VegaLite

  @enforce_keys [:grid]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          grid: Grid.t({Resource.t(), agent :: pid | nil})
        }

  @left_lower_quadrant_center {16, 36}
  @right_upper_quadrant_center {40, 10}

  # These values are hand picked in order to replicate the sugarscape environment
  # found in the book
  @gaussian_hill_centers [@right_upper_quadrant_center, @left_lower_quadrant_center]
  @gaussian_spread 9.3

  @doc """
  Creates a new environment with two hills in the lower left and upper right quadrants
  with their sugar distributed via a Gaussian distribution starting from the hill center
  """
  @spec new_gaussian(pos_integer, pos_integer) :: __MODULE__.t()
  def new_gaussian(width, height) do
    initialize_resource = fn coordinate ->
      coordinate
      |> assign_level()
      |> Resource.new()
    end

    initialize_agent = fn coordinate ->
      if Enum.random([true, false]) do
        Agent.start_link(coordinate)
      else
        nil
      end
    end

    %__MODULE__{
      grid:
        Grid.new(width, height, fn coordinate ->
          {initialize_resource.(coordinate), initialize_agent.(coordinate)}
        end)
    }
  end

  @doc """
  Flattens an environment down to a list of maps consisting of the (x,y)-coordinates
  and the level of the resource at each coordinate
  """
  @spec flatten(__MODULE__.t()) :: [%{x: pos_integer, y: pos_integer, level: pos_integer}]
  def flatten(environment) do
    environment.grid
    |> Grid.map(fn _x, _y, {resource, _agent} -> %{level: resource.level} end)
  end

  @doc """
  Return a `VegaLite` graphics specification that can be displayed in a
  Livebook notebook. This will display an environment's layout of resources
  on the environment's grid.
  """
  @spec view_resources(__MODULE__.t(), String.t()) :: VegaLite.t()
  def view_resources(environment, title) do
    VegaLite.new(title: title, width: 500, height: 500)
    |> VegaLite.data_from_values(flatten(environment))
    |> VegaLite.mark(:rect,
      opacity: 0.8,
      tooltip: true
    )
    |> VegaLite.encode_field(:x, "x", title: "X location")
    |> VegaLite.encode_field(:y, "y", title: "Y location")
    |> VegaLite.encode_field(:color, "level",
      title: "Sugar level",
      type: :ordinal,
      legend: [title: "Sugar level"]
    )
  end

  @doc """
  Return a `VegaLite` graphics specification that can be displayed in a
  Livebook notebook. This will display an environment's layout of agents
  on the environment's grid.
  """
  @spec view_agents(__MODULE__.t(), String.t()) :: VegaLite.t()
  def view_agents(environment, title) do
    VegaLite.new(title: title, width: 500, height: 500)
    |> VegaLite.data_from_values(
      environment.grid
      |> Grid.map(fn _x, _y, {_resource, agent} -> %{agent: agent} end)
      |> Enum.filter(fn %{agent: agent} -> agent != nil end)
      |> Enum.map(fn point -> Map.replace(point, :agent, true) end)
    )
    |> VegaLite.mark(:point,
      color: "red",
      filled: true,
      opacity: 0.8,
      tooltip: true
    )
    |> VegaLite.encode_field(:x, "x", title: "X location")
    |> VegaLite.encode_field(:y, "y", title: "Y location")
  end

  @doc """
  Determines whether the given location is occupied by an agent or is empty
  """
  @spec occupied?(__MODULE__.t(), Types.coordinate()) :: boolean
  def occupied?(environment, {x, y}) do
    environment.grid
    |> Grid.index({x, y})
    |> elem(1)
    |> Kernel.!==(nil)
  end

  # Assigns a resource level to the given (x,y)-coordinate
  @spec assign_level(Types.coordinate()) :: number
  defp assign_level({x, y}) do
    amplitude = 4

    @gaussian_hill_centers
    |> Enum.min_by(fn center -> calculate_distance({x, y}, center) end)
    |> gaussian({x, y}, amplitude)
    |> round()
  end

  # Calculates the distance between two coordinates
  @spec calculate_distance(Types.coordinate(), Types.coordinate()) :: number
  defp calculate_distance({x1, y1}, {x2, y2}) do
    (:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
    |> :math.sqrt()
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

  # Calculates a Gaussian distribution given the (x,y)-coordinate and another
  # (x_c, y_c)-coordinate for the center of the distribution.
  @spec gaussian(Types.coordinate(), Types.coordinate(), number) :: number
  defp gaussian({center_x, center_y}, {x, y}, amplitude) do
    noise = Perlin.noise(to_float(x), to_float(y), 0.5)
    {x, y} = {x + noise, y + noise}
    # As noted above, the spread is hand picked
    spread_x = @gaussian_spread
    spread_y = @gaussian_spread

    # Standard formula for a 2D Gaussian distribution
    x_component = :math.pow(x - center_x, 2) / (2 * :math.pow(spread_x, 2))
    y_component = :math.pow(y - center_y, 2) / (2 * :math.pow(spread_y, 2))

    (x_component + y_component)
    |> Kernel.*(-1)
    |> :math.exp()
    |> Kernel.*(amplitude)
  end

  # Convert a number to a `float` type
  @spec to_float(number) :: float
  defp to_float(number), do: number / 1
end
