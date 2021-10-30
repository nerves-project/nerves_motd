defmodule NervesMOTD do
  @moduledoc """
  `NervesMOTD` prints a "message of the day" on Nerves devices.

  To use, add `NervesMOTD.print()` to the `rootfs_overlay/etc/iex.exs` file in
  your Nerves project.
  """

  @logo """
  \e[38;5;24m████▄▄    \e[38;5;74m▐███
  \e[38;5;24m█▌  ▀▀██▄▄  \e[38;5;74m▐█
  \e[38;5;24m█▌  \e[38;5;74m▄▄  \e[38;5;24m▀▀  \e[38;5;74m▐█   \e[39mN  E  R  V  E  S
  \e[38;5;24m█▌  \e[38;5;74m▀▀██▄▄  ▐█
  \e[38;5;24m███▌    \e[38;5;74m▀▀████\e[0m
  """

  alias NervesMOTD.Utils

  @excluded_ifnames ['lo', 'lo0']

  @typedoc """
  MOTD options
  """
  @type option() :: {:logo, iodata()}

  @typep cell() :: {String.t(), IO.ANSI.ansidata()}

  @doc """
  Print the message of the day

  Options:

  * `:logo` - a custom logo to display instead of the default Nerves logo. Pass
    an empty logo (`""`) to remove it completely.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    {:ok, _} = Application.ensure_all_started(:nerves_runtime)

    [
      logo(opts),
      uname(),
      "\n",
      Enum.map(rows(), &format_row/1),
      "\n",
      """
      Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
      """
    ]
    |> IO.ANSI.format()
    |> IO.puts()
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
      [memory_usage_cell(), active_application_partition_cell()],
      [{"Hostname", hostname()}, {"Load average", load_average()}],
      []
    ] ++ ip_address_rows()
  end

  @spec format_row([cell()]) :: iolist()
  # A blank line
  defp format_row([]), do: ["\n"]

  # A row with full width
  defp format_row([{label, value}]) do
    ["  ", format_cell_label(label), " : ", value, "\n", :reset]
  end

  # A row with two columns
  defp format_row([col0, col1]) do
    ["  ", format_cell(col0, 0), format_cell(col1, 1), "\n"]
  end

  @spec format_cell(cell(), 0 | 1) :: IO.ANSI.ansidata()
  defp format_cell({label, value}, column_index) do
    [format_cell_label(label), " : ", format_cell_value(value, column_index, 24), :reset]
  end

  @spec format_cell_label(IO.ANSI.ansidata()) :: IO.ANSI.ansidata()
  defp format_cell_label(label), do: Utils.fit_ansidata(label, 12)

  @spec format_cell_value(IO.ANSI.ansidata(), 0 | 1, pos_integer()) :: IO.ANSI.ansidata()
  defp format_cell_value(value, 0, width), do: Utils.fit_ansidata(value, width)
  defp format_cell_value(value, 1, _width), do: value

  @spec firmware_cell() :: cell()
  defp firmware_cell() do
    fw_active = Nerves.Runtime.KV.get("nerves_fw_active") |> String.upcase()

    if runtime_mod().firmware_valid?() do
      {"Firmware", [:green, "Valid (#{fw_active})"]}
    else
      {"Firmware", [:red, "Not validated (#{fw_active})"]}
    end
  end

  @spec applications_cell() :: cell()
  defp applications_cell() do
    apps = runtime_mod().applications()
    started_count = length(apps[:started])
    loaded_count = length(apps[:loaded])

    if started_count == loaded_count do
      {"Applications", "#{started_count} started"}
    else
      not_started = Enum.join(apps[:loaded] -- apps[:started], ", ")
      {"Applications", [:yellow, "#{started_count} started (#{not_started} not started)"]}
    end
  end

  @spec memory_usage_cell() :: cell()
  defp memory_usage_cell() do
    case runtime_mod().memory_stats() do
      {:ok, stats} ->
        text = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

        if stats.used_percent < 85 do
          {"Memory usage", text}
        else
          {"Memory usage", [:red, text]}
        end

      :error ->
        {"Memory usage", [:red, "not available"]}
    end
  end

  @spec active_application_partition_cell() :: cell()
  defp active_application_partition_cell() do
    app_partition_path = Nerves.Runtime.KV.get_active("nerves_fw_application_part0_devpath")

    case runtime_mod().filesystem_stats(app_partition_path) do
      {:ok, stats} ->
        text = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

        if stats.used_percent < 85 do
          {"Part usage", text}
        else
          {"Part usage", [:red, text]}
        end

      :error ->
        {"Part usage", [:red, "not available"]}
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

  @spec clock() :: binary() | [binary()]
  defp clock() do
    local_time(NervesTimeZones) || local_time(NaiveDateTime) || utc_time()
  end

  # 2021-10-30 11:50:09-04:00 EDT America/New_York
  defp local_time(NervesTimeZones) do
    case Code.ensure_loaded(NervesTimeZones) do
      {:module, mod} ->
        mod.get_time_zone()
        |> DateTime.now!()
        |> DateTime.truncate(:second)
        |> DateTime.to_string()

      _ ->
        nil
    end
  end

  # 2021-10-30 11:49:44-0400 EDT
  defp local_time(NaiveDateTime) do
    if Version.match?(System.version(), "~> 1.10") do
      case Code.ensure_loaded(NaiveDateTime) do
        {:module, mod} ->
          [
            mod.local_now()
            |> NaiveDateTime.truncate(:second)
            |> NaiveDateTime.to_string(),
            system_time_zone_name()
          ]

        _ ->
          nil
      end
    end
  end

  # 2021-10-30 15:49:30+0000 UTC
  defp utc_time() do
    [
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.trim_trailing("Z"),
      "+0000 UTC"
    ]
  end

  defp system_time_zone_name() do
    # -0400 EDT
    case System.cmd("date", ["+%z %Z"]) do
      {tz_str, 0} -> tz_str |> String.trim()
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

  @spec ip_address_rows() :: [[cell()]]
  defp ip_address_rows() do
    {:ok, if_addresses} = :inet.getifaddrs()

    if_addresses
    |> Enum.map(&ip_address_row/1)
    |> Enum.reject(fn row -> row == [] end)
  end

  @spec ip_address_row({charlist(), keyword()}) :: [cell()]
  defp ip_address_row({name, ifaddrs}) when name not in @excluded_ifnames do
    case Utils.extract_ifaddr_addresses(ifaddrs) do
      [] ->
        # Skip interfaces without addresses
        []

      addresses ->
        # Create a comma-separated list of IP addresses
        formatted_list =
          addresses
          |> Enum.map(&Utils.ip_address_mask_to_string/1)
          |> Enum.intersperse(", ")

        [{name, formatted_list}]
    end
  end

  defp ip_address_row(_), do: []

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
