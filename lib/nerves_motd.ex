# SPDX-FileCopyrightText: 2021 Ace Yanagida
# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
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

  alias Nerves.Runtime.KV
  alias NervesMOTD.Utils

  @excluded_ifnames [~c"lo", ~c"lo0"]

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
  * `:extra_rows` - a list of custom rows or a callback for returning rows.
    The callback can be a 0-arity function reference or MFArgs tuple.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    combined_opts = Application.get_all_env(:nerves_motd) |> Keyword.merge(opts)
    apps = runtime_mod().applications()

    if ready?(apps) do
      [
        logo(combined_opts),
        :reset,
        uname(),
        "\n\n",
        Tablet.render(info(opts),
          column_widths: %{key: 14, value: :expand},
          wrap_across: 2,
          wrap_direction: :horizontal,
          style: :kv
        ),
        "\n",
        """
        Nerves CLI help: https://hexdocs.pm/nerves/iex-with-nerves.html
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

  defp info(opts) do
    blank = %{key: "", value: ""}

    [
      %{key: "Serial", value: serial_number()},
      %{key: "CPU Temp", value: temperature()},
      %{key: "Uptime", value: uptime()},
      %{key: "Clock", value: clock()},
      blank,
      blank,
      %{key: "Firmware", value: firmware_slot()},
      %{key: "Applications", value: applications(runtime_mod().applications())},
      %{key: "Memory usage", value: memory_usage()},
      %{key: "Part usage", value: active_application_partition()},
      %{key: "Hostname", value: hostname()},
      %{key: "Load average", value: load_average()},
      blank,
      blank
    ] ++ ip_address_rows() ++ extra_rows(opts)
  end

  @spec extra_rows([option()]) :: IO.ANSI.ansidata()
  defp extra_rows(opts) do
    case opts[:extra_rows] do
      fun when is_function(fun, 0) -> fun.()
      {m, f, args} -> apply(m, f, args)
      rows when is_list(rows) -> rows
      _ -> []
    end
  catch
    err, msg ->
      [[{[:red, ":extra_rows failed"], ["failed (", inspect(err), ") - ", inspect(msg)]}]]
  end

  defp temperature() do
    case runtime_mod().cpu_temperature() do
      {:ok, temperature_c} -> [:erlang.float_to_binary(temperature_c, decimals: 1), "°C"]
      _ -> "Unavailable"
    end
  end

  defp clock() do
    if runtime_mod().time_synchronized?() do
      Utils.formatted_local_time()
    else
      [:yellow, Utils.formatted_local_time(), " (unsynchronized)", :default_color]
    end
  end

  defp firmware_slot() do
    fw_active = runtime_mod().active_partition()

    case runtime_mod().firmware_validity() do
      :valid -> [:green, "Valid (#{fw_active})", :default_color]
      :invalid -> [:red, "Not validated (#{fw_active})", :default_color]
      _ -> fw_active
    end
  end

  defp applications(apps) do
    started_count = length(apps[:started])
    loaded_count = length(apps[:loaded])

    if started_count == loaded_count do
      "#{started_count} started"
    else
      not_started = Enum.join(apps[:loaded] -- apps[:started], ", ")
      [:yellow, "#{started_count} started (#{not_started} not started)", :default_color]
    end
  end

  defp memory_usage() do
    case runtime_mod().memory_stats() do
      {:ok, stats} ->
        text = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

        if stats.used_percent < 85 do
          text
        else
          [:red, text, :default_color]
        end

      :error ->
        [:red, "not available", :default_color]
    end
  end

  defp active_application_partition() do
    app_partition_path = KV.get_active("nerves_fw_application_part0_devpath")

    with true <- devpath_specified?(app_partition_path),
         {:ok, stats} <- runtime_mod().filesystem_stats(app_partition_path) do
      text = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

      if stats.used_percent < 85 do
        text
      else
        [:red, text, :default_color]
      end
    else
      _ -> [:red, "not available", :default_color]
    end
  end

  defp devpath_specified?(nil), do: false
  defp devpath_specified?(""), do: false
  defp devpath_specified?(path) when is_binary(path), do: true

  @spec uname() :: IO.chardata()
  defp uname() do
    fw_architecture = KV.get_active("nerves_fw_architecture")
    fw_platform = KV.get_active("nerves_fw_platform")
    fw_product = KV.get_active("nerves_fw_product")
    fw_version = KV.get_active("nerves_fw_version")
    fw_uuid = KV.get_active("nerves_fw_uuid")
    [fw_product, " ", fw_version, " (", fw_uuid, ") ", fw_architecture, " ", fw_platform]
  end

  # https://github.com/erlang/otp/blob/1c63b200a677ec7ac12202ddbcf7710884b16ff2/lib/stdlib/src/c.erl#L1118
  @spec uptime() :: IO.chardata()
  defp uptime() do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~b days, ", [d]), else: []
    hours = if d + h > 0, do: :io_lib.format("~b hours, ", [h]), else: []
    minutes = if d + h + m > 0, do: :io_lib.format("~b minutes and ", [m]), else: []
    seconds = :io_lib.format("~b", [s])
    millis = if d + h + m == 0, do: :io_lib.format(".~3..0b", [rem(uptime, 1000)]), else: []

    [days, hours, minutes, seconds, millis, " seconds"]
  end

  @spec load_average() :: IO.chardata()
  defp load_average() do
    case runtime_mod().load_average() do
      [a, b, c | _] -> [a, " ", b, " ", c]
      _ -> "error"
    end
  end

  @spec serial_number() :: String.t()
  defp serial_number() do
    Nerves.Runtime.serial_number()
  end

  @spec hostname() :: [byte()]
  defp hostname() do
    {:ok, hostname} = :inet.gethostname()
    hostname
  end

  @spec ip_address_rows() :: [[cell()]]
  defp ip_address_rows() do
    {:ok, if_addresses} = :inet.getifaddrs()

    if_addresses
    |> Enum.flat_map(&ip_address_row/1)
    |> Enum.reject(fn row -> row == [] end)
    |> Enum.sort_by(& &1.key)
  end

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
          |> Enum.intersperse("\n")

        [%{key: name, value: formatted_list}]
    end
  end

  defp ip_address_row(_), do: []

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
