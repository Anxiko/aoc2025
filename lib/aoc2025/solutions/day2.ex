defmodule Aoc2025.Solutions.Day2 do
  alias Aoc2025.Types

  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, part, _mode) do
    ranges = parse_input(input)

    ranges
    |> Stream.flat_map(&Enum.to_list/1)
    |> Stream.filter(&invalid_id?(&1, part))
    |> Enum.sum()
  end

  @spec parse_input(Types.input()) :: [Range.t()]
  defp parse_input([input]) do
    input
    |> String.split(",")
    |> Enum.map(fn raw_range ->
      [start, end_] = raw_range |> String.split("-") |> Enum.map(&String.to_integer/1)
      start..end_
    end)
  end

  @spec invalid_id?(integer(), Types.part()) :: boolean()
  defp invalid_id?(id, part) do
    id = id |> Integer.to_string() |> String.graphemes()

    chunk_sizes(length(id), part)
    |> Enum.any?(fn chunk_size ->
      id
      |> Enum.chunk_every(chunk_size)
      |> equal_chunks?()
    end)
  end

  @spec chunk_sizes(non_neg_integer(), Types.part()) :: [non_neg_integer()]
  defp chunk_sizes(length, _part) when length < 2, do: []

  defp chunk_sizes(length, part) do
    part
    |> case do
      :part1 -> [div(length, 2)]
      :part2 -> 1..div(length, 2)
    end
    |> Enum.filter(&(rem(length, &1) == 0))
  end

  defp equal_chunks?([chunk | [_ | _] = rest]) do
    Enum.all?(rest, &(&1 == chunk))
  end

  defp equal_chunks?(chunks) when is_list(chunks), do: false
end
