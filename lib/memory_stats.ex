defmodule MemoryStats do
  @doc """
  Display Erlang runtime memory usage statistics.

  Shows memory allocation for different categories within the Erlang VM
  using data from :erlang.memory/0.
  """
  @spec show_usage() :: :ok
  def show_usage() do
    memory_info = :erlang.memory()

    segments = [
      {"Atoms", :green, memory_info[:atom_used]},
      {"Binary", :blue, memory_info[:binary]},
      {"Code", :magenta, memory_info[:code]},
      {"ETS", :yellow, memory_info[:ets]},
      {"Proc.", :red, memory_info[:processes_used]},
      {"System", :light_black, memory_info[:system]}
    ]

    legend = [
      draw_bars(segments, 25),
      " #{format(memory_info[:total])}\n\n",
      draw_legend(segments)
    ]

    IO.puts(IO.ANSI.format(legend))
  end

  defp draw_bars(segments, width) do
    sum = Enum.sum_by(segments, fn {_label, _color, value} -> value end)

    assign_bars(segments, sum, width) |> Enum.map(&draw_bar/1)
  end

  @bar_char "▓"
  defp draw_legend([{label1, color1, value1}, {label2, color2, value2} | rest]) do
    [
      [color1, @bar_char, :default_color, " ", pad_label(label1), format(value1), " "],
      [color2, @bar_char, :default_color, " ", pad_label(label2), format(value2), "\n"]
      | draw_legend(rest)
    ]
  end

  defp draw_legend([{label, color, value}]) do
    [[color, @bar_char, :default_color, " ", pad_label(label), format(value), "\n"]]
  end

  defp draw_legend([]), do: []

  defp pad_label(label), do: String.pad_trailing(label, 7)

  defp assign_bars([{label, color, _value}], _sum, width_left), do: [{label, color, width_left}]

  defp assign_bars([{label, color, value} | rest], sum, width_left) do
    width = round(value / sum * width_left)
    [{label, color, width} | assign_bars(rest, sum, width_left - width)]
  end

  defp draw_bar({_label, color, width}),
    do: [color, String.duplicate(@bar_char, width), :default_color]

  @doc """
  Display system memory usage statistics.

  Shows physical memory usage from the operating system perspective
  using data from :memsup.get_system_memory_data/0.
  """
  @spec show_system_usage() :: :ok
  def show_system_usage() do
    case :memsup.get_system_memory_data() do
      system_memory when is_list(system_memory) ->
        render_system_memory(system_memory)

      _error ->
        IO.puts("Error: Unable to retrieve system memory data")
    end
  end

  defp render_system_memory(system_memory) do
    # Extract system memory categories
    total = Keyword.get(system_memory, :total_memory, 0)
    free = Keyword.get(system_memory, :free_memory, 0)
    cached = Keyword.get(system_memory, :cached_memory, 0)
    buffered = Keyword.get(system_memory, :buffered_memory, 0)
    available = Keyword.get(system_memory, :available_memory, free + cached + buffered)

    used = total - available
    adjusted_free = total - used - cached - buffered

    segments = [
      {"Used", :magenta, used},
      {"Cached", :yellow, cached},
      {"Buffer", :blue, buffered},
      {"Free", :green, adjusted_free}
    ]

    legend = [
      draw_bars(segments, 20),
      " #{format(available)}/#{format(total)} #{round(available / total * 100)}%\n\n",
      draw_legend(segments)
    ]

    IO.puts(IO.ANSI.format(legend))
  end

  # 3 significant digits
  defp format(bytes) do
    {value, formatting} = fmt(bytes)
    :io_lib.format(formatting, [value]) |> IO.iodata_to_binary()
  end

  defp fmt(bytes) do
    cond do
      bytes < 1000 -> {bytes, "~4B B "}
      bytes < 1024 * 100 -> {bytes / 1024, "~4.1f KB"}
      bytes < 1024 * 1024 -> {round(bytes / 1024), "~4B KB"}
      bytes < 1_048_576 * 100 -> {bytes / 1_048_576, "~4.1f MB"}
      bytes < 1024 * 1024 * 1024 -> {round(bytes / (1024 * 1024)), "~4B MB"}
      true -> {bytes / (1024 * 1024 * 1024), "~4.1f GB"}
    end
  end
end
