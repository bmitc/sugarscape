defmodule Sugarscape.Agent do
  @moduledoc """
  Implements a standalone agent as a `GenServer`
  """

  use GenServer

  alias Sugarscape.Coordinate
  alias Sugarscape.Environment
  alias Sugarscape.Resource

  @enforce_keys [:location, :vision, :metabolism, :sugar_holdings, :state]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          location: Coordinate.t(),
          # vision range = [1, 6]
          vision: pos_integer,
          # metabolism range = [1, 4]
          metabolism: pos_integer,
          sugar_holdings: non_neg_integer,
          state: :alive
        }

  @type state :: :alive | :perished

  @type message :: {:take_turn, Environment.t()} | :get_state

  ############################################################
  #### Public functions ######################################
  ############################################################

  @doc """
  Creates a new agent state
  """
  @spec new(Coordinate.t()) :: __MODULE__.t()
  def new(initial_location) do
    new(initial_location, Enum.random(1..6), Enum.random(1..4))
  end

  @doc """
  Creates a new agent state
  """
  @spec new(Coordinate.t(), pos_integer(), pos_integer()) :: __MODULE__.t()
  def new(initial_location, vision, metabolism) do
    %__MODULE__{
      location: initial_location,
      vision: vision,
      metabolism: metabolism,
      sugar_holdings: 0,
      state: :alive
    }
  end

  @doc """
  Starts an agent `GenServer` with the given location
  """
  @spec start_link(Coordinate.t()) :: GenServer.on_start()
  def start_link(initial_location) when is_tuple(initial_location) do
    GenServer.start_link(__MODULE__, new(initial_location))
  end

  @spec get_state(pid) :: {:ok, __MODULE__.t()} | any
  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end

  @spec take_turn(pid, Environment.t()) :: any
  def take_turn(pid, %Environment{} = environment) when is_pid(pid) do
    GenServer.call(pid, {:take_turn, environment})
  end

  ############################################################
  #### GenServer callbacks ###################################
  ############################################################

  @impl GenServer
  @spec init(__MODULE__.t()) :: {:ok, __MODULE__.t()}
  def init(agent), do: {:ok, agent}

  @impl GenServer
  def handle_call({:take_turn, environment}, _from, agent) do
    # Get all the visible locations in the horizontal and vertical directions
    # using the agent's vision. visible_locations is a list of {Coordinate.t(), Resource.t()}.
    visible_locations =
      environment
      |> Environment.get_visible_locations({:lattice, agent.vision}, agent.location)
      |> Enum.shuffle()

    # Get the maximum resource level that the agent can see
    maximum_resource_level =
      Enum.max_by(visible_locations, fn {_, resource} ->
        case resource do
          nil -> 0
          %Resource{} -> resource.level
        end
      end)
      |> case do
        {_, nil} -> 0
        {_, %Resource{} = resource} -> resource.level
      end

    # Find the closest coordinate location that has the maximum resource level
    {closest_location, _closest_resource} =
      if maximum_resource_level == 0 do
        {agent.location, nil}
      else
        visible_locations
        |> Enum.filter(fn {_, resource} ->
          if maximum_resource_level != 0 do
            case resource do
              nil -> false
              %Resource{} -> resource.level == maximum_resource_level
            end
          else
            case resource do
              nil -> true
              %Resource{} -> resource.level == 0
            end
          end
        end)
        |> Enum.shuffle()
        |> Enum.sort_by(
          fn {coordinate, _} -> Coordinate.distance(coordinate, agent.location) end,
          fn distance1, distance2 -> distance1 <= distance2 end
        )
        |> List.first()
      end

    new_sugar_holdings = agent.sugar_holdings + maximum_resource_level - agent.metabolism

    new_agent = %__MODULE__{
      agent
      | location: closest_location,
        sugar_holdings: new_sugar_holdings,
        state:
          if new_sugar_holdings <= 0 do
            :perished
          else
            :alive
          end
    }

    new_environment =
      environment
      # Remove agent from current location. There may not be a resource at the location,
      # i.e., it's nil, so don't force a %Resource{} in the pattern match.
      |> Environment.update_at(agent.location, fn {resource, _agent_pid} ->
        {resource, nil}
      end)
      # Take away all of the resource at the new location and add new agent's PID.
      # There should be a resource at this location, i.e., not nil, so force the pattern
      # match to check it's a %Resource{}.
      |> Environment.update_at(closest_location, fn {resource, _agent_pid} ->
        {
          case resource do
            nil -> nil
            %Resource{} -> %Resource{resource | level: 0}
          end,
          if is_alive?(new_agent) do
            self()
          else
            nil
          end
        }
      end)

    case new_agent.state do
      :alive ->
        {:reply, new_environment, new_agent}

      _ ->
        {:reply, new_environment, new_agent}
        # :perished -> {:stop, "Agent has perished", new_environment, new_agent}
    end
  end

  def handle_call(:get_state, _from, agent) do
    {:reply, agent, agent}
  end

  ############################################################
  #### Private functions #####################################
  ############################################################

  # Determines whether the agent is alive or has perished
  @spec is_alive?(__MODULE__.t()) :: boolean
  defp is_alive?(agent), do: agent.state == :alive
end
