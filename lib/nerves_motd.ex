defmodule NervesMOTD do
  @moduledoc """
  Documentation for `NervesMOTD`.
  """

  @spec print :: :ok
  def print(opts \\ []) do
    show_logo = Keyword.get(opts, :logo, true)

    fmt_col_fun = fn str -> String.pad_trailing(str, 20, " ") end

    applications_text =
      "#{length(Application.started_applications())} / #{length(Application.loaded_applications())}"

    firmware_text = "#{validate_firmware()} (#{String.upcase(fw_active())})"

    networks_text = network_names() |> Enum.join(", ")

    [memory_usage_total, memory_usage_used | _] = memory_usage()

    memory_usage_text =
      "#{memory_usage_used} kB (#{trunc(memory_usage_used / memory_usage_total * 100)}%)"

    hostname_text = :inet.gethostname() |> elem(1) |> to_string()

    load_average_text = load_average()

    if show_logo do
      IO.puts("""
      \e[34m████▄▖    \e[36m▐███
      \e[34m█▌  ▀▜█▙▄▖  \e[36m▐█
      \e[34m█▌ \e[36m▐█▄▖\e[34m▝▀█▌ \e[36m▐█   \e[39mN  E  R  V  E  S
      \e[34m█▌   \e[36m▝▀█▙▄▖ ▐█
      \e[34m███▌    \e[36m▀▜████\e[0m
      """)
    end

    IO.puts("""
    #{fw_product()} #{fw_version()} (#{fw_uuid()}) #{fw_architecture()}

      Uptime : #{uptime()}
      Clock  : #{clock()}

      Firmware     : #{fmt_col_fun.(firmware_text)}\tMemory usage : #{fmt_col_fun.(memory_usage_text)}
      Applications : #{fmt_col_fun.(applications_text)}\tLoad average : #{fmt_col_fun.(load_average_text)}
      Hostname     : #{fmt_col_fun.(hostname_text)}\tNetworks     : #{fmt_col_fun.(networks_text)}

    Nerves CLI help: https://hexdocs.pm/nerves/nerves_cli.html
    """)
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
    runtime_kv_mod().get("nerves_fw_active")
  end

  @spec fw_architecture :: binary
  def fw_architecture do
    runtime_kv_mod().get_active("nerves_fw_architecture")
  end

  @spec fw_platform :: binary
  def fw_platform do
    runtime_kv_mod().get_active("nerves_fw_platform")
  end

  @spec fw_product :: binary
  def fw_product do
    runtime_kv_mod().get_active("nerves_fw_product")
  end

  @spec fw_version :: binary
  def fw_version do
    runtime_kv_mod().get_active("nerves_fw_version")
  end

  @spec fw_uuid :: binary
  def fw_uuid do
    runtime_kv_mod().get_active("nerves_fw_uuid")
  end

  @spec validate_firmware :: :ok | any
  def validate_firmware do
    runtime_mod().validate_firmware()
  catch
    :error, :undef ->
      # Fall back to the old Nerves way
      case System.cmd("fw_setenv", ["nerves_fw_validated", "1"]) do
        {_, 0} -> :ok
        {reason, _} -> reason
      end
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
    [_total, _used, _free, _shared, _buff, _available] = linux_mod().memory_usage()
  end

  @spec load_average :: binary
  def load_average do
    linux_mod().load_average()
  end

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Prod)
  end

  defp runtime_kv_mod() do
    Application.get_env(:nerves_motd, :runtime_kv_mod, NervesMOTD.RuntimeKV.Prod)
  end

  defp linux_mod() do
    Application.get_env(:nerves_motd, :linux_mod, NervesMOTD.Linux.Prod)
  end
end
