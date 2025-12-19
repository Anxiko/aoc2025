defmodule Aoc2025.Solutions.Day11 do
  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, part, _mode) do
    mappings = Map.new(input, &parse_connection/1)

    case part do
      :part1 ->
        path_counting(mappings, "you", "out")

      :part2 ->
        stepped_path_counting(mappings, ["svr", "dac", "fft", "out"]) +
          stepped_path_counting(mappings, ["svr", "fft", "dac", "out"])
    end
  end

  defp parse_connection(connection) do
    [source, destinations] = String.split(connection, ":")

    destinations =
      destinations
      |> String.trim()
      |> String.split()

    {source, destinations}
  end

  def topological_order(mappings, start) do
    {order, _visited} = topological_order(mappings, start, MapSet.new(), [])

    order
  end

  defp topological_order(mappings, node, visited, acc) do
    if MapSet.member?(visited, node) do
      {acc, visited}
    else
      visited = MapSet.put(visited, node)

      {acc, visited} =
        mappings
        |> Map.get(node, [])
        |> Enum.reduce({acc, visited}, fn neighbour, {acc, visited} ->
          topological_order(mappings, neighbour, visited, acc)
        end)

      {[node | acc], visited}
    end
  end

  def path_counting(mappings, source, destination) do
    order = topological_order(mappings, source)

    paths = %{source => 1}

    order
    |> Enum.reduce(paths, fn u, paths ->
      mappings
      |> Map.get(u, [])
      |> Enum.reduce(paths, fn v, paths ->
        new_paths = Map.get(paths, u, 0)
        Map.update(paths, v, new_paths, &(&1 + new_paths))
      end)
    end)
    |> Map.get(destination, 0)
  end

  def stepped_path_counting(mappings, [source, destination | rest]) do
    filtered_mappings = Map.new(mappings, fn {k, v} -> {k, v -- rest} end)

    paths = path_counting(filtered_mappings, source, destination)
    paths * stepped_path_counting(mappings, [destination | rest])
  end

  def stepped_path_counting(_mappings, [_destination]), do: 1
end
