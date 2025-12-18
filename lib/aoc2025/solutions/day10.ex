defmodule Aoc2025.Solutions.Day10 do
  alias Aoc2025.Shared.Lists

  @enforce_keys [
    :target_lights,
    :current_lights,
    :buttons,
    :target_joltages,
    :current_joltages
  ]
  defstruct @enforce_keys

  @type lights() :: [boolean()]
  @type button() :: [non_neg_integer()]
  @type joltage() :: pos_integer()
  @type target() :: :lights | :joltages
  @type status() :: :complete | :cont | :halt

  @type t() :: %__MODULE__{
          target_lights: lights(),
          current_lights: lights(),
          buttons: [button()],
          target_joltages: [joltage()],
          current_joltages: [joltage()]
        }

  @machine_pattern ~r"^\[(?P<lights>[.#]+)\] (?P<buttons>((\(\d+(,\d+)*)\) )+)\{(?P<joltages>\d+(,\d+)*)\}$"
  @button_pattern ~r"\((?P<indices>\d+(,\d+)*)\)"

  @behaviour Aoc2025.DaySolver

  def solve(input, part, _mode) do
    machines = Enum.map(input, &parse/1)

    case part do
      :part1 ->
        machines
        |> Enum.map(&min_presses(&1, :lights))
        |> Enum.sum()

      :part2 ->
        machines
        |> Enum.map(fn %__MODULE__{} = machine ->
          IO.inspect(machine, label: "Solving")

          {:ok, cache} = Agent.start_link(&Map.new/0)
          presses_for_target(machine.target_joltages, machine.buttons, cache)
          |> IO.inspect(label: "Presses for #{inspect(machine)}")
        end)
        |> Enum.sum()
    end
  end

  @spec new(lights(), [button()], [joltage()]) :: t()
  def new(target_lights, buttons, target_joltages) do
    %__MODULE__{
      target_lights: target_lights,
      current_lights: List.duplicate(false, length(target_lights)),
      buttons: buttons,
      target_joltages: target_joltages,
      current_joltages: List.duplicate(0, length(target_joltages))
    }
  end

  @spec parse(String.t()) :: t()
  def parse(machine) do
    %{"lights" => lights, "buttons" => buttons, "joltages" => joltages} =
      Regex.named_captures(@machine_pattern, machine)

    new(parse_lights(lights), parse_buttons(buttons), parse_target_joltages(joltages))
  end

  @spec presses_for_target([joltage()], [button()], Agent.agent()) :: non_neg_integer() | nil
  def presses_for_target(target, buttons, cache) do
    if Enum.all?(target, &(&1 == 0)) do
      0
    else
      case Agent.get(cache, &Map.fetch(&1, {target, buttons})) do
        {:ok, solution} ->
          solution

        :error ->
          lights = Enum.map(target, fn joltage -> rem(joltage, 2) == 1 end)

          case presses_for_lights(lights, buttons) do
            [] ->
              nil

            subsets ->
              subsets
              |> Enum.map(fn subset ->
                target =
                  Enum.reduce(subset, target, fn button, target ->
                    reduce_target(target, button)
                  end)

                half_target = Enum.map(target, &div(&1, 2))

                case presses_for_target(half_target, buttons, cache) do
                  nil -> nil
                  presses_for_half_target -> length(subsets) + 2 * presses_for_half_target
                end
              end)
              |> Enum.filter(&(&1 != nil))
              |> case do
                [] -> nil
                presses -> Enum.min(presses)
              end
          end
          |> tap(fn solution ->
            Agent.update(cache, &Map.put(&1, {target, buttons}, solution))
          end)
      end
    end
  end

  @spec presses_for_lights(lights(), [button()]) :: [[button()]]
  def presses_for_lights(lights, buttons) do
    0..length(buttons)
    |> Stream.flat_map(&Lists.combinations(buttons, &1))
    |> Enum.filter(fn subsets ->
      subsets
      |> Enum.reduce(lights, fn button, lights -> toggle_lights(lights, button) end)
      |> Enum.all?(&(&1 == false))
    end)
  end

  @spec toggle_lights(lights(), button()) :: lights()
  defp toggle_lights(lights, button) do
    Enum.with_index(lights, fn light, index ->
      if index in button do
        not light
      else
        light
      end
    end)
  end

  @spec reduce_target([joltage()], button()) :: button()
  defp reduce_target(target, button) do
    Enum.with_index(target, fn joltage, index ->
      if index in button do
        joltage - 1
      else
        joltage
      end
    end)
  end

  @spec branch_and_bound(t()) :: non_neg_integer()
  def branch_and_bound(%__MODULE__{} = machine) do
    branch_and_bound(machine.target_joltages, machine.buttons)
  end

  @spec branch_and_bound([joltage()], [button()]) :: non_neg_integer()
  def branch_and_bound(target, buttons) do
    upper_bound = ceil(Enum.sum(target) / length(Enum.min_by(buttons, &length/1)))

    branch_and_bound(target, Enum.sort_by(buttons, &length/1, :desc), 0, upper_bound)
  end

  @spec branch_and_bound([joltage()], [button()], non_neg_integer(), non_neg_integer()) ::
          non_neg_integer()
  defp branch_and_bound(_target, _buttons, presses, best) when best <= presses,
    do: best

  defp branch_and_bound(target, [], presses, best) do
    if Enum.all?(target, &(&1 == 0)) do
      IO.inspect(presses, label: "Solution found, best is #{best}")
      update_best(best, presses)
    else
      best
    end
  end

  defp branch_and_bound(target, [button | buttons], presses, best) do
    case max_presses(target, button) do
      {:exact, button_presses} ->
        IO.inspect(presses + button_presses, label: "Solution found, best is #{best}")
        update_best(best, presses + button_presses)

      {:max_possible, max_button_presses} ->
        lower_bound = ceil(Enum.sum(target) / length(Enum.max_by([button | buttons], &length/1)))

        if presses + lower_bound < best do
          max_button_presses..0//-1
          |> Enum.reduce(best, fn button_presses, best ->
            presses =
              target
              |> target_after_pressing(button, button_presses)
              |> branch_and_bound(buttons, presses + button_presses, best)

            update_best(best, presses)
          end)
        else
          best
        end
    end
  end

  @spec max_presses([joltage()], button()) :: {:exact | :max_possible, non_neg_integer()}
  defp max_presses(target, button) do
    max_possible =
      target
      |> Enum.with_index()
      |> Enum.filter(fn {_value, idx} -> idx in button end)
      |> Enum.min_by(fn {value, _idx} -> value end)
      |> then(fn {value, _idx} -> value end)

    exact? =
      target
      |> Enum.with_index()
      |> Enum.all?(fn {value, idx} ->
        if idx in button do
          value == max_possible
        else
          value == 0
        end
      end)

    if exact?, do: {:exact, max_possible}, else: {:max_possible, max_possible}
  end

  @spec target_after_pressing([joltage()], button(), non_neg_integer()) :: [joltage()]
  defp target_after_pressing(target, _button, 0), do: target

  defp target_after_pressing(target, button, presses) do
    target
    |> Enum.with_index()
    |> Enum.map(fn {value, idx} ->
      if idx in button do
        value - presses
      else
        value
      end
    end)
  end

  @spec update_best(non_neg_integer() | nil, non_neg_integer()) :: non_neg_integer()
  defp update_best(nil, presses), do: presses
  defp update_best(best, presses), do: min(best, presses)

  @spec min_presses(t(), target()) :: non_neg_integer()
  def min_presses(%__MODULE__{} = machine, target) do
    min_presses([machine], target, MapSet.new(), 0)
  end

  @dialyzer {:nowarn_function, min_presses: 4}
  @spec min_presses([t()], target(), MapSet.t(t()), non_neg_integer()) :: non_neg_integer()
  defp min_presses([_ | _] = machines, target, %MapSet{} = seen, presses) do
    if Enum.any?(machines, &(completion_status(&1, target) == :complete)) do
      presses
    else
      machines =
        machines
        |> Enum.flat_map(fn %__MODULE__{} = machine ->
          Enum.map(machine.buttons, &press_button(machine, &1))
        end)
        |> Enum.reject(&MapSet.member?(seen, &1))
        |> Enum.reject(&(completion_status(&1, target) == :halt))

      min_presses(machines, target, machines |> MapSet.new() |> MapSet.union(seen), presses + 1)
    end
  end

  @spec press_button(t(), button()) :: t()
  def press_button(%__MODULE__{} = machine, button) do
    lights =
      machine.current_lights
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        if index in button do
          not value
        else
          value
        end
      end)

    joltages =
      machine.current_joltages
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        if index in button do
          value + 1
        else
          value
        end
      end)

    %{machine | current_lights: lights, current_joltages: joltages}
  end

  @spec completion_status(t(), target()) :: status()
  def completion_status(%__MODULE__{} = machine, :lights) do
    if machine.current_lights == machine.target_lights do
      :complete
    else
      :continue
    end
  end

  def completion_status(%__MODULE__{} = machine, :joltages) do
    machine.current_joltages
    |> Enum.zip(machine.target_joltages)
    |> Enum.reduce_while(:complete, fn
      {current, target}, _ when current > target -> {:halt, :halt}
      {target, target}, :complete -> {:cont, :complete}
      _, _ -> {:cont, :cont}
    end)
  end

  @spec solved?(t()) :: boolean()
  def solved?(%__MODULE__{} = machine), do: machine.current_lights == machine.target_lights

  @spec parse_lights(String.t()) :: lights()
  defp parse_lights(lights) do
    lights
    |> String.graphemes()
    |> Enum.map(fn
      "#" -> true
      "." -> false
    end)
  end

  @spec parse_buttons(String.t()) :: [button()]
  defp parse_buttons(buttons) do
    @button_pattern
    |> Regex.scan(buttons, capture: [:indices])
    |> Enum.map(&hd/1)
    |> Enum.map(fn button ->
      button |> String.split(",") |> Enum.map(&String.to_integer/1)
    end)
  end

  @spec parse_target_joltages(String.t()) :: [joltage()]
  defp parse_target_joltages(joltages) do
    joltages
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end
end
