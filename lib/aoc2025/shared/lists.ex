defmodule Aoc2025.Shared.Lists do
  @spec pairs([element]) :: [{element, element}] when element: any()
  def pairs(list) do
    for {left, idx} <- Enum.with_index(list), right <- Enum.drop(list, idx + 1) do
      {left, right}
    end
  end

  @spec combinations([element], non_neg_integer()) :: [[element]] when element: any()
  def combinations(_elements, 0), do: [[]]
  def combinations([], _count), do: []

  def combinations([h | t], count) when count > 0 do
    with_h = for comb <- combinations(t, count - 1), do: [h | comb]
    without_h = combinations(t, count)

    with_h ++ without_h
  end
end
