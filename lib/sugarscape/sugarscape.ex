defmodule Sugarscape.Sugarscape do
  @moduledoc """
  Provides the Sugarscape struct
  """

  alias Nx
  alias Sugarscape.Resource

  @enforce_keys [:grid]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          grid: Nx.Tensor.t(Resource.t())
        }

  @spec new(pos_integer(), pos_integer()) :: __MODULE__.t()
  def new(width, height) do
    for _ <- 1..width do
      for _ <- 1..height do
        Resource.random()
      end
    end
    |> Nx.tensor()
  end
end
