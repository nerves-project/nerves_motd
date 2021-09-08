defmodule NervesMOTD do
  @moduledoc """
  `NervesMOTD` prints a "message of the day" on Nerves devices.

  To use, add `NervesMOTD.print()` to the `rootfs_overlay/etc/iex.exs` file in
  your Nerves project.
  """

  @logo """
  \e[34m████▄▖    \e[36m▐███
  \e[34m█▌  ▀▜█▙▄▖  \e[36m▐█
  \e[34m█▌ \e[36m▐█▄▖\e[34m▝▀█▌ \e[36m▐█   \e[39mN  E  R  V  E  S
  \e[34m█▌   \e[36m▝▀█▙▄▖ ▐█
  \e[34m███▌    \e[36m▀▜████\e[0m
  """

  @typedoc """
  MOTD options
  """
  @type option() :: {:logo, iodata()}

  @typep cell :: {String.t(), iodata()} | {String.t(), iodata(), :green | :red}

  @doc """
  Print the message of the day

  Options:

  * `:logo` - a custom logo to display instead of the default Nerves logo. Pass
    an empty logo (`""`) to remove it completely.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    {:ok, _} = Application.ensure_all_started(:nerves_runtime)

    IO.puts(logo(opts))

    IO.puts(uname())

    Enum.each(rows(), &IO.puts(["  ", format_row(&1)]))

    IO.puts("""

    Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
    """)
  end

  @spec logo([option()]) :: iodata()
  defp logo(opts) do
    Keyword.get(opts, :logo, @logo)
  end

  @spec rows() :: [[cell()]]
  defp rows() do
    [
      [{"Uptime", uptime()}],
      [{"Clock", clock()}],
      [],
      [firmware_cell(), applications_cell()],
      [memory_usage_cell(), {"Load average", load_average()}],
      [{"Hostname", hostname()}, {"Networks", network_names()}]
    ]
  end

  @spec format_row([cell()]) :: iolist()
  # A blank line
  defp format_row([]), do: []

  # A row with full width
  defp format_row([{label, formatted_iodata}]) do
    :io_lib.format("~-12ts : ~s", [label, formatted_iodata])
  end

  # A row with two columns
  defp format_row([col0, col1]) do
    [format_cell(col0, 0), format_cell(col1, 1)]
  end

  @spec format_cell(cell(), 0 | 1) :: iolist()
  defp format_cell({label, formatted_iodata}, column_index) do
    case column_index do
      0 -> "~-12ts : ~-24ts"
      _ -> "~-12ts : ~s"
    end
    |> :io_lib.format([label, formatted_iodata])
  end

  defp format_cell({label, formatted_iodata, :green}, column_index) do
    [
      :io_lib.format("~-12ts : ", [label]),
      IO.ANSI.green(),
      case column_index do
        0 -> "~-24ts"
        _ -> "~s"
      end
      |> :io_lib.format([formatted_iodata]),
      IO.ANSI.reset()
    ]
  end

  defp format_cell({label, formatted_iodata, :red}, column_index) do
    [
      :io_lib.format("~-12ts : ", [label]),
      IO.ANSI.red(),
      case column_index do
        0 -> "~-24ts"
        _ -> "~s"
      end
      |> :io_lib.format([formatted_iodata]),
      IO.ANSI.reset()
    ]
  end

  @spec firmware_cell() :: cell()
  defp firmware_cell() do
    fw_active = Nerves.Runtime.KV.get("nerves_fw_active") |> String.upcase()

    if runtime_mod().firmware_valid?() do
      {"Firmware", :io_lib.format("Valid (~s)", [fw_active]), :green}
    else
      {"Firmware", :io_lib.format("Not validated (~s)", [fw_active]), :red}
    end
  end

  @spec applications_cell() :: cell()
  defp applications_cell() do
    apps = runtime_mod().applications()
    started_count = length(apps[:started])
    loaded_count = length(apps[:loaded])

    if started_count == loaded_count do
      {"Applications", :io_lib.format("~p / ~p", [started_count, loaded_count]), :green}
    else
      not_started = Enum.join(apps[:loaded] -- apps[:started], ", ")

      {
        "Applications",
        :io_lib.format("~p / ~p (~s not started)", [started_count, loaded_count, not_started]),
        :red
      }
    end
  end

  @spec memory_usage_cell() :: cell()
  defp memory_usage_cell() do
    [memory_usage_total, memory_usage_used | _] = runtime_mod().memory_usage()
    percentage = round(memory_usage_used / memory_usage_total * 100)
    text = :io_lib.format("~p MB (~p%)", [div(memory_usage_used, 1000), percentage])

    if percentage < 85 do
      {"Memory usage", text}
    else
      {"Memory usage", text, :red}
    end
  end

  @spec uname() :: iolist()
  defp uname() do
    fw_architecture = Nerves.Runtime.KV.get_active("nerves_fw_architecture")
    fw_platform = Nerves.Runtime.KV.get_active("nerves_fw_platform")
    fw_product = Nerves.Runtime.KV.get_active("nerves_fw_product")
    fw_version = Nerves.Runtime.KV.get_active("nerves_fw_version")
    fw_uuid = Nerves.Runtime.KV.get_active("nerves_fw_uuid")
    [fw_product, " ", fw_version, " (", fw_uuid, ") ", fw_architecture, " ", fw_platform]
  end

  # https://github.com/erlang/otp/blob/1c63b200a677ec7ac12202ddbcf7710884b16ff2/lib/stdlib/src/c.erl#L1118
  @spec uptime() :: iolist()
  defp uptime() do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~p days, ", [d])
    hours = if d + h > 0, do: :io_lib.format("~p hours, ", [h])
    minutes = if d + h + m > 0, do: :io_lib.format("~p minutes and ", [m])
    seconds = :io_lib.format("~p seconds", [s])
    Enum.reject([days, hours, minutes, seconds], &is_nil/1)
  end

  @spec clock() :: [binary(), ...]
  defp clock() do
    [
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.trim_trailing("Z"),
      " UTC"
    ]
  end

  @spec network_names() :: String.t()
  defp network_names() do
    case :inet.getifaddrs() do
      {:ok, list} -> list |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")
      _ -> ""
    end
  end

  @spec load_average() :: iolist()
  defp load_average() do
    case runtime_mod().load_average() do
      [a, b, c | _] -> [a, " ", b, " ", c]
      _ -> "error"
    end
  end

  @spec hostname() :: [byte()]
  defp hostname() do
    :inet.gethostname() |> elem(1)
  end

  @spec runtime_mod() :: atom()
  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
