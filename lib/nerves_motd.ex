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
    show_logo = Keyword.get(opts, :logo, true)

    if show_logo, do: IO.puts(@logo)

    IO.puts("""
    #{fw_product()} #{fw_version()} (#{fw_uuid()}) #{fw_architecture()}

      Uptime : #{uptime()}
      Clock  : #{clock()}

      Firmware     : #{String.pad_trailing(firmware_text(), 20, " ")}\tMemory usage : #{memory_usage_text()}
      Applications : #{String.pad_trailing(application_text(), 20, " ")}\tLoad average : #{load_average_text()}
      Hostname     : #{String.pad_trailing(hostname_text(), 20, " ")}\tNetworks     : #{networks_text()}

    Nerves CLI help: https://hexdocs.pm/nerves/using-the-cli.html
    """)
  end

  defp firmware_text do
    if(firmware_valid?(),
      do: IO.ANSI.green() <> "Valid (#{String.upcase(fw_active())})",
      else: IO.ANSI.red() <> "Invalid (#{String.upcase(fw_active())})"
    ) <> IO.ANSI.reset()
  end

  defp application_text do
    started = length(Application.started_applications())
    loaded = length(Application.loaded_applications())

    if(started == loaded, do: IO.ANSI.green(), else: IO.ANSI.red()) <>
      "#{length(Application.started_applications())} / #{length(Application.loaded_applications())}" <>
      IO.ANSI.reset()
  end

  defp hostname_text do
    # Use "\e[0m" as a placeholder for consistent white spaces.
    IO.ANSI.reset() <> hostname() <> IO.ANSI.reset()
  end

  defp memory_usage_text do
    [memory_usage_total, memory_usage_used | _] = memory_usage()

    "#{memory_usage_used} kB (#{trunc(memory_usage_used / memory_usage_total * 100)}%)"
  end

  defp load_average_text do
    load_average()
  end

  defp networks_text do
    Enum.join(network_names(), ", ")
  end

  # https://github.com/erlang/otp/blob/1c63b200a677ec7ac12202ddbcf7710884b16ff2/lib/stdlib/src/c.erl#L1118
  @spec uptime :: binary
  def uptime do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~p days, ", [d])
    hours = if d + h > 0, do: :io_lib.format("~p hours, ", [h])
    minutes = if d + h + m > 0, do: :io_lib.format("~p minutes and ", [m])
    seconds = :io_lib.format("~p seconds", [s])
    [days, hours, minutes, seconds] |> Enum.filter(fn x -> x end) |> List.to_string()
  end

  @spec clock :: binary
  def clock do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
    |> String.trim_trailing("Z")
    |> Kernel.<>(" UTC")
  end

  @spec fw_active :: binary
  def fw_active do
    Nerves.Runtime.KV.get("nerves_fw_active")
  end

  @spec fw_architecture :: binary
  def fw_architecture do
    Nerves.Runtime.KV.get_active("nerves_fw_architecture")
  end

  @spec fw_platform :: binary
  def fw_platform do
    Nerves.Runtime.KV.get_active("nerves_fw_platform")
  end

  @spec fw_product :: binary
  def fw_product do
    Nerves.Runtime.KV.get_active("nerves_fw_product")
  end

  @spec fw_version :: binary
  def fw_version do
    Nerves.Runtime.KV.get_active("nerves_fw_version")
  end

  @spec fw_uuid :: binary
  def fw_uuid do
    Nerves.Runtime.KV.get_active("nerves_fw_uuid")
  end

  @spec firmware_valid? :: boolean
  def firmware_valid? do
    runtime_mod().firmware_valid?()
  end

  @spec network_names :: list
  def network_names do
    case :inet.getifaddrs() do
      {:ok, list} -> list |> Enum.map(&elem(&1, 0))
      _ -> []
    end
  end

  @spec memory_usage :: [integer]
  def memory_usage do
    [_total, _used, _free, _shared, _buff, _available] = runtime_mod().memory_usage()
  end

  @spec load_average :: binary
  def load_average do
    runtime_mod().load_average()
  end

  @spec hostname :: binary
  def hostname do
    :inet.gethostname() |> elem(1) |> to_string()
  end

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
