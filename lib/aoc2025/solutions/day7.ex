defmodule Aoc2025.Solutions.Day7 do
  alias Aoc2025.Types
  alias Aoc2025.Shared.Grid
  alias Aoc2025.Shared.Coord

  @keys [:board, :beams, :beam_height, :board_height]
  @enforce_keys @keys
  defstruct @keys ++ [splits: 0]

  @type cell() :: :space | :splitter

  @type t() :: %__MODULE__{
          board: Grid.t(cell()),
          beams: %{integer() => pos_integer()},
          beam_height: integer(),
          board_height: integer(),
          splits: non_neg_integer()
        }

  @behaviour Aoc2025.DaySolver

  @impl true
  def solve(input, part, _mode) do
    experiment =
      input
      |> parse()
      |> complete()

    case part do
      :part1 ->
        experiment.splits

      :part2 ->
        total_power(experiment)
    end
  end

  @spec complete(t()) :: t()
  def complete(%__MODULE__{} = experiment)
      when experiment.beam_height < experiment.board_height do
    experiment
    |> step()
    |> complete()
  end

  def complete(%__MODULE__{} = experiment) when experiment.beam_height == experiment.board_height,
    do: experiment

  @spec total_power(t()) :: non_neg_integer()
  def total_power(%__MODULE__{} = experiment) do
    Enum.sum_by(experiment.beams, fn {_beam_x, beam_power} -> beam_power end)
  end

  @spec step(t()) :: t()
  defp step(%__MODULE__{beam_height: beam_height, board_height: board_height} = experiment)
       when beam_height < board_height do
    {beams, new_splits} =
      experiment.beams
      |> Enum.map(fn {beam_x, beam_power} -> step_beam(experiment, beam_x, beam_power) end)
      |> Enum.reduce({%{}, 0}, fn {keep_or_split, beam_x_list, beam_power}, {mapping, splits} ->
        splits =
          case keep_or_split do
            :keep -> splits
            :split -> splits + 1
          end

        mapping =
          beam_x_list
          |> Map.new(fn beam_x -> {beam_x, beam_power} end)
          |> Map.merge(mapping, fn _beam_x, beam_power_1, beam_power_2 ->
            beam_power_1 + beam_power_2
          end)

        {mapping, splits}
      end)

    %{
      experiment
      | beams: beams,
        beam_height: experiment.beam_height + 1,
        splits: experiment.splits + new_splits
    }
  end

  @spec step_beam(t(), integer(), pos_integer()) :: {:keep | :split, [integer()], pos_integer()}
  defp step_beam(%__MODULE__{} = experiment, beam_x, beam_power) do
    next_coord = Coord.new(beam_x, experiment.beam_height)

    case Grid.read(experiment.board, next_coord, :space) do
      :space ->
        {:keep, [beam_x], beam_power}

      :splitter ->
        {:split, [beam_x - 1, beam_x + 1], beam_power}
    end
  end

  @spec parse(Types.input()) :: t()
  defp parse(input) do
    grid =
      input
      |> Enum.map(&String.graphemes/1)
      |> Grid.from_rows()

    {:ok, %Coord{x: starter_x, y: starter_y}} = Grid.find(grid, "S")
    {_min, %Coord{x: _x_max, y: y_max}} = Grid.bounding_box(grid)

    grid =
      Grid.map(grid, fn
        "^" -> :splitter
        space when space in ["S", "."] -> :space
      end)

    %__MODULE__{
      board: grid,
      beams: %{starter_x => 1},
      beam_height: starter_y,
      board_height: y_max
    }
  end
end
