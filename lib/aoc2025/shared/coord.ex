defmodule Aoc2025.Shared.Coord do
  defstruct x: 0, y: 0

  @neighbour_opts [cross: true, diagonal: true, center: false]

  @type t() :: %__MODULE__{
          x: integer(),
          y: integer()
        }

  @spec new(x :: integer(), y :: integer()) :: t()
  def new(x, y) do
    %__MODULE__{x: x, y: y}
  end

  @spec add(t(), t()) :: t()
  def add(%__MODULE__{} = left, %__MODULE__{} = right) do
    %__MODULE__{x: left.x + right.x, y: left.y + right.y}
  end

  @spec sub(t(), t()) :: t()
  def sub(%__MODULE__{} = left, %__MODULE__{} = right) do
    %__MODULE__{x: left.x - right.x, y: left.y - right.y}
  end

  @spec neighbours(t(), Keyword.t()) :: [t()]
  @spec neighbours(t()) :: [t()]
  def neighbours(%__MODULE__{} = coord, opts \\ []) do
    opts = Keyword.validate!(opts, @neighbour_opts)

    [
      {Keyword.fetch!(opts, :cross), cross(coord)},
      {Keyword.fetch!(opts, :diagonal), diagonal(coord)},
      {Keyword.fetch!(opts, :center), [coord]}
    ]
    |> Enum.flat_map(fn
      {condition?, values} -> if condition?, do: values, else: []
    end)
  end

  @spec x(t()) :: integer()
  def x(%__MODULE__{} = coord), do: coord.x

  @spec y(t()) :: integer()
  def y(%__MODULE__{} = coord), do: coord.y

  defp cross(%__MODULE__{} = coord) do
    Enum.map(
      [
        %__MODULE__{x: 1, y: 0},
        %__MODULE__{x: -1, y: 0},
        %__MODULE__{x: 0, y: 1},
        %__MODULE__{x: 0, y: -1}
      ],
      &add(coord, &1)
    )
  end

  defp diagonal(%__MODULE__{} = coord) do
    Enum.map(
      [
        %__MODULE__{x: 1, y: 1},
        %__MODULE__{x: 1, y: -1},
        %__MODULE__{x: -1, y: 1},
        %__MODULE__{x: -1, y: -1}
      ],
      &add(coord, &1)
    )
  end
end
