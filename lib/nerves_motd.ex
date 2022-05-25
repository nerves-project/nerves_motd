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
  @type option() :: {:logo, IO.ANSI.ansidata()} | {:extra_rows, [row()]}

  @typedoc """
  One row of information

  A row may contain 0, 1 or 2 cells.
  """
  @type row() :: [cell()]

  @typedoc """
  A label and value
  """
  @type cell() :: {String.t(), IO.ANSI.ansidata()}

  @doc """
  Print the message of the day

  This uses the Nerves.Runtime library. In the unlikely event that it's not
  available, it assumes the system isn't ready and doesn't print the MOTD.

  Options:

  * `:logo` - a custom logo to display instead of the default Nerves logo. Pass
    an empty logo (`""`) to remove it completely.
  * `:extra_rows` - custom rows that append to the end of the MOTD.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    apps = runtime_mod().applications()

    if ready?(apps) do
      [
        logo(opts),
        IO.ANSI.reset(),
        uname(),
        "\n",
        Enum.map(rows(apps, opts), &format_row/1),
        "\n",
        """
        Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
        """
      ]
      |> IO.ANSI.format()
      |> IO.puts()
    end

    :ok
  rescue
    error -> IO.puts("Could not print MOTD: #{inspect(error)}")
  end

  defp ready?(apps), do: :nerves_runtime in apps.started

  @spec logo([option()]) :: IO.ANSI.ansidata()
  defp logo(opts) do
    Keyword.get(opts, :logo, @logo)
  end

  @spec rows(map(), list()) :: [[cell()]]
  defp rows(apps, opts) do
    [
      [{"Uptime", uptime()}],
      [{"Clock", Utils.formatted_local_time()}],
      [],
      [firmware_cell(), applications_cell(apps)],
      [memory_usage_cell(), active_application_partition_cell()],
      [{"Hostname", hostname()}, {"Load average", load_average()}],
      []
    ] ++
      ip_address_rows() ++
      Keyword.get(opts, :extra_rows, [])
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

  @spec applications_cell(%{loaded: list(), started: list()}) :: cell()
  defp applications_cell(apps) do
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
    label = "Part usage"
    app_partition_path = Nerves.Runtime.KV.get_active("nerves_fw_application_part0_devpath")

    with true <- devpath_specified?(app_partition_path),
         {:ok, stats} <- runtime_mod().filesystem_stats(app_partition_path) do
      text = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

      if stats.used_percent < 85 do
        {label, text}
      else
        {label, [:red, text]}
      end
    else
      _ ->
        {label, [:red, "not available"]}
    end
  end

  defp devpath_specified?(nil), do: false
  defp devpath_specified?(""), do: false
  defp devpath_specified?(path) when is_binary(path), do: true

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

  @spec load_average() :: iodata()
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
