defmodule Aoc2025.Solutions.Day9.Wall do
  alias Aoc2025.Shared.Coord
  alias Aoc2025.Shared.Ranges

  @enforce_keys [:orientation, :pinned_coord, :range_coord]
  defstruct @enforce_keys

  @type orientation() :: :vertical | :horizontal
  @type direction() :: :negative | :positive

  @type t() :: %__MODULE__{
          orientation: orientation(),
          pinned_coord: integer(),
          range_coord: Range.t()
        }

  @spec new(orientation(), integer(), Range.t()) :: t()
  def new(orientation, pinned_coord, range_coord) do
    %__MODULE__{
      orientation: orientation,
      pinned_coord: pinned_coord,
      range_coord: range_coord
    }
  end

  @spec from_pair(Coord.t(), Coord.t()) :: t()
  def from_pair(%Coord{x: x} = left, %Coord{x: x} = right) when left.y != right.y do
    new(:vertical, x, Ranges.auto(left.y, right.y))
  end

  @spec from_pair(Coord.t(), Coord.t()) :: t()
  def from_pair(%Coord{y: y} = left, %Coord{y: y} = right) when left.x != right.x do
    new(:horizontal, y, Ranges.auto(left.x, right.x))
  end

  @spec from_circuit([Coord.t()]) :: [t()]
  def from_circuit([h | [_ | _] = t] = coords) do
    coords
    |> Enum.zip(t ++ [h])
    |> Enum.map(fn {left, right} -> from_pair(left, right) end)
  end

  @spec reverse(t()) :: t()
  def reverse(%__MODULE__{} = wall) do
    %{wall | range_coord: reverse_range(wall.range_coord)}
  end

  @spec reverse_circuit([t()]) :: [t()]
  def reverse_circuit(walls) do
    walls
    |> Enum.reverse()
    |> Enum.map(&reverse/1)
  end

  @spec turning_counterclockwise(Aoc2025.Solutions.Day9.Wall.t()) ::
          {orientation(), direction()}
  def turning_counterclockwise(%__MODULE__{
        orientation: :vertical,
        range_coord: _left.._right//step
      })
      when step > 0, do: {:horizontal, :positive}

  def turning_counterclockwise(%__MODULE__{
        orientation: :vertical,
        range_coord: _left.._right//step
      })
      when step < 0, do: {:horizontal, :negative}

  def turning_counterclockwise(%__MODULE__{
        orientation: :horizontal,
        range_coord: _left.._right//step
      })
      when step > 0, do: {:vertical, :negative}

  def turning_counterclockwise(%__MODULE__{
        orientation: :horizontal,
        range_coord: _left.._right//step
      })
      when step < 0, do: {:vertical, :positive}

  @spec contains?(t(), Coord.t()) :: boolean()
  def contains?(%__MODULE__{} = wall, %Coord{} = coord) do
    {pinned, in_range} =
      case wall.orientation do
        :horizontal -> {coord.y, coord.x}
        :vertical -> {coord.x, coord.y}
      end

    wall.pinned_coord == pinned and in_range in wall.range_coord
  end

  def crosses?(
        %__MODULE__{orientation: :vertical} = vertical,
        %__MODULE__{orientation: :horizontal} = horizontal
      ) do
    crosses?(horizontal, vertical)
  end

  def crosses?(
        %__MODULE__{orientation: :horizontal} = horizontal,
        %__MODULE__{orientation: :vertical} = vertical
      ) do
    case {Ranges.check_point_in(horizontal.range_coord, vertical.pinned_coord),
          Ranges.check_point_in(vertical.range_coord, horizontal.pinned_coord)} do
      {{:inside, _}, {:inside, _}} ->
        true

      _ ->
        false
    end
  end

  def crosses?(%__MODULE__{orientation: orientation}, %__MODULE__{orientation: orientation})
      when orientation in [:vertical, :horizontal], do: false

  @spec circuits_overlap?([t()], [t()]) :: boolean()
  def circuits_overlap?(left_circuit, right_circuit) do
    for left_wall <- left_circuit, right_wall <- right_circuit do
      {left_wall, right_wall}
    end
    |> Enum.any?(fn {left_wall, right_wall} ->
      crosses?(left_wall, right_wall)
    end)
  end

  defp reverse_range(left..right//step), do: right..left//-step
end
