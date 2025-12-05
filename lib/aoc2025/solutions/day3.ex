defmodule Aoc2025.Solutions.Day3 do
  @behaviour Aoc2025.DaySolver

  @type bank() :: [integer()]

  @impl true
  def solve(input, part, _mode) do
    banks = Enum.map(input, &parse_bank/1)

    target_digits =
      case part do
        :part1 ->
          2

        :part2 ->
          12
      end

    banks
    |> Enum.map(&find_biggest_battery(&1, target_digits))
    |> Enum.map(&Integer.undigits/1)
    |> Enum.sum()
  end

  @spec parse_bank(String.t()) :: bank()
  defp parse_bank(raw_bank) do
    raw_bank
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
  end

  def find_biggest_battery(bank, target_digits) do
    bank
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.reverse()
    |> Enum.reduce([], fn {new_digit, remaining}, acc ->
      update_digits(acc, new_digit, target_digits, remaining)
    end)
  end

  @spec update_digits(
          current_digits :: bank(),
          new_digit :: integer(),
          target_digits :: non_neg_integer(),
          remaining :: non_neg_integer()
        ) :: bank()
  defp update_digits(current_digits, new_digit, target_digits, remaining),
    do: update_digits(current_digits, new_digit, target_digits, remaining, [])

  defp update_digits([], _new_digit, 0, _remaining, acc), do: Enum.reverse(acc)

  defp update_digits([], new_digit, target_digits, remaining, acc)
       when remaining >= target_digits and target_digits > 0 do
    Enum.reverse([new_digit | acc])
  end

  defp update_digits([h | _t], new_digit, target_digits, remaining, acc)
       when remaining >= target_digits and target_digits > 0 and new_digit > h do
    Enum.reverse([new_digit | acc])
  end

  defp update_digits([h | t], new_digit, target_digits, remaining, acc)
       when target_digits > 0 do
    update_digits(t, new_digit, target_digits - 1, remaining, [h | acc])
  end
end
