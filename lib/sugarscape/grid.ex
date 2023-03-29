defmodule Sugarscape.Grid do
  @moduledoc """
  Implements a 2D grid
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

  @spec map_data(__MODULE__.t(data), (data -> data)) :: __MODULE__.t(data) when data: any
  def map_data(grid, fun) do
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
  def map(grid, mapper) do
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
  def index(grid, {x0, y0}) do
    grid.data
    |> Enum.find(fn %{x: x, y: y} -> x == x0 and y == y0 end)
    |> Map.fetch!(:data)
  end

  @doc """
  Updates the grid's data element at the given coordinate
  """
  @spec update_at(__MODULE__.t(data), Coordinate.t(), (data -> data)) :: __MODULE__.t(data)
        when data: any
  def update_at(grid, {x, y}, fun) do
    {width, _height} = grid.size
    index = convert_2d_index_to_1d_index(x - 1, y - 1, width)

    %__MODULE__{
      grid
      | data:
          List.update_at(grid.data, index, fn element ->
            Map.update!(element, :data, &fun.(&1))
          end)
    }
  end

  # Given a 2D array's width (number of columns), converts a 1D array index to a 2D array (x,y) index
  # defp convert_1d_index_to_2d_index(index, width) do
  #   {rem(index, width), div(index, width)}
  # end

  # Given a 2D array's width (number of columns), converts a 2D array (x,y) index to a 1D array index
  defp convert_2d_index_to_1d_index(x, y, width) do
    x + y * width
  end
end
