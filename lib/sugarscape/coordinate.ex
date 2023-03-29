defmodule Sugarscape.Coordinate do
  @moduledoc """
  An (x,y)-coordinate for a 2-dimensional grid
  """

  @typedoc """
  Represents an (x,y)-coordinate for a 2-dimensional grid. The coordinate ranges
  run from 1 to the width or height of the grid.
  """
  @type t :: {pos_integer, pos_integer}

  @doc """
  Calculates the distance between two coordinates
  """
  @spec distance(__MODULE__.t(), __MODULE__.t()) :: number
  def distance({x1, y1}, {x2, y2}) do
    (:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
    |> :math.sqrt()
  end

  @doc """
  Shift the coordinate, given the grid's size, by the amount specified, wrapping around if
  needed.
  """
  @spec shift({pos_integer, pos_integer}, __MODULE__.t(), :x | :y, non_neg_integer) ::
          __MODULE__.t()
  def shift({x, y}, {width, _height}, :x, amount) do
    # Change from 1-indexed to 0-indexed before modulo and then change
    # back to 1-indexed.
    {wraparound(x - 1 + amount, width) + 1, y}
  end

  def shift({x, y}, {_width, height}, :y, amount) do
    # Change from 1-indexed to 0-indexed before modulo and then change
    # back to 1-indexed.
    {x, wraparound(y - 1 + amount, height) + 1}
  end

  @doc """
  Given a grid's width, converts an (x,y)-coordinate, where each
  coordinate is 1-based, to a 0-based list index
  """
  @spec convert_to_index(__MODULE__.t(), pos_integer) :: non_neg_integer
  def convert_to_index({x, y} = _coordinate, width) do
    x - 1 + (y - 1) * width
  end

  # Wrap around a value to always be between 1 and `mod`.
  #
  # Examples:
  #   iex> wraparound(-1, 50)
  #   49
  #
  #   iex> wraparound(52, 50)
  #   2
  @spec wraparound(pos_integer, pos_integer) :: pos_integer
  defp wraparound(value, mod) do
    result = rem(value, mod)

    if result >= 0 do
      result
    else
      mod + result
    end
  end
end
