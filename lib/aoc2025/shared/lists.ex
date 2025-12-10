defmodule Aoc2025.Shared.Lists do
  @spec pairs([element]) :: [{element, element}] when element: any()
  def pairs(list) do
    for {left, idx} <- Enum.with_index(list), right <- Enum.drop(list, idx + 1) do
      {left, right}
    end
  end
end
