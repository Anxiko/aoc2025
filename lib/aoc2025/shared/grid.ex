defmodule Aoc2025.Shared.Grid do
  alias Aoc2025.Shared.Coord

  defstruct mapping: %{}

  @type t(cell) :: %__MODULE__{
          mapping: %{Coord.t() => cell}
        }

  @type t() :: t(any())

  @spec new(pairs :: Enumerable.t({Coord.t(), cell})) :: t(cell) when cell: any()
  @spec new() :: t()
  def new(pairs \\ %{}) do
    %__MODULE__{
      mapping: Map.new(pairs)
    }
  end

  @spec read(t(cell), Coord.t(), default) :: cell | default when cell: any(), default: any()
  @spec read(t(cell), Coord.t()) :: cell | nil when cell: any()
  def read(%__MODULE__{} = grid, coord, default \\ nil) do
    Map.get(grid.mapping, coord, default)
  end

  @spec write(t(cell), Coord.t(), cell) :: t(cell) when cell: any()
  def write(%__MODULE__{} = grid, coord, cell) do
    %{grid | mapping: Map.put(grid.mapping, coord, cell)}
  end

  @spec from_rows([[cell]]) :: t(cell) when cell: any()
  def from_rows(rows) do
    for {row, y} <- Enum.with_index(rows), {cell, x} <- Enum.with_index(row) do
      {Coord.new(x, y), cell}
    end
    |> new()
  end

  @spec bounding_box(t()) :: {Coord.t(), Coord.t()}
  def bounding_box(%__MODULE__{} = grid) do
    {x_min, x_max} = pairs(grid) |> Enum.map(fn {coord, _cell} -> coord.x end) |> Enum.min_max()
    {y_min, y_max} = pairs(grid) |> Enum.map(fn {coord, _cell} -> coord.y end) |> Enum.min_max()

    {Coord.new(x_min, y_min), Coord.new(x_max, y_max)}
  end

  @spec to_rows(t(cell), default) :: [[cell | default]] when cell: any(), default: any()
  @spec to_rows(t(cell)) :: [[cell | nil]] when cell: any()
  def to_rows(%__MODULE__{} = grid, empty \\ nil) do
    {%Coord{x: x_min, y: y_min}, %Coord{x: x_max, y: y_max}} = bounding_box(grid)

    for y <- y_min..y_max do
      for x <- x_min..x_max do
        read(grid, Coord.new(x, y), empty)
      end
    end
  end

  @spec pairs(t(cell)) :: [{Coord.t(), cell}] when cell: any()
  def pairs(%__MODULE__{} = grid), do: grid.mapping

  @spec map(t(old_cell), (old_cell -> new_cell)) :: t(new_cell)
        when old_cell: any(), new_cell: any()
  def map(%__MODULE__{} = grid, mapper) do
    mapping = Map.new(grid.mapping, fn {k, v} -> {k, mapper.(v)} end)
    %{grid | mapping: mapping}
  end

  @spec find(t(cell), cell) :: {:ok, Coord.t()} | :not_found when cell: any()
  def find(%__MODULE__{} = grid, cell) do
    grid.mapping
    |> Enum.find(:not_found, fn {_k, v} -> v == cell end)
    |> case do
      :not_found -> :not_found
      {k, _v} -> {:ok, k}
    end
  end
end
