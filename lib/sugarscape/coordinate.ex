defmodule Sugarscape.Coordinate do
  @moduledoc """
  A 2D coordinate
  """

  @type t :: {pos_integer, pos_integer}

  @doc """
  Calculates the distance between two coordinates
  """
  @spec distance(Types.coordinate(), Types.coordinate()) :: number
  def distance({x1, y1}, {x2, y2}) do
    (:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
    |> :math.sqrt()
  end
end
