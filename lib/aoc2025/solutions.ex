defmodule Aoc2025.Solutions do
  alias Aoc2025.DaySolver
  alias Aoc2025.Solutions.Day1
  alias Aoc2025.Solutions.Day2
  alias Aoc2025.Solutions.Day3
  alias Aoc2025.Solutions.Day4
  alias Aoc2025.Solutions.Day5
  alias Aoc2025.Solutions.Day6
  alias Aoc2025.Solutions.Day7
  alias Aoc2025.Solutions.Day8
  alias Aoc2025.Solutions.Day9

  @day_mapping %{
    1 => Day1,
    2 => Day2,
    3 => Day3,
    4 => Day4,
    5 => Day5,
    6 => Day6,
    7 => Day7,
    8 => Day8,
    9 => Day9
  }

  @spec get_solver(non_neg_integer()) :: DaySolver.t()
  def get_solver(day_number) when is_integer(day_number) and day_number > 0 do
    Map.fetch!(@day_mapping, day_number)
  end
end
