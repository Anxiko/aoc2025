defmodule Aoc2025.Shared.Coord3D do
  defstruct x: 0, y: 0, z: 0

  @type t() :: %__MODULE__{
          x: integer(),
          y: integer(),
          z: integer()
        }

  @spec new(integer(), integer(), integer()) :: t()
  def new(x, y, z) do
    %__MODULE__{
      x: x,
      y: y,
      z: z
    }
  end

  @spec add(t(), t()) :: t()
  def add(%__MODULE__{} = lhs, %__MODULE__{} = rhs) do
    new(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
  end

  @spec sub(t(), t()) :: t()
  def sub(%__MODULE__{} = lhs, %__MODULE__{} = rhs) do
    new(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
  end

  @spec mod(t()) :: float()
  def mod(%__MODULE__{} = coord3D) do
    [coord3D.x, coord3D.y, coord3D.z]
    |> Enum.map(&Integer.pow(&1, 2))
    |> Enum.sum()
    |> :math.sqrt()
  end
end

defimpl Inspect, for: Aoc2025.Shared.Coord3D do
  import Inspect.Algebra

  def inspect(%@for{} = coord, opts) do
    concat([
      "(",
      to_doc(coord.x, opts),
      ", ",
      to_doc(coord.y, opts),
      ", ",
      to_doc(coord.z, opts),
      ")"
    ])
  end
end

defimpl String.Chars, for: Aoc2025.Shared.Coord3D do
  def to_string(%@for{} = coord), do: inspect(coord)
end
