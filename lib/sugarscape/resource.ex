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
          level: non_neg_integer(),
          capacity: non_neg_integer(),
          growback_rate: non_neg_integer() | :immediate
        }

  @doc """
  Creates a new resource with the given level, capacity, and growback rate
  """
  @spec new(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          __MODULE__.t()
  def new(level, capacity, growback_rate) do
    %__MODULE__{
      level: level,
      capacity: capacity,
      growback_rate: growback_rate
    }
  end

  @doc """
  Creates a new resource with a default level of 4, a default capacity of 4,
  and a default growback rate of 1
  """
  @spec new() :: __MODULE__.t()
  def new() do
    new(@default_maximum_level, @default_capacity, 1)
  end

  @doc """
  Creates a new resource with the given level, a default capacity of the level,
  and a default growback rate of 1
  """
  @spec new(non_neg_integer()) :: __MODULE__.t()
  def new(level) do
    new(level, level, 1)
  end

  @doc """
  Creates a new resource with a random level between 0 and 4, a default capacity of 4,
  and a default growback rate of 1
  """
  @spec new_random() :: __MODULE__.t()
  def new_random() do
    level = Enum.random(0..@default_maximum_level)
    new(level, @default_capacity, 1)
  end

  @doc """
  Calculate the resource's new level after a new timestep
  """
  @spec calculate_new_level(__MODULE__.t()) :: __MODULE__.t()
  def calculate_new_level(%__MODULE__{growback_rate: :immediate} = resource) do
    # This works due to term ordering
    # See https://hexdocs.pm/elixir/1.14.3/operators.html#term-ordering
    %__MODULE__{resource | level: min(:infinity, resource.capacity)}
  end

  def calculate_new_level(%__MODULE__{} = resource) do
    %__MODULE__{resource | level: min(resource.level + resource.growback_rate, resource.capacity)}
  end

  @spec has_level?(__MODULE__.t(), non_neg_integer) :: boolean
  def has_level?(resource, level) do
    if level != 0 do
      case resource do
        nil -> false
        %__MODULE__{} -> resource.level == level
      end
    else
      case resource do
        nil -> true
        %__MODULE__{} -> resource.level == 0
      end
    end
  end
end
