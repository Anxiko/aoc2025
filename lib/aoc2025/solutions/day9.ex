defmodule Aoc2025.Solutions.Day9 do
  alias Aoc2025.Shared.Lists
  alias Aoc2025.Shared.Coord
  alias Aoc2025.Shared.Ranges
  alias Aoc2025.Solutions.Day9.Wall

  @type mapped_walls() :: %{{Wall.orientation(), integer()} => [Wall.t()]}

  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, part, _mode) do
    coords = Enum.map(input, &parse_coord/1)

    sorted_areas =
      coords
      |> Lists.pairs()
      |> Enum.map(fn {left, right} -> {left, right, area(left, right)} end)
      |> Enum.sort_by(fn {_left, _right, area} -> area end, :desc)

    case part do
      :part1 ->
        {_left, _right, area} = hd(sorted_areas)
        area

      :part2 ->
        walls = Wall.from_circuit(coords)

        # The inside of the polygon should be on the counterclockwise turn of the wall
        # For example, a wall going up (towards Y negative) has the inside to the left, and the outside to the right
        # First we build the walls and then we check. If they don't obey this property, just turn them all around

        walls =
          walls
          |> Enum.filter(fn %Wall{orientation: orientation} -> orientation == :vertical end)
          |> Enum.min_by(fn %Wall{} = wall -> wall.pinned_coord end)
          |> Wall.turning_counterclockwise()
          |> case do
            {:horizontal, :negative} -> Wall.reverse_circuit(walls)
            {:horizontal, :positive} -> walls
          end

        mapped_walls =
          Enum.group_by(walls, fn %Wall{} = wall -> {wall.orientation, wall.pinned_coord} end)

        {_left, _right, area} =
          Enum.find(sorted_areas, fn {left, right, _area} ->
            valid_inner_rectangle?(left, right, walls, mapped_walls)
          end)

        area
    end
  end

  @spec parse_coord(String.t()) :: Coord.t()
  defp parse_coord(coord) do
    [x, y] = coord |> String.split(",") |> Enum.map(&String.to_integer/1)
    Coord.new(x, y)
  end

  @spec area(Coord.t(), Coord.t()) :: non_neg_integer()
  defp area(%Coord{} = left, %Coord{} = right) do
    %Coord{x: width, y: height} =
      left
      |> Coord.sub(right)

    (abs(width) + 1) * (abs(height) + 1)
  end

  @spec valid_inner_rectangle?(
          Coord.t(),
          Coord.t(),
          [Wall.t()],
          mapped_walls()
        ) :: boolean()
  def valid_inner_rectangle?(left, right, walls, mapped_walls) do
    inside_corner?(left, right, mapped_walls) and
      inside_corner?(right, left, mapped_walls) and
      not walls_within?(left, right, walls)
  end

  @spec walls_within?(Coord.t(), Coord.t(), [Wall.t()]) :: boolean()
  def walls_within?(left, right, walls) do
    x_range = Ranges.auto(left.x, right.x) |> Ranges.increasing()
    y_range = Ranges.auto(left.y, right.y) |> Ranges.increasing()

    vertical_walls = find_candidate_walls(walls, :vertical, Ranges.exclusive(x_range))
    horizontal_walls = find_candidate_walls(walls, :horizontal, Ranges.exclusive(y_range))

    wall_in_axis?(vertical_walls, y_range) or wall_in_axis?(horizontal_walls, x_range)
  end

  defp wall_in_axis?(walls, range) do
    Enum.any?(walls, &wall_in_range?(range, &1))
  end

  defp find_candidate_walls(walls, orientation, %Range{} = exclusive_range) do
    walls
    |> Enum.filter(fn %Wall{} = wall -> wall.orientation == orientation end)
    |> Enum.filter(fn %Wall{} = wall -> wall.pinned_coord in exclusive_range end)
  end

  defp find_candidate_walls(_walls, _orientation, nil), do: []

  defp wall_in_range?(%Range{} = range, %Wall{} = wall) do
    case Ranges.intersection(Ranges.increasing(range), Ranges.increasing(wall.range_coord)) do
      nil ->
        false

      point..point//1 when range.first == range.last ->
        true

      point..point//1 when point == range.first or point == range.last ->
        false

      left..right//1 when left <= right ->
        true
    end
  end

  @spec inside_corner?(Coord.t(), Coord.t(), mapped_walls()) :: boolean()
  def inside_corner?(from, to, mapped_walls) do
    {horizontal, vertical} =
      walls_for_coord(from, mapped_walls)

    case corner_type(horizontal, vertical) do
      :inner -> coord_inside_wall(to, horizontal) and coord_inside_wall(to, vertical)
      :outer -> coord_inside_wall(to, horizontal) or coord_inside_wall(to, vertical)
    end
  end

  defp coord_inside_wall(%Coord{} = coord, %Wall{} = wall) do
    coord_position =
      case wall do
        %Wall{orientation: :vertical} -> coord.x
        %Wall{orientation: :horizontal} -> coord.y
      end

    {_orientation, direction_inside} = Wall.turning_counterclockwise(wall)

    cond do
      coord_position == wall.pinned_coord -> true
      coord_position > wall.pinned_coord -> direction_inside == :positive
      coord_position < wall.pinned_coord -> direction_inside == :negative
    end
  end

  @spec corner_type(Wall.t(), Wall.t()) :: :inner | :outer
  defp corner_type(
         %Wall{orientation: :horizontal} = horizontal,
         %Wall{orientation: :vertical} = vertical
       ) do
    case {horizontal, vertical} do
      {
        %Wall{
          orientation: :horizontal,
          range_coord: _hor_start..corner_x//hor_step,
          pinned_coord: corner_y
        },
        %Wall{
          orientation: :vertical,
          range_coord: corner_y.._hor_end//ver_step,
          pinned_coord: corner_x
        }
      }
      when hor_step > 0 and ver_step < 0 ->
        :inner

      {
        %Wall{
          orientation: :horizontal,
          range_coord: corner_x.._hor_end//hor_step,
          pinned_coord: corner_y
        },
        %Wall{
          orientation: :vertical,
          range_coord: _ver_start..corner_y//ver_step,
          pinned_coord: corner_x
        }
      }
      when hor_step < 0 and ver_step < 0 ->
        :inner

      {
        %Wall{
          orientation: :horizontal,
          range_coord: _hor_start..corner_x//hor_step,
          pinned_coord: corner_y
        },
        %Wall{
          orientation: :vertical,
          range_coord: corner_y.._ver_end//ver_step,
          pinned_coord: corner_x
        }
      }
      when hor_step < 0 and ver_step > 0 ->
        :inner

      {
        %Wall{
          orientation: :horizontal,
          range_coord: corner_x.._hor_end//hor_step,
          pinned_coord: corner_y
        },
        %Wall{
          orientation: :vertical,
          range_coord: _ver_start..corner_y//ver_step,
          pinned_coord: corner_x
        }
      }
      when hor_step > 0 and ver_step > 0 ->
        :inner

      {
        %Wall{
          orientation: :horizontal,
          range_coord: hor_range,
          pinned_coord: corner_y
        },
        %Wall{
          orientation: :vertical,
          range_coord: ver_range,
          pinned_coord: corner_x
        }
      } = walls ->
        if corner_x in hor_range and corner_y in ver_range do
          :outer
        else
          raise ArgumentError, message: "Walls do not meet in a corner: #{inspect(walls)}"
        end
    end
  end

  @spec walls_for_coord(Coord.t(), mapped_walls()) :: {Wall.t(), Wall.t()}
  def walls_for_coord(coord, mapped_walls) do
    [%Wall{orientation: :horizontal} = horizontal] =
      mapped_walls
      |> Map.fetch!({:horizontal, coord.y})
      |> Enum.filter(&Wall.contains?(&1, coord))

    [%Wall{orientation: :vertical} = vertical] =
      mapped_walls
      |> Map.fetch!({:vertical, coord.x})
      |> Enum.filter(&Wall.contains?(&1, coord))

    {horizontal, vertical}
  end

  @spec inner_rectangle(Coord.t(), Coord.t()) :: [Wall.t()]
  def inner_rectangle(%Coord{} = left_coord, %Coord{} = right_coord) do
    left = min(left_coord.x, right_coord.x) + 1
    right = max(left_coord.x, right_coord.x) - 1
    top = min(left_coord.y, right_coord.y) + 1
    bottom = max(left_coord.y, right_coord.y) - 1

    if left <= right and top <= bottom do
      [
        Wall.new(:horizontal, bottom, left..right//1),
        Wall.new(:vertical, right, bottom..top//-1),
        Wall.new(:horizontal, top, right..left//-1),
        Wall.new(:vertical, left, top..bottom//1)
      ]
    else
      []
    end
  end
end
