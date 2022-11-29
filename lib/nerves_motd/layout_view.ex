defmodule NervesMOTD.LayoutView do
  @moduledoc false

  alias NervesMOTD.SystemInfo

  @typedoc """
  One row of information

  A row may contain 0, 1 or 2 cells.
  """
  @type row() :: [cell()]

  @typedoc """
  A label and value
  """
  @type cell() :: {String.t(), IO.ANSI.ansidata()}

  @spec render(keyword()) :: IO.chardata()
  def render(opts) do
    logo = opts[:logo]
    header = opts[:header]
    rows = Keyword.fetch!(opts, :rows)
    help_text = opts[:help_text]

    [
      logo,
      IO.ANSI.reset(),
      header,
      "\n",
      rows |> Enum.map(&format_row/1),
      "\n",
      help_text
    ]
    |> List.flatten()
    |> IO.ANSI.format()
  end

  ## formatters

  @spec format_row([cell()]) :: iolist()
  # A blank line
  def format_row([]), do: ["\n"]

  # A row with full width
  def format_row([{label, value}]) do
    ["  ", format_cell_label(label), " : ", value, "\n", :reset]
  end

  # A row with two columns
  def format_row([col0, col1]) do
    ["  ", format_cell(col0, 0), format_cell(col1, 1), "\n"]
  end

  def format_row(nil), do: []

  @spec format_cell(cell(), 0 | 1) :: IO.ANSI.ansidata()
  def format_cell({label, value}, column_index) do
    [format_cell_label(label), " : ", format_cell_value(value, column_index, 24), :reset]
  end

  @spec format_cell_label(IO.ANSI.ansidata()) :: IO.ANSI.ansidata()
  def format_cell_label(label), do: fit_ansidata(label, 12)

  @spec format_cell_value(IO.ANSI.ansidata(), 0 | 1, pos_integer()) :: IO.ANSI.ansidata()
  def format_cell_value(value, 0, width), do: fit_ansidata(value, width)
  def format_cell_value(value, 1, _width), do: value

  @doc """
  Fit ansidata to a specified column width

  This function first trims the ansidata so that it doesn't exceed the specified
  width. Then if it's not long enough, it will pad the ansidata to either left or
  right justify it.

  ## Examples

      iex> s = [:red, "r", :yellow, "a", :light_yellow, "i", :green, "n", :blue, "b", :magenta, "o", :white, "w"]
      ...> fit_ansidata(s, 4)
      [:red, "r", :yellow, "a", :light_yellow, "i", :green, "n"]

      iex> s = [:red, "r", :yellow, "a", :light_yellow, "i", :green, "n", :blue, "b", :magenta, "o", :white, "w"]
      ...> fit_ansidata(s, 10)
      [[:red, "r", :yellow, "a", :light_yellow, "i", :green, "n", :blue, "b", :magenta, "o", :white, "w"], "   "]

      iex> fit_ansidata([:red, ["Hello"], [" ", "world!"]], 20, :right)
      ["        ", :red, "Hello", " ", "world!"]

      iex> fit_ansidata([:red, [["Hello"]], " ", "world!"], 2, :right)
      [:red, "He"]
  """
  @spec fit_ansidata(IO.ANSI.ansidata(), non_neg_integer(), :left | :right) :: IO.ANSI.ansidata()
  def fit_ansidata(ansidata, width, justification \\ :left) do
    {result, length_left} = trim_ansidata(ansidata, [], width)

    result
    |> Enum.reverse()
    |> add_padding(length_left, justification)
  end

  defp add_padding(ansidata, 0, _justification), do: ansidata
  defp add_padding(ansidata, count, :left), do: [ansidata, :binary.copy(" ", count)]
  defp add_padding(ansidata, count, :right), do: [:binary.copy(" ", count) | ansidata]

  defp trim_ansidata(_remainder, acc, 0), do: {acc, 0}
  defp trim_ansidata([], acc, length), do: {acc, length}
  defp trim_ansidata(char, acc, length) when is_integer(char), do: {[char | acc], length - 1}
  defp trim_ansidata(ansicode, acc, length) when is_atom(ansicode), do: {[ansicode | acc], length}

  defp trim_ansidata(str, acc, length) when is_binary(str) do
    sliced_string = String.slice(str, 0, length)
    {[sliced_string | acc], length - String.length(sliced_string)}
  end

  defp trim_ansidata([head | rest], acc, length) do
    {result, length_left} = trim_ansidata(head, acc, length)

    trim_ansidata(rest, result, length_left)
  end

  ## cells

  @spec uptime_cell :: cell()
  def uptime_cell(), do: {"Uptime", SystemInfo.uptime_text()}

  @spec clock_cell :: cell()
  def clock_cell(), do: {"Clock", SystemInfo.clock_text()}

  @spec cpu_temperature_cell :: cell() | nil
  def cpu_temperature_cell() do
    if text = SystemInfo.cpu_temperature_text() do
      {"Temperature", text}
    end
  end

  @spec firmware_cell :: cell()
  def firmware_cell(), do: {"Firmware", SystemInfo.firmware_status_text()}

  @spec applications_cell(%{loaded: [atom], started: [atom]}) :: cell()
  def applications_cell(apps), do: {"Applications", SystemInfo.applications_text(apps)}

  @spec memory_usage_cell :: cell()
  def memory_usage_cell(), do: {"Memory usage", SystemInfo.memory_usage_text()}

  @spec part_usage_cell :: cell()
  def part_usage_cell(), do: {"Part usage", SystemInfo.active_part_usage_text()}

  @spec hostname_cell :: cell()
  def hostname_cell(), do: {"Hostname", SystemInfo.hostname_text()}

  @spec load_average_cell :: cell()
  def load_average_cell(), do: {"Load average", SystemInfo.load_average_text()}
end
