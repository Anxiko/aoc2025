defmodule Aoc2025.Solutions.Day10 do
  @enforce_keys [:target_lights, :current_lights, :buttons, :joltage_requirements]
  defstruct @enforce_keys

  @type lights() :: [boolean()]
  @type button() :: [non_neg_integer()]
  @type joltage() :: pos_integer()

  @type t() :: %__MODULE__{
          target_lights: lights(),
          current_lights: lights(),
          buttons: [button()],
          joltage_requirements: [joltage()]
        }

  @machine_pattern ~r"^\[(?P<lights>[.#]+)\] (?P<buttons>((\(\d+(,\d+)*)\) )+)\{(?P<joltages>\d+(,\d+)*)\}$"
  @button_pattern ~r"\((?P<indices>\d+(,\d+)*)\)"

  @behaviour Aoc2025.DaySolver

  def solve(input, part, _mode) do
    machines = Enum.map(input, &parse/1)

    case part do
      :part1 ->
        machines
        |> Enum.map(&min_presses/1)
        |> Enum.sum()
    end
  end

  @spec new(lights(), [button()], [joltage()]) :: t()
  def new(target_lights, buttons, joltage_requirements) do
    %__MODULE__{
      target_lights: target_lights,
      current_lights: List.duplicate(false, length(target_lights)),
      buttons: buttons,
      joltage_requirements: joltage_requirements
    }
  end

  @spec parse(String.t()) :: t()
  def parse(machine) do
    %{"lights" => lights, "buttons" => buttons, "joltages" => joltages} =
      Regex.named_captures(@machine_pattern, machine)

    new(parse_lights(lights), parse_buttons(buttons), parse_joltage_requirements(joltages))
  end

  @spec min_presses(t()) :: non_neg_integer()
  def min_presses(%__MODULE__{} = machine) do
    min_presses([machine], 0)
  end

  defp min_presses(machines, presses) do
    if Enum.any?(machines, &solved?/1) do
      presses
    else
      machines
      |> Enum.flat_map(fn %__MODULE__{} = machine ->
        Enum.map(machine.buttons, &press_button(machine, &1))
      end)
      |> min_presses(presses + 1)
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

    %{machine | current_lights: lights}
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

  @spec parse_joltage_requirements(String.t()) :: [joltage()]
  defp parse_joltage_requirements(joltages) do
    joltages
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end
end
