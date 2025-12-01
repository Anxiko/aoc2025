defmodule Aoc2025.Solutions do
  alias Aoc2025.DaySolver
  alias Aoc2025.Solutions.Day1

  @day_mapping %{
    1 => Day1
  }

  @spec get_solver(non_neg_integer()) :: DaySolver.t()
  def get_solver(day_number) when is_integer(day_number) and day_number > 0 do
    Map.fetch!(@day_mapping, day_number)
  end
end
