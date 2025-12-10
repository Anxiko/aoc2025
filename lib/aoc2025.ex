defmodule Aoc2025 do
  alias Aoc2025.Solutions
  alias Aoc2025.Types

  @spec solve(Types.day(), Types.part(), Types.mode()) :: any()
  @spec solve(Types.day(), Types.part()) :: any()
  def solve(day, part, mode \\ :real) do
    solver = Solutions.get_solver(day)
    input = load_input(day, mode)
    solver.solve(input, part, mode)
  end

  @spec load_input(Types.day(), Types.mode()) :: Types.input()
  def load_input(day, mode) do
    "inputs/day#{day}/#{mode}.txt"
    |> File.read!()
    |> String.trim_trailing("\n")
    |> String.split("\n")
  end
end
