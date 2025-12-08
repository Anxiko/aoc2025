defmodule Aoc2025.Solutions.Day8 do
  alias Aoc2025.Shared.Coord3D

  @behaviour Aoc2025.DaySolver

  @enforce_keys [:distances, :junctions_count]
  defstruct @enforce_keys ++
              [connection_log: [], junction_to_group: %{}, group_to_junctions: %{}, groups: 0]

  @type distance() :: {Coord3D.t(), Coord3D.t(), float()}
  @type group() :: non_neg_integer()

  @type t() :: %__MODULE__{
          distances: [distance()],
          connection_log: [{Coord3D.t(), Coord3D.t()}],
          junctions_count: non_neg_integer(),
          junction_to_group: %{optional(Coord3D.t()) => group()},
          group_to_junctions: %{optional(group()) => [Coord3D.t()]},
          groups: group()
        }

  @impl true
  def solve(input, part, mode) do
    problem =
      input
      |> Enum.map(&parse_coord3D/1)
      |> new()

    case part do
      :part1 ->
        connections =
          case mode do
            :real -> 1_000
            :example -> 10
          end

        problem
        |> make_connections(connections)
        |> junction_groups()
        |> Enum.map(fn {_group, coords} -> length(coords) end)
        |> Enum.sort(:desc)
        |> Enum.take(3)
        |> Enum.product()

      :part2 ->
        %__MODULE__{
          connection_log: [{%Coord3D{x: left_x}, %Coord3D{x: right_x}} | _connection_log]
        } = make_connections(problem, :all)

        left_x * right_x
    end
  end

  @spec new([Coord3D.t()]) :: t()
  def new(coords) do
    %__MODULE__{
      distances: calc_distances(coords),
      junctions_count: length(coords)
    }
  end

  @spec parse_coord3D(String.t()) :: Coord3D.t()
  defp parse_coord3D(line) do
    [x, y, z] = line |> String.split(",") |> Enum.map(&String.to_integer/1)
    Coord3D.new(x, y, z)
  end

  @spec calc_distances([Coord3D.t()]) :: [distance()]
  defp calc_distances(coords) do
    for left <- coords, right <- coords, left < right do
      {left, right, left |> Coord3D.sub(right) |> Coord3D.mod()}
    end
    |> Enum.sort_by(fn {_left, _right, dist} -> dist end, :asc)
  end

  @spec assign_group(t(), group(), Coord3D.t()) :: t()
  defp assign_group(%__MODULE__{} = problem, new_group, junction) do
    case Map.get(problem.junction_to_group, junction) do
      ^new_group ->
        problem

      nil ->
        add_to_group(problem, new_group, junction)

      old_group ->
        in_old_group = Map.fetch!(problem.group_to_junctions, old_group)

        problem
        |> delete_group(old_group)
        |> add_to_group(new_group, in_old_group)
    end
  end

  @spec add_to_group(t(), group(), Coord3D.t() | [Coord3D.t()]) :: t()
  defp add_to_group(%__MODULE__{} = problem, group, junction_or_junctions) do
    junctions = List.wrap(junction_or_junctions)

    %{
      problem
      | group_to_junctions:
          Map.update(problem.group_to_junctions, group, junctions, &(junctions ++ &1)),
        junction_to_group:
          Enum.reduce(junctions, problem.junction_to_group, fn junction, junction_to_group ->
            Map.put(junction_to_group, junction, group)
          end)
    }
  end

  @spec delete_group(t(), group()) :: t()
  defp delete_group(%__MODULE__{} = problem, group) do
    %{problem | group_to_junctions: Map.delete(problem.group_to_junctions, group)}
  end

  @spec bump_groups(t()) :: t()
  defp bump_groups(%__MODULE__{} = problem) do
    %{problem | groups: problem.groups + 1}
  end

  @spec join_pair(t(), Coord3D.t(), Coord3D.t()) :: t()
  defp join_pair(%__MODULE__{} = problem, left, right) do
    left_group = Map.get(problem.junction_to_group, left)
    right_group = Map.get(problem.junction_to_group, right)

    problem =
      case {left_group, right_group} do
        {nil, nil} ->
          problem
          |> assign_group(problem.groups, left)
          |> assign_group(problem.groups, right)
          |> bump_groups()

        {left_group, nil} ->
          assign_group(problem, left_group, right)

        {nil, right_group} ->
          assign_group(problem, right_group, left)

        {left_group, right_group} when left_group != right_group ->
          joint_group = min(left_group, right_group)

          problem
          |> assign_group(joint_group, left)
          |> assign_group(joint_group, right)

        {_left_group, _right_group} ->
          problem
      end

    %{problem | connection_log: [{left, right} | problem.connection_log]}
  end

  @spec make_connections(t(), non_neg_integer() | :all) :: t()
  defp make_connections(%__MODULE__{} = problem, target) when target == :all or target > 0 do
    case target do
      :all ->
        problem.distances

      target when is_integer(target) and target > 0 ->
        Enum.take(problem.distances, target)
    end
    |> Enum.reduce_while(problem, fn {left, right, _distance}, problem ->
      problem = join_pair(problem, left, right)

      if fully_connected?(problem) do
        {:halt, problem}
      else
        {:cont, problem}
      end
    end)
  end

  @spec fully_connected?(t()) :: boolean()
  defp fully_connected?(%__MODULE__{} = problem) do
    problem.group_to_junctions
    |> Enum.map(fn {_k, junctions} -> length(junctions) end)
    |> case do
      [total] -> total == problem.junctions_count
      _ -> false
    end
  end

  @spec junction_groups(t()) :: %{optional(group) => [Coord3D.t()]}
  defp junction_groups(%__MODULE__{} = problem) do
    Enum.group_by(
      problem.junction_to_group,
      fn {_coord, group} -> group end,
      fn {coord, _group} -> coord end
    )
  end
end
