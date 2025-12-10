defmodule Aoc2025.Shared.Ranges do
  @spec auto(limit, limit) :: Range.t(limit, limit) when limit: any()
  def auto(left, right) when left <= right do
    left..right//1
  end

  def auto(left, right) do
    left..right//-1
  end

  @spec exclusive(Range.t()) :: Range.t() | nil
  def exclusive(left..right//1) when right - left >= 2 do
    (left + 1)..(right - 1)//1
  end

  def exclusive(left..right//-1) when left - right >= 2 do
    (left - 1)..(right + 1)//-1
  end

  def exclusive(_left.._right//step) when step in [1, -1], do: nil

  @spec check_point_in(Range.t(limit, limit), limit) :: :outside | {:inside, :start | :end | nil}
        when limit: any()
  def check_point_in(range_start..range_end//_step = range, point) do
    cond do
      point not in range -> :outside
      point == range_start -> {:inside, :start}
      point == range_end -> {:inside, :end}
      true -> {:inside, nil}
    end
  end

  @spec increasing(Range.t()) :: Range.t()
  def increasing(left..right//step) when step < 0, do: right..left//-step
  def increasing(%Range{} = range), do: range

  @spec intersection(Range.t(), Range.t()) :: Range.t() | nil
  def intersection(a_start..a_end//1 = a, b_start..b_end//1 = b)
      when a_start <= a_end and b_start <= b_end do
    if Range.disjoint?(a, b) do
      nil
    else
      start = max(a_start, b_start)
      end_ = min(a_end, b_end)

      start..end_//1
    end
  end
end
