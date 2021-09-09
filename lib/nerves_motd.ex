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

  @doc """
  Print the message of the day

  Options:

  * `:logo` - a custom logo to display instead of the default Nerves logo. Pass
    an empty logo (`""`) to remove it completely.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    {:ok, _} = Application.ensure_all_started(:nerves_runtime)
    IO.puts(generate(opts))
  end

  defp generate(opts) do
    [
      logo_text(opts),
      uname(),
      """

        Uptime : #{uptime()}
        Clock  : #{clock()}

        Firmware     : #{String.pad_trailing(firmware_text(), 24, " ")}\tApplications : #{application_text()}
        Memory usage : #{String.pad_trailing(memory_usage_text(), 24, " ")}\tLoad average : #{load_average()}
        Hostname     : #{String.pad_trailing(hostname_text(), 24, " ")}\tNetworks     : #{networks_text()}

      Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
      """
    ]
  end

  defp logo_text(opts) do
    Keyword.get(opts, :logo, @logo)
  end

  defp firmware_text() do
    fw_active = Nerves.Runtime.KV.get("nerves_fw_active") |> String.upcase()

    if firmware_valid?() do
      IO.ANSI.green() <> "Valid (#{fw_active})"
    else
      IO.ANSI.red() <> "Not validated (#{fw_active})"
    end <> IO.ANSI.reset()
  end

  defp application_text() do
    apps = runtime_mod().applications()
    started_count = length(apps[:started])
    loaded_count = length(apps[:loaded])

    if started_count == loaded_count do
      IO.ANSI.green() <> "#{started_count} / #{loaded_count}"
    else
      apps_not_started = Enum.join(apps[:loaded] -- apps[:started], ", ")
      IO.ANSI.red() <> "#{started_count} / #{loaded_count} (#{apps_not_started} not started)"
    end <> IO.ANSI.reset()
  end

  defp hostname_text() do
    # Use "\e[0m" as a placeholder for consistent white spaces.
    IO.ANSI.reset() <> hostname() <> IO.ANSI.reset()
  end

  defp memory_usage_text() do
    [memory_usage_total, memory_usage_used | _] = runtime_mod().memory_usage()
    percentage = round(memory_usage_used / memory_usage_total * 100)

    if(percentage < 85, do: IO.ANSI.reset(), else: IO.ANSI.red()) <>
      "#{div(memory_usage_used, 1000)} MB (#{percentage}%)" <>
      IO.ANSI.reset()
  end

  defp networks_text() do
    Enum.join(network_names(), ", ")
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
  @spec uptime() :: String.t()
  defp uptime() do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~p days, ", [d])
    hours = if d + h > 0, do: :io_lib.format("~p hours, ", [h])
    minutes = if d + h + m > 0, do: :io_lib.format("~p minutes and ", [m])
    seconds = :io_lib.format("~p seconds", [s])
    [days, hours, minutes, seconds] |> Enum.filter(fn x -> x end) |> List.to_string()
  end

  @spec clock() :: String.t()
  defp clock() do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
    |> String.trim_trailing("Z")
    |> Kernel.<>(" UTC")
  end

  @spec firmware_valid?() :: boolean()
  defp firmware_valid?() do
    runtime_mod().firmware_valid?()
  end

  @spec network_names() :: list()
  defp network_names() do
    case :inet.getifaddrs() do
      {:ok, list} -> list |> Enum.map(&elem(&1, 0))
      _ -> []
    end
  end

  @spec load_average() :: iodata()
  defp load_average() do
    case runtime_mod().load_average() do
      [a, b, c | _] -> [a, " ", b, " ", c]
      _ -> "error"
    end
  end

  @spec hostname() :: String.t()
  defp hostname() do
    :inet.gethostname() |> elem(1) |> to_string()
  end

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
