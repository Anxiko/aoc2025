defmodule Aoc2025.DaySolver do
  alias Aoc2025.Types

  @type t() :: module()

  @callback solve(input :: Types.input(), part :: Types.part(), mode :: Types.mode()) :: any()
end
