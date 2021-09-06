defmodule NervesMOTD do
  @moduledoc """
  `NervesMOTD` prints a "message of the day" (MOTD) for Nerves-based projects.
  """

  @logo """
  \e[34m████▄▖    \e[36m▐███
  \e[34m█▌  ▀▜█▙▄▖  \e[36m▐█
  \e[34m█▌ \e[36m▐█▄▖\e[34m▝▀█▌ \e[36m▐█   \e[39mN  E  R  V  E  S
  \e[34m█▌   \e[36m▝▀█▙▄▖ ▐█
  \e[34m███▌    \e[36m▀▜████\e[0m
  """

  @spec print :: :ok
  def print(opts \\ []) do
    logo = Keyword.get(opts, :logo, @logo)

    fw_architecture = Nerves.Runtime.KV.get_active("nerves_fw_architecture")
    fw_platform = Nerves.Runtime.KV.get_active("nerves_fw_platform")
    fw_product = Nerves.Runtime.KV.get_active("nerves_fw_product")
    fw_version = Nerves.Runtime.KV.get_active("nerves_fw_version")
    fw_uuid = Nerves.Runtime.KV.get_active("nerves_fw_uuid")

    if logo, do: IO.puts(logo)

    IO.puts("""
    #{fw_product} #{fw_version} (#{fw_uuid}) #{fw_architecture} #{fw_platform}

      Uptime : #{uptime()}
      Clock  : #{clock()}

      Firmware     : #{String.pad_trailing(firmware_text(), 20, " ")}\tMemory usage : #{memory_usage_text()}
      Applications : #{String.pad_trailing(application_text(), 20, " ")}\tLoad average : #{load_average()}
      Hostname     : #{String.pad_trailing(hostname_text(), 20, " ")}\tNetworks     : #{networks_text()}

    Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
    """)
  end

  defp firmware_text do
    fw_active = Nerves.Runtime.KV.get("nerves_fw_active") |> String.upcase()

    if firmware_valid?() do
      IO.ANSI.green() <> "Valid (#{fw_active})"
    else
      IO.ANSI.red() <> "Invalid (#{fw_active})"
    end <> IO.ANSI.reset()
  end

  defp application_text do
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

  defp hostname_text do
    # Use "\e[0m" as a placeholder for consistent white spaces.
    IO.ANSI.reset() <> hostname() <> IO.ANSI.reset()
  end

  defp memory_usage_text do
    [memory_usage_total, memory_usage_used | _] = memory_usage()
    percentage = trunc(memory_usage_used / memory_usage_total * 100)

    if(percentage < 85, do: IO.ANSI.reset(), else: IO.ANSI.red()) <>
      "#{div(memory_usage_used, 1000)} MB (#{percentage}%)" <>
      IO.ANSI.reset()
  end

  defp networks_text do
    Enum.join(network_names(), ", ")
  end

  # https://github.com/erlang/otp/blob/1c63b200a677ec7ac12202ddbcf7710884b16ff2/lib/stdlib/src/c.erl#L1118
  @spec uptime :: binary
  defp uptime do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~p days, ", [d])
    hours = if d + h > 0, do: :io_lib.format("~p hours, ", [h])
    minutes = if d + h + m > 0, do: :io_lib.format("~p minutes and ", [m])
    seconds = :io_lib.format("~p seconds", [s])
    [days, hours, minutes, seconds] |> Enum.filter(fn x -> x end) |> List.to_string()
  end

  @spec clock :: binary
  defp clock do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
    |> String.trim_trailing("Z")
    |> Kernel.<>(" UTC")
  end

  @spec firmware_valid? :: boolean
  defp firmware_valid? do
    runtime_mod().firmware_valid?()
  end

  @spec network_names :: list
  defp network_names do
    case :inet.getifaddrs() do
      {:ok, list} -> list |> Enum.map(&elem(&1, 0))
      _ -> []
    end
  end

  @spec memory_usage :: [integer]
  defp memory_usage do
    [_total, _used, _free, _shared, _buff, _available] = runtime_mod().memory_usage()
  end

  @spec load_average :: binary
  defp load_average do
    runtime_mod().load_average()
  end

  @spec hostname :: binary
  defp hostname do
    :inet.gethostname() |> elem(1) |> to_string()
  end

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
