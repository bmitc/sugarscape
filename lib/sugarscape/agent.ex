defmodule Sugarscape.Agent do
  @moduledoc """
  Implements a standalone agent as a `GenServer`
  """

  use GenServer

  alias Sugarscape.Environment
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
  def handle_call({:take_turn, environment}, _from, state) do
    {:reply, environment, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
