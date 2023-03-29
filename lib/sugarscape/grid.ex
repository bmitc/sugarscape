defmodule Sugarscape.Grid do
  @moduledoc """
  Implements a 2-dimensional grid that wraps around the tops and bottoms. Because of
  this wraparound behavior, the grid has the same topology as a torus.
  """

  alias Sugarscape.Coordinate

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

  @type size :: {pos_integer, pos_integer}

  @doc """
  Creates a new grid using the given `initializer` function, which gets passed all of the
  (x,y)-coordinates to initialize each coordinate value for a grid of the given width and height.
  The (x,y)-coordinates always start at 1.
  """
  @spec new(pos_integer, pos_integer, (Coordinate.t() -> data)) :: __MODULE__.t(data)
        when data: any
  def new(width, height, initializer) do
    data =
      for y <- 1..height do
        for x <- 1..width do
          %{x: x, y: y, data: initializer.({x, y})}
        end
      end
      |> List.flatten()

    %__MODULE__{size: {width, height}, data: data}
  end

  @doc """
  Gets the size of the grid
  """
  @spec size(__MODULE__.t(any)) :: size
  def size(%__MODULE__{} = grid), do: grid.size

  @doc """
  Gets the width of the grid
  """
  @spec width(__MODULE__.t(any)) :: pos_integer
  def width(%__MODULE__{} = grid), do: grid.size |> elem(0)

  @doc """
  Gets the height of the grid
  """
  @spec height(__MODULE__.t(any)) :: pos_integer
  def height(%__MODULE__{} = grid), do: grid.size |> elem(1)

  @spec map_data(__MODULE__.t(data), (data -> data)) :: __MODULE__.t(data) when data: any
  def map_data(%__MODULE__{} = grid, fun) do
    new_data =
      grid.data
      |> Enum.map(fn %{data: data} = element -> %{element | data: fun.(data)} end)

    %__MODULE__{grid | data: new_data}
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
  def map(%__MODULE__{} = grid, mapper) do
    Enum.map(grid.data, fn %{x: x, y: y, data: data} = _element ->
      Map.merge(
        %{x: x, y: y},
        mapper.(x, y, data)
      )
    end)
  end

  @doc """
  Indexes a grid by getting the grid's value at the given coordinate location
  """
  @spec index(__MODULE__.t(data), Coordinate.t()) :: data when data: any
  def index(%__MODULE__{} = grid, coordinate) do
    grid.data
    |> Enum.at(Coordinate.convert_to_index(coordinate, width(grid)))
    |> Map.fetch!(:data)
  end

  @doc """
  Updates the grid's data element at the given coordinate
  """
  @spec update_at(__MODULE__.t(data), Coordinate.t(), (data -> data)) :: __MODULE__.t(data)
        when data: any
  def update_at(%__MODULE__{} = grid, coordinate, fun) do
    {width, _height} = grid.size
    index = Coordinate.convert_to_index(coordinate, width)

    %__MODULE__{
      grid
      | data:
          List.update_at(grid.data, index, fn element ->
            Map.update!(element, :data, &fun.(&1))
          end)
    }
  end
end
