defmodule Sugarscape.Agent do
  @moduledoc """
  Implements a standalone agent as a `GenServer`
  """

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
          state: :alive | :perished
        }

  ############################################################
  #### Public functions ######################################
  ############################################################

  @doc """
  Creates a new agent
  """
  @spec new(Coordinate.t()) :: __MODULE__.t()
  def new(initial_location) do
    new(initial_location, Enum.random(1..6), Enum.random(1..4))
  end

  @doc """
  Creates a new agent
  """
  @spec new(Coordinate.t(), pos_integer(), pos_integer()) :: __MODULE__.t()
  def new(initial_location, vision, metabolism) do
    %__MODULE__{
      location: initial_location,
      vision: vision,
      metabolism: metabolism,
      sugar_holdings: 6,
      state: :alive
    }
  end

  @spec take_turn(Environment.t(), __MODULE__.t()) :: Environment.t()
  def take_turn(%Environment{} = environment, %__MODULE__{} = agent) do
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
      |> Environment.update_at(agent.location, fn {resource, _agent} ->
        {resource, nil}
      end)
      # Take away all of the resource at the new location and add the new agent.
      # There should be a resource at this location, i.e., not nil, so force the pattern
      # match to check it's a %Resource{}.
      |> Environment.update_at(closest_location, fn {resource, _agent} ->
        {
          case resource do
            nil -> nil
            %Resource{} -> %Resource{resource | level: 0}
          end,
          if is_alive?(new_agent) do
            new_agent
          else
            nil
          end
        }
      end)

    new_environment
  end

  ############################################################
  #### Private functions #####################################
  ############################################################

  # Determines whether the agent is alive or has perished
  @spec is_alive?(__MODULE__.t()) :: boolean
  defp is_alive?(agent), do: agent.state == :alive
end
