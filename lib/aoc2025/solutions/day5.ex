defmodule Aoc2025.Solutions.Day5 do
  alias Aoc2025.Types

  @behaviour Aoc2025.DaySolver

  @enforce_keys [:fresh_ranges, :ingredients]
  defstruct [:fresh_ranges, :ingredients]

  @type ingredient() :: integer()
  @type fresh_range() :: Range.t(ingredient(), ingredient())

  @type t() :: %__MODULE__{
          fresh_ranges: [fresh_range()],
          ingredients: [ingredient()]
        }

  def solve(input, part, _mode) do
    database = parse(input)

    case part do
      :part1 ->
        database
        |> fresh_ingredients()
        |> Enum.count()

      :part2 ->
        database
        |> reduce_fresh_ranges()
        |> Enum.sum_by(&Range.size/1)
    end
  end

  @spec fresh_ingredients(t()) :: [ingredient()]
  def fresh_ingredients(%__MODULE__{} = database) do
    Enum.filter(database.ingredients, &fresh?(database, &1))
  end

  @spec reduce_fresh_ranges(t()) :: [fresh_range()]
  def reduce_fresh_ranges(%__MODULE__{} = database) do
    database.fresh_ranges
    |> Enum.reduce([], &add_range(&2, &1))
  end

  @spec parse(Types.input()) :: t()
  defp parse(input) do
    sep_idx = input |> Enum.find_index(&(&1 == ""))

    {ranges, ["" | ingredients]} = Enum.split(input, sep_idx)

    %__MODULE__{
      fresh_ranges: Enum.map(ranges, &parse_range/1),
      ingredients: Enum.map(ingredients, &String.to_integer/1)
    }
  end

  defp parse_range(raw_range) do
    [left, right] = raw_range |> String.split("-") |> Enum.map(&String.to_integer/1)
    left..right
  end

  defp fresh?(%__MODULE__{} = database, ingredient) do
    Enum.any?(database.fresh_ranges, fn interval -> ingredient in interval end)
  end

  defp add_range(ranges, new_range), do: do_add_range(ranges, new_range, [])

  defp do_add_range([], new_range, acc), do: [new_range | acc]

  defp do_add_range([h | t], new_range, acc) do
    if Range.disjoint?(h, new_range) do
      do_add_range(t, new_range, [h | acc])
    else
      do_add_range(t, range_union(h, new_range), acc)
    end
  end

  defp range_union(left_min..left_max//left_step, right_min..right_max//right_step)
       when left_step == right_step do
    min(left_min, right_min)..max(left_max, right_max)//left_step
  end
end
