defmodule Sugarscape.Grid do
  @moduledoc """
  Implements a 2D grid
  """

  @enforce_keys [:size, :data]
  defstruct @enforce_keys

  @opaque t(term) :: %__MODULE__{
            size: {width :: pos_integer, height :: pos_integer},
            data: [[term]]
          }

  @type flattened_map(term) :: %{
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
          initializer.(x, y)
        end
      end

    %__MODULE__{size: {width, height}, data: data}
  end

  @spec flatten_to_map_list(__MODULE__.t(data), (data -> new_data)) ::
          [%{x: pos_integer, y: pos_integer, data: new_data}]
        when data: any, new_data: any
  def flatten_to_map_list(grid, data_mapper \\ &Function.identity/1) do
    grid.data
    |> Enum.with_index(fn rows, y ->
      Enum.with_index(
        rows,
        fn element, x ->
          %{
            x: x + 1,
            y: y + 1,
            data: data_mapper.(element)
          }
        end
      )
    end)
    |> List.flatten()
  end
end
