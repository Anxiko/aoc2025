defmodule Aoc2025.Solutions.Day1 do
  @default_value 50
  @max_value 100

  @enforce_keys [:value, :max_value, :perfect_zeros, :crossed_zeroes]
  defstruct [:value, :max_value, :perfect_zeros, :crossed_zeroes]

  @type t() :: %__MODULE__{
          value: integer(),
          max_value: integer(),
          perfect_zeros: non_neg_integer(),
          crossed_zeroes: non_neg_integer()
        }

  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, part, _mode) do
    moves = Enum.map(input, &parse_move/1)

    final_state =
      Enum.reduce(moves, new(), fn move, state ->
        move(state, move)
      end)

    case part do
      :part1 -> final_state.perfect_zeros
      :part2 -> final_state.crossed_zeroes
    end
  end

  @spec new() :: t()
  def new do
    mod(%__MODULE__{
      value: @default_value,
      max_value: @max_value,
      perfect_zeros: 0,
      crossed_zeroes: 0
    })
  end

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{value: value} = state, delta) when is_integer(delta) do
    %{state | value: value + delta}
    |> update_crossed_zeroes(value)
    |> mod()
    |> update_perfect_zeros()
  end

  @spec parse_move(String.t()) :: integer()
  def parse_move("L" <> rest) do
    -String.to_integer(rest)
  end

  def parse_move("R" <> rest) do
    String.to_integer(rest)
  end

  @spec mod(t()) :: t()
  defp mod(%__MODULE__{value: value, max_value: max_value} = state) do
    %{state | value: Integer.mod(value, max_value)}
  end

  @spec update_perfect_zeros(t()) :: t()
  defp update_perfect_zeros(%__MODULE__{value: 0, perfect_zeros: pz} = state) do
    %{state | perfect_zeros: pz + 1}
  end

  defp update_perfect_zeros(%__MODULE__{} = state), do: state

  @spec update_crossed_zeroes(t(), integer()) :: t()
  defp update_crossed_zeroes(
         %__MODULE__{value: value, max_value: max_value, crossed_zeroes: crossed_zeroes} = state,
         previous_value
       ) do
    new_crossed_zeroes =
      case {previous_value, value} do
        {0, 0} -> raise RuntimeError, "Unexpected case: both previous and current values are zero"
        {0, current} -> current |> div(max_value) |> abs()
        {_prev, current} when current > 0 -> current |> div(max_value) |> abs()
        {_prev, current} when current < 0 -> (current |> div(max_value) |> abs()) + 1
        {_prev, 0} -> 1
      end

    %{state | crossed_zeroes: crossed_zeroes + new_crossed_zeroes}
  end
end
