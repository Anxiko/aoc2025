defmodule Aoc2025.Solutions.Day6 do
  alias Aoc2025.Types
  @behaviour Aoc2025.DaySolver

  @mandatory_keys [:rows, :operations]

  @enforce_keys @mandatory_keys
  defstruct @mandatory_keys

  @type row() :: [String.t()]
  @type column(element) :: [element]
  @type operation() :: :add | :mul

  @type t() :: %__MODULE__{
          rows: [row()],
          operations: [operation()]
        }

  @mapped_operations %{
    "+" => :add,
    "*" => :mul
  }

  @impl true
  def solve(input, part, _mode) do
    worksheet = parse(input)

    vertical? =
      case part do
        :part1 -> false
        :part2 -> true
      end

    calculate(worksheet, vertical?)
  end

  @spec parse(Types.input()) :: t()
  defp parse(input) do
    {operations, rows} = List.pop_at(input, -1)

    {operations, column_sizes} =
      parse_operations(operations)

    rows = Enum.map(rows, &split_row_by_sizes(&1, column_sizes))

    %__MODULE__{rows: rows, operations: operations}
  end

  @spec calculate(t(), boolean()) :: integer()
  def calculate(%__MODULE__{} = worksheet, vertical?) do
    column_mapper =
      if vertical? do
        &vertical_read/1
      else
        &horizontal_read/1
      end

    worksheet
    |> columns()
    |> Enum.map(column_mapper)
    |> Enum.zip(worksheet.operations)
    |> Enum.map(fn {column, operation} ->
      Enum.reduce(column, operation_function(operation))
    end)
    |> Enum.sum()
  end

  @spec columns(t()) :: [column(String.t())]
  defp columns(%__MODULE__{} = worksheet) do
    worksheet.rows |> do_columns([]) |> Enum.map(&Enum.reverse/1)
  end

  @spec do_columns([row()], [column(String.t())]) :: [column(String.t())]
  defp do_columns([[] | _rest], acc) do
    Enum.reverse(acc)
  end

  defp do_columns(rows, acc) do
    {column, rows} =
      Enum.reduce(rows, {[], []}, fn [h | t], {column, rows} ->
        {[h | column], [t | rows]}
      end)

    do_columns(Enum.reverse(rows), [column | acc])
  end

  @spec horizontal_read(column(String.t())) :: column(integer())
  defp horizontal_read(column) do
    Enum.map(column, fn value -> value |> String.trim() |> String.to_integer() end)
  end

  @spec vertical_read(column(String.t())) :: column(integer())
  defp vertical_read(column) do
    do_vertical_read(column, [])
  end

  defp do_vertical_read(column, acc) do
    {number, column} =
      Enum.reduce(column, {"", []}, fn
        "", acc ->
          acc

        <<digit, rest::binary>>, {number, numbers} ->
          {<<number::binary, digit::utf8>>, [rest | numbers]}
      end)

    case number do
      "" -> acc
      number ->
        number = number |> String.trim() |> String.to_integer()
        do_vertical_read(Enum.reverse(column), [number | acc])
    end
  end

  @spec operation_function(operation()) :: (integer(), integer() -> integer())
  defp operation_function(:add), do: &Kernel.+/2
  defp operation_function(:mul), do: &Kernel.*/2

  @spec parse_operations(String.t()) :: {[operation()], [non_neg_integer()]}
  defp parse_operations(row) do
    do_parse_operations_row(row, []) |> Enum.unzip()
  end

  defp do_parse_operations_row("", acc) do
    Enum.reverse(acc)
  end

  defp do_parse_operations_row(<<operation::utf8, rest::binary>>, acc)
       when is_map_key(@mapped_operations, <<operation::utf8>>) do
    operation = Map.fetch!(@mapped_operations, <<operation::utf8>>)

    {column_size, rest} =
      case count_remove_leading_whitespace(rest) do
        {leading, "" = rest} -> {leading + 1, rest}
        {leading, rest} -> {leading, rest}
      end

    do_parse_operations_row(rest, [{operation, column_size} | acc])
  end

  defp count_remove_leading_whitespace(string) do
    do_count_remove_leading_whitespace(string, 0)
  end

  defp do_count_remove_leading_whitespace(" " <> string, acc),
    do: do_count_remove_leading_whitespace(string, acc + 1)

  defp do_count_remove_leading_whitespace(string, acc), do: {acc, string}

  defp split_row_by_sizes(row, sizes), do: do_split_row_by_sizes(row, sizes, [])

  defp do_split_row_by_sizes("", [], acc), do: Enum.reverse(acc)

  defp do_split_row_by_sizes(row, [size | sizes], acc) do
    {column, row} = String.split_at(row, size)

    row =
      case row do
        "" -> ""
        " " <> row -> row
      end

    do_split_row_by_sizes(row, sizes, [column | acc])
  end
end
