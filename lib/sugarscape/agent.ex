defmodule Sugarscape.Agent do
  @moduledoc """
  Implements a standalone agent as a `GenServer`
  """

  use GenServer

  alias Sugarscape.Environment
  alias Sugarscape.Resource
  alias Sugarscape.Types

  @enforce_keys [:location, :vision, :metabolism, :sugar_holdings, :state]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          location: Types.coordinate(),
          # vision range = [1, 6]
          vision: pos_integer,
          # metabolism range = [1, 4]
          metabolism: pos_integer,
          sugar_holdings: non_neg_integer,
          state: :alive
        }

  @type state :: :alive | :perished

  @type message :: {:take_turn, Environment.t()} | :get_state

  @doc """
  Starts an agent `GenServer` with the given location
  """
  @spec start_link(Types.coordinate()) :: GenServer.on_start()
  def start_link(initial_location) do
    GenServer.start_link(__MODULE__, {initial_location, Enum.random(1..6), Enum.random(1..4)})
  end

  @spec get_state(pid) :: {:ok, __MODULE__.t()} | any
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def take_turn(pid, environment) do
    GenServer.call(pid, {:take_turn, environment})
  end

  ############################################################
  #### GenServer callbacks ###################################
  ############################################################

  @impl GenServer
  @spec init({Types.coordinate(), pos_integer(), pos_integer()}) :: {:ok, __MODULE__.t()}
  def init({initial_location, vision, metabolism}) do
    {:ok,
     %__MODULE__{
       location: initial_location,
       vision: vision,
       metabolism: metabolism,
       sugar_holdings: 0,
       state: :alive
     }}
  end

  @impl GenServer
  def handle_call({:take_turn, environment}, _from, agent) do
    visible_locations =
      Environment.get_visible_locations(environment, {:lattice, agent.vision}, agent.location)

    {_, %Resource{level: maximum_resource_level}} =
      Enum.max_by(visible_locations, fn {_, %Resource{} = resource} -> resource.level end)

    {{_x, _y} = closest_location, %Resource{} = closest_resource} =
      visible_locations
      |> Enum.filter(fn {_, %Resource{} = resource} ->
        resource.level == maximum_resource_level
      end)
      |> Enum.sort_by(fn {coordinate, _} ->
        Environment.calculate_distance(coordinate, agent.location)
      end)
      |> List.first()

    new_sugar_holdings = agent.sugar_holdings + closest_resource.level - agent.metabolism

    new_agent = %__MODULE__{
      agent
      | location: closest_location,
        sugar_holdings: new_sugar_holdings,
        state:
          if new_sugar_holdings == 0 do
            :perished
          else
            :alive
          end
    }

    new_environment =
      environment
      # Remove agent from current location
      |> Environment.update_resource_at(agent.location, fn {%Resource{} = resource, _agent} ->
        {resource, nil}
      end)
      # Take away all of the resource at the new location and add new agent
      |> Environment.update_resource_at(closest_location, fn {%Resource{} = resource, _agent} ->
        {%Resource{resource | level: 0},
         if is_alive?(new_agent) do
           self()
         else
           nil
         end}
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

  @spec is_alive?(__MODULE__.t()) :: boolean
  def is_alive?(agent) do
    agent.state == :alive
  end
end
