defmodule Aoc2025.Solutions.Day4 do
  alias Aoc2025.Shared.Coord
  alias Aoc2025.Shared.Grid

  @behaviour Aoc2025.DaySolver

  @paper_roll "@"
  @empty "."
  @accessible_limit 4

  @impl true
  def solve(input, part, _mode) do
    grid = input |> Enum.map(&String.graphemes/1) |> Grid.from_rows()

    case part do
      :part1 ->
        grid
        |> removable()
        |> Enum.count()

      :part2 ->
        grid
        |> remove_all()
        |> Enum.count()
    end
  end

  @spec removable(Grid.t()) :: [Coord.t()]
  def removable(grid) do
    grid
    |> Grid.pairs()
    |> Enum.filter(fn {_coord, cell} -> cell == @paper_roll end)
    |> Enum.filter(fn {coord, _cell} -> accessible?(grid, coord) end)
    |> Enum.map(fn {coord, _cell} -> coord end)
  end

  @spec remove_all(Grid.t()) :: [Coord.t()]
  def remove_all(grid) do
    do_remove_all(grid, [])
  end

  defp do_remove_all(grid, acc) do
    case removable(grid) do
      [] ->
        acc

      removable_coords ->
        grid = Enum.reduce(removable_coords, grid, &Grid.write(&2, &1, @empty))
        do_remove_all(grid, removable_coords ++ acc)
    end
  end

  defp accessible?(grid, coord) do
    coord
    |> Coord.neighbours()
    |> Enum.map(&Grid.read(grid, &1))
    |> Enum.filter(&(&1 == @paper_roll))
    |> Enum.count()
    |> then(&(&1 < @accessible_limit))
  end
end
