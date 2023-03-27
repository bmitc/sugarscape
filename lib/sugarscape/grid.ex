defmodule Sugarscape.Grid do
  @moduledoc """
  Implements a 2D grid
  """

  @enforce_keys [:size, :data]
  defstruct @enforce_keys

  @opaque t(term) :: %__MODULE__{
            size: {width :: pos_integer, height :: pos_integer},
            data: [element(term)]
          }

  @type element(term) :: %{
          x: pos_integer,
          y: pos_integer,
          data: term
        }

  @doc """
  Creates a new grid using the given `initializer` function, which gets passed all of the
  (x,y)-coordinates to initialize each coordinate value for a grid of the given width and height.
  The (x,y)-coordinates always start at 1.
  """
  @spec new(pos_integer, pos_integer, (pos_integer, pos_integer -> data)) :: __MODULE__.t(data)
        when data: any
  def new(width, height, initializer) do
    data =
      for y <- 1..height do
        for x <- 1..width do
          %{x: x, y: y, data: initializer.(x, y)}
        end
      end
      |> List.flatten()

    %__MODULE__{size: {width, height}, data: data}
  end

  @doc """
  Maps over a grid's data and returns a list of a map `%{x: x-coord, y: y-coord}` merged
  with the map that the `mapper` function returns. This is useful to convert a grid's
  data into a new format to be used in some other context, such as plotting the grid.
  """
  @spec map(
          __MODULE__.t(data),
          (x :: pos_integer, y :: pos_integer, data -> map)
        ) :: [%{:x => pos_integer, :y => pos_integer, optional(any) => any}]
        when data: any
  def map(grid, mapper) do
    Enum.map(grid.data, fn %{x: x, y: y, data: data} = _element ->
      Map.merge(
        %{x: x, y: y},
        mapper.(x, y, data)
      )
    end)
  end
end
