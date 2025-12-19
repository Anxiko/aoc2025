defmodule Aoc2025.Solutions.Day12 do
  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, _part, _mode) do
    areas = parse_input(input)

    Enum.count(areas, fn {width, height, shape_counts} ->
      solvable?(width, height, shape_counts)
    end)
  end

  def parse_input(input) do
    input
    |> Enum.reverse()
    |> Enum.take_while(fn s -> s != "" end)
    |> Enum.reverse()
    |> Enum.map(&parse_area/1)
  end

  defp parse_area(area) do
    [dimensions, shape_counts] = String.split(area, ":")

    [width, height] = dimensions |> String.split("x") |> Enum.map(&String.to_integer/1)

    shape_counts =
      shape_counts |> String.trim() |> String.split() |> Enum.map(&String.to_integer/1)

    {width, height, shape_counts}
  end

  defp solvable?(width, height, shape_counts) do
    total = Enum.sum(shape_counts)

    div(width, 3) * div(height, 3) >= total
  end
end
