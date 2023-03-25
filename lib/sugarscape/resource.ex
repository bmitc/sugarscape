defmodule Sugarscape.Resource do
  @moduledoc """
  Provides a Resource to be placed on a sugarscape's grid
  """

  @default_maximum_level 4
  @default_capacity @default_maximum_level

  @enforce_keys [:level, :capacity, :growback_rate]
  defstruct @enforce_keys

  @typedoc """
  Represents a sugarscape resource
  """
  @type t :: %__MODULE__{
          level: Range.t(),
          capacity: non_neg_integer(),
          growback_rate: non_neg_integer()
        }

  @spec new(non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          __MODULE__.t()
  def new(minimum_level, maximum_level, initial_capacity, growback_rate) do
    %__MODULE__{
      level: Range.new(minimum_level, maximum_level),
      capacity: initial_capacity,
      growback_rate: growback_rate
    }
  end

  @spec new() :: __MODULE__.t()
  def new() do
    new(0, @default_maximum_level, @default_capacity, 1)
  end

  @spec random() :: __MODULE__.t()
  def random() do
    maximum_level = Enum.random(0..@default_maximum_level)
    new(0, maximum_level, @default_capacity, 1)
  end
end
