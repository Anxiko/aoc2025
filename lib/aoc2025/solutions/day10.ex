defmodule Aoc2025.Solutions.Day10 do
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

    target =
      case part do
        :part1 -> :lights
        :part2 -> :joltages
      end

    machines
    |> Task.async_stream(&min_presses(&1, target), timeout: :infinity)
    |> Enum.map(fn {:ok, value} -> value end)
    |> Enum.sum()
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
