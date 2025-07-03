defmodule MemoryStats do
  def show_usage() do
    memory_info = :erlang.memory()

    # Convert to MB for display
    total = memory_info[:total]
    atom = memory_info[:atom_used]
    binary = memory_info[:binary]
    code = memory_info[:code]
    ets = memory_info[:ets]
    processes = memory_info[:processes_used]
    system = memory_info[:system]

    # Calculate bar segments (total bar width of 20 characters)
    bar_width = 22
    atom_bars = calculate_bar_segments(atom, total, bar_width)
    binary_bars = calculate_bar_segments(binary, total, bar_width)
    code_bars = calculate_bar_segments(code, total, bar_width)
    ets_bars = calculate_bar_segments(ets, total, bar_width)
    processes_bars = calculate_bar_segments(processes, total, bar_width)
    system_bars = calculate_bar_segments(system, total, bar_width)

    # Create the visual bar
    bar = [
      :green,
      String.duplicate("▒", atom_bars),
      :blue,
      String.duplicate("░", binary_bars),
      :magenta,
      String.duplicate("█", code_bars),
      :yellow,
      String.duplicate("░", ets_bars),
      :red,
      String.duplicate("▓", processes_bars),
      :light_black,
      String.duplicate("░", system_bars),
      :reset
    ]

    legend = [
      bar,
      " #{format(total)}\n\n",
      [:green, "▒", :reset, " Atoms  #{format(atom)} "],
      [:blue, "░", :reset, " Binary #{format(binary)}\n"],
      [:magenta, "█", :reset, " Code   #{format(code)} "],
      [:yellow, "░", :reset, " ETS    #{format(ets)}\n"],
      [:red, "▓", :reset, " Proc.  #{format(processes)} "],
      [:light_black, "░", :reset, " System #{format(system)}\n"]
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
      bytes < 1000 -> {bytes, "~5B B"}
      bytes < 1024 * 100 -> {bytes / 1024, "~5.1f KB"}
      bytes < 1024 * 1024 -> {round(bytes / 1024), "~5B KB"}
      bytes < 1_048_576 * 100 -> {bytes / 1_048_576, "~5.1f MB"}
      bytes < 1024 * 1024 * 1024 -> {round(bytes / (1024 * 1024)), "~5B MB"}
      true -> {bytes / (1024 * 1024 * 1024), "~.1f GB"}
    end
  end

  defp calculate_bar_segments(category_bytes, total_bytes, bar_width) do
    ratio = category_bytes / total_bytes
    segments = round(ratio * bar_width)
    max(segments, 0)
  end
end
