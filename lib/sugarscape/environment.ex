defmodule Sugarscape.Environment do
  @moduledoc """
  Provides the Environment struct
  """

  alias Sugarscape.Agent
  alias Sugarscape.Coordinate
  alias Sugarscape.Grid
  alias Sugarscape.Perlin
  alias Sugarscape.Resource

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
  @spec two_hills(pos_integer, pos_integer) :: __MODULE__.t()
  def two_hills(width, height) do
    initialize_resource = fn coordinate ->
      coordinate
      |> assign_level()
      |> Resource.new()
    end

    initialize_agent = fn coordinate ->
      if Enum.random([true, false]) do
        {:ok, pid} = Agent.start_link(coordinate)
        pid
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

  @spec update_resource_at(
          __MODULE__.t(),
          Coordinate.t(),
          ({Resource.t(), pid | nil} -> {Resource.t(), pid | nil})
        ) ::
          __MODULE__.t()
  def update_resource_at(environment, coordinate, updater) do
    %__MODULE__{
      environment
      | grid: Grid.update_at(environment.grid, coordinate, &updater.(&1))
    }
  end

  @spec get_agents(__MODULE__.t()) :: [pid]
  def get_agents(environment) do
    environment.grid.data
    |> Enum.map(fn %{data: {_resource, agent_pid}} -> agent_pid end)
    |> Enum.filter(fn pid -> pid != nil end)
  end

  @spec tick(__MODULE__.t()) :: __MODULE__.t()
  def tick(environment) do
    new_environment =
      environment
      |> get_agents()
      |> List.foldl(environment, fn agent_pid, env -> Agent.take_turn(agent_pid, env) end)

    # Grow resources and remove perished agents
    new_grid =
      new_environment.grid
      |> Grid.map_data(fn {resource, agent} ->
        {Resource.calculate_new_level(resource), agent}
      end)

    %__MODULE__{new_environment | grid: new_grid}
  end

  @spec tick(__MODULE__.t(), pos_integer) :: __MODULE__.t()
  def tick(environment, n) do
    Enum.to_list(1..n)
    |> List.foldl(environment, fn _, env -> tick(env) end)
  end

  def shift_coordinate({width, _height}, {x, y}, :x, amount) do
    # Change from 1-indexed to 0-indexed before modulo and then change
    # back to 1-indexed.
    {wraparound_value(x - 1 + amount, width) + 1, y}
  end

  def shift_coordinate({_width, height}, {x, y}, :y, amount) do
    # Change from 1-indexed to 0-indexed before modulo and then change
    # back to 1-indexed.
    {x, wraparound_value(y - 1 + amount, height) + 1}
  end

  defp wraparound_value(value, mod) do
    result = rem(value, mod)

    if result >= 0 do
      result
    else
      mod + result
    end
  end

  @spec get_visible_locations(__MODULE__.t(), any, Coordinate.t()) :: [
          {Coordinate.t(), Resource.t()}
        ]
  def get_visible_locations(environment, {:lattice, vision}, coordinate) do
    grid_size = {_width, _height} = environment.grid.size

    horizontal =
      [-vision..-1, 1..vision]
      |> Enum.concat()
      |> Enum.map(fn shift -> shift_coordinate(grid_size, coordinate, :x, shift) end)
      |> Enum.map(&{&1, get_resource_at(environment, &1)})

    vertical =
      [-vision..-1, 1..vision]
      |> Enum.concat()
      |> Enum.map(fn shift -> shift_coordinate(grid_size, coordinate, :y, shift) end)
      |> Enum.map(&{&1, get_resource_at(environment, &1)})

    Enum.concat(horizontal, vertical)
  end

  @spec get_resource_at(__MODULE__.t(), Coordinate.t()) :: Resource.t()
  def get_resource_at(environment, location) do
    {%Resource{} = resource, _agent_pid} = Grid.index(environment.grid, location)
    resource
  end

  @doc """
  Flatten an environment down to a list of maps consisting of the (x,y)-coordinates
  and the level of the resource at each coordinate
  """
  @spec flatten_to_resources(__MODULE__.t()) :: [
          %{x: pos_integer, y: pos_integer, level: pos_integer}
        ]
  def flatten_to_resources(environment) do
    environment.grid
    |> Grid.map(fn _x, _y, {resource, _agent} -> %{level: resource.level} end)
  end

  @doc """
  Flatten an environment down to a list of maps consisting of the (x,y)-coordinates
  and the agent at each coordinate
  """
  @spec flatten_to_agents(__MODULE__.t()) :: [
          %{x: pos_integer, y: pos_integer, agent: Agent.t()}
        ]
  def flatten_to_agents(environment) do
    environment.grid
    |> Grid.map(fn _x, _y, {_resource, pid} -> %{agent: pid} end)
    |> Enum.filter(fn %{agent: pid} -> pid != nil end)
    |> Enum.map(fn %{agent: pid} = map ->
      state =
        Agent.get_state(pid)
        |> Map.from_struct()
        |> Map.update!(:location, &Tuple.to_list(&1))

      Map.replace(map, :agent, state)
    end)
  end

  @doc """
  Return a `VegaLite` graphics specification that can be displayed in a
  Livebook notebook. This will display an environment's layout of resources
  on the environment's grid.
  """
  @spec view_resources(__MODULE__.t(), String.t()) :: VegaLite.t()
  def view_resources(environment, title) do
    VegaLite.new(title: title, width: 500, height: 500)
    |> VegaLite.data_from_values(flatten_to_resources(environment))
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
    |> VegaLite.data_from_values(flatten_to_agents(environment))
    |> VegaLite.mark(:point,
      color: "red",
      filled: true,
      opacity: 0.8,
      tooltip: true
    )
    |> VegaLite.encode_field(:x, "x", title: "X location")
    |> VegaLite.encode_field(:y, "y", title: "Y location")

    # |> VegaLite.encode_field(:size, "agent.vision",
    #   title: "Agent vision",
    #   legend: [title: "Agent vision"]
    # )
  end

  @doc """
  Determines whether the given location is occupied by an agent or is empty
  """
  @spec occupied?(__MODULE__.t(), Coordinate.t()) :: boolean
  def occupied?(environment, {x, y}) do
    environment.grid
    |> Grid.index({x, y})
    |> elem(1)
    |> Kernel.!==(nil)
  end

  # Assigns a resource level to the given (x,y)-coordinate
  @spec assign_level(Coordinate.t()) :: number
  defp assign_level({x, y}) do
    amplitude = 4

    @gaussian_hill_centers
    |> Enum.min_by(fn center -> Coordinate.distance({x, y}, center) end)
    |> gaussian({x, y}, amplitude)
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

  # Calculates a Gaussian distribution given the (x,y)-coordinate and another
  # (x_c, y_c)-coordinate for the center of the distribution.
  @spec gaussian(Coordinate.t(), Coordinate.t(), number) :: number
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
