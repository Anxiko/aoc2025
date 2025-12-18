defmodule Aoc2025.Solutions.Day10 do
  alias Aoc2025.Shared.Lists

  @enforce_keys [
    :target_lights,
    :buttons,
    :target_joltages
  ]
  defstruct @enforce_keys

  @type lights() :: [boolean()]
  @type button() :: [non_neg_integer()]
  @type joltage() :: pos_integer()
  @type target() :: :lights | :joltages
  @type status() :: :complete | :cont | :halt

  @type t() :: %__MODULE__{
          target_lights: lights(),
          buttons: [button()],
          target_joltages: [joltage()]
        }

  @machine_pattern ~r"^\[(?P<lights>[.#]+)\] (?P<buttons>((\(\d+(,\d+)*)\) )+)\{(?P<joltages>\d+(,\d+)*)\}$"
  @button_pattern ~r"\((?P<indices>\d+(,\d+)*)\)"

  @behaviour Aoc2025.DaySolver

  def solve(input, part, _mode) do
    machines = Enum.map(input, &parse/1)

    case part do
      :part1 ->
        machines
        |> Enum.map(fn %__MODULE__{} = machine ->
          machine.target_lights
          |> presses_for_lights(machine.buttons)
          |> Enum.map(&length/1)
          |> Enum.min()
        end)
        |> Enum.sum()

      :part2 ->
        machines
        |> Enum.map(fn %__MODULE__{} = machine ->
          presses_for_target(machine.target_joltages, machine.buttons)
        end)
        |> Enum.sum()
    end
  end

  @spec new(lights(), [button()], [joltage()]) :: t()
  def new(target_lights, buttons, target_joltages) do
    %__MODULE__{
      target_lights: target_lights,
      buttons: buttons,
      target_joltages: target_joltages
    }
  end

  @spec parse(String.t()) :: t()
  def parse(machine) do
    %{"lights" => lights, "buttons" => buttons, "joltages" => joltages} =
      Regex.named_captures(@machine_pattern, machine)

    new(parse_lights(lights), parse_buttons(buttons), parse_target_joltages(joltages))
  end

  @spec presses_for_target([joltage()], [button()]) :: non_neg_integer() | nil
  def presses_for_target(target, buttons) do
    {:ok, cache} = Agent.start_link(&Map.new/0)
    presses_for_target(target, buttons, cache)
  end

  @spec presses_for_target([joltage()], [button()], Agent.agent()) :: non_neg_integer() | nil
  def presses_for_target(target, buttons, cache) do
    cond do
      Enum.all?(target, &(&1 == 0)) ->
        0

      Enum.any?(target, &(&1 < 0)) ->
        nil

      true ->
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
                    presses_for_half_target -> length(subset) + 2 * presses_for_half_target
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
