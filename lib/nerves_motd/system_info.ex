defmodule NervesMOTD.SystemInfo do
  @moduledoc false

  @doc """
  Create a comma-separated list of IP addresses

  ## Example:

      iex> if_addresses = [
      ...>   {{10, 0, 0, 202}, {255, 255, 255, 0}},
      ...>   {{65152, 0, 0, 0, 47655, 60415, 65227, 8746}, {65535, 65535, 65535, 65535, 0, 0, 0, 0}}
      ...> ]
      iex> join_ip_addresses(if_addresses, ", ")
      ["10.0.0.202/24", ", ", "fe80::ba27:ebff:fecb:222a/64"]
  """
  @spec join_ip_addresses(list(), String.t()) :: iolist()
  def join_ip_addresses(addresses, sep) do
    addresses
    |> Enum.map(&ip_address_tuple_to_string/1)
    |> Enum.intersperse(sep)
  end

  @doc """
  Extract IP addresses for one interface returned by `:inet.getifaddrs/0`

  ## Example:

      iex> if_addresses = [
      ...>   flags: [:up, :broadcast, :running, :multicast],
      ...>   addr: {10, 0, 0, 202},
      ...>   netmask: {255, 255, 255, 0},
      ...>   broadaddr: {10, 0, 0, 202},
      ...>   addr: {65152, 0, 0, 0, 47655, 60415, 65227, 8746},
      ...>   netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0},
      ...>   hwaddr: [184, 39, 235, 203, 34, 42]
      ...> ]
      iex> extract_ifaddr_addresses(if_addresses)
      [
        {{10, 0, 0, 202}, {255, 255, 255, 0}},
        {{65152, 0, 0, 0, 47655, 60415, 65227, 8746}, {65535, 65535, 65535, 65535, 0, 0, 0, 0}}
      ]
  """
  @spec extract_ifaddr_addresses(keyword()) :: [String.t()]
  def extract_ifaddr_addresses(kv_pairs, acc \\ [])

  def extract_ifaddr_addresses([], acc), do: Enum.reverse(acc)

  def extract_ifaddr_addresses([{:addr, addr}, {:netmask, netmask} | rest], acc) do
    extract_ifaddr_addresses(rest, [{addr, netmask} | acc])
  end

  def extract_ifaddr_addresses([_other | rest], acc) do
    extract_ifaddr_addresses(rest, acc)
  end

  @doc """
  Convert an IP address and subnet mask to a nice string

  Examples:

      iex> ip_address_tuple_to_string({{10, 0, 0, 202}, {255, 255, 255, 0}})
      "10.0.0.202/24"
      iex> ip_address_tuple_to_string({{65152, 0, 0, 0, 47655, 60415, 65227, 8746}, {65535, 65535, 65535, 65535, 0, 0, 0, 0}})
      "fe80::ba27:ebff:fecb:222a/64"

  """
  @spec ip_address_tuple_to_string({:inet.ip_address(), :inet.ip_address()}) :: String.t()
  def ip_address_tuple_to_string({address, mask}) do
    "#{:inet.ntoa(address)}/#{subnet_mask_to_prefix(mask)}"
  end

  @doc """
  Convert a subnet mask tuple to a prefix length

  Examples:

      iex> subnet_mask_to_prefix({255, 255, 255, 0})
      24

      iex> subnet_mask_to_prefix({65535, 65535, 65535, 65535, 0, 0, 0, 0})
      64
  """
  @spec subnet_mask_to_prefix(:inet.ip_address()) :: 0..128
  def subnet_mask_to_prefix(address) do
    address |> ip_to_binary() |> leading_ones(0)
  end

  defp ip_to_binary({a, b, c, d}), do: <<a, b, c, d>>

  defp ip_to_binary({a, b, c, d, e, f, g, h}),
    do: <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>

  defp leading_ones(<<0b11111111, rest::binary>>, sum), do: leading_ones(rest, sum + 8)
  defp leading_ones(<<0b11111110, _rest::binary>>, sum), do: sum + 7
  defp leading_ones(<<0b11111100, _rest::binary>>, sum), do: sum + 6
  defp leading_ones(<<0b11111000, _rest::binary>>, sum), do: sum + 5
  defp leading_ones(<<0b11110000, _rest::binary>>, sum), do: sum + 4
  defp leading_ones(<<0b11100000, _rest::binary>>, sum), do: sum + 3
  defp leading_ones(<<0b11000000, _rest::binary>>, sum), do: sum + 2
  defp leading_ones(<<0b10000000, _rest::binary>>, sum), do: sum + 1
  defp leading_ones(_, sum), do: sum

  if Version.match?(System.version(), ">= 1.11.0") and Code.ensure_loaded?(NervesTimeZones) do
    # NervesTimeZones and Calendar.strftime require Elixir 1.11
    @spec clock_text() :: binary()
    def clock_text() do
      # NervesTimeZones is an optional dependency so make sure its started
      {:ok, _} = Application.ensure_all_started(:nerves_time_zones)

      NervesTimeZones.get_time_zone()
      |> DateTime.now!()
      |> DateTime.truncate(:second)
      |> Calendar.strftime("%c %Z")
    end
  else
    @spec clock_text() :: binary()
    def clock_text() do
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)
      |> NaiveDateTime.to_string()
      |> Kernel.<>(" UTC")
    end
  end

  # https://github.com/erlang/otp/blob/1c63b200a677ec7ac12202ddbcf7710884b16ff2/lib/stdlib/src/c.erl#L1118
  @spec uptime_text() :: iolist()
  def uptime_text() do
    {uptime, _} = :erlang.statistics(:wall_clock)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    days = if d > 0, do: :io_lib.format("~p days, ", [d])
    hours = if d + h > 0, do: :io_lib.format("~p hours, ", [h])
    minutes = if d + h + m > 0, do: :io_lib.format("~p minutes and ", [m])
    seconds = :io_lib.format("~p seconds", [s])
    Enum.reject([days, hours, minutes, seconds], &is_nil/1)
  end

  @spec cpu_temperature_text() :: [String.t()] | nil
  def cpu_temperature_text() do
    case runtime_mod().cpu_temperature() do
      {:ok, temperature_c} ->
        [:erlang.float_to_binary(temperature_c, decimals: 1), "°C"]

      _ ->
        nil
    end
  end

  @spec firmware_status_text() :: [String.t()]
  def firmware_status_text() do
    Nerves.Runtime.KV.get("nerves_fw_active")
    |> String.upcase()
    |> format_firmware_status(runtime_mod().firmware_valid?())
  end

  @spec format_firmware_status(String.t(), boolean()) :: IO.ANSI.ansidata()
  defp format_firmware_status(active_part, true = _validated) do
    [:green, "Valid (#{active_part})"]
  end

  defp format_firmware_status(active_part, false = _validated) do
    [:red, "Not validated (#{active_part})"]
  end

  @spec load_average_text() :: iodata()
  def load_average_text() do
    case runtime_mod().load_average() do
      [a, b, c | _] -> [a, " ", b, " ", c]
      _ -> "error"
    end
  end

  @spec hostname_text() :: [byte()]
  def hostname_text() do
    {:ok, value} = :inet.gethostname()
    value
  end

  @spec uname() :: iolist()
  def uname() do
    fw_architecture = Nerves.Runtime.KV.get_active("nerves_fw_architecture")
    fw_platform = Nerves.Runtime.KV.get_active("nerves_fw_platform")
    fw_product = Nerves.Runtime.KV.get_active("nerves_fw_product")
    fw_version = Nerves.Runtime.KV.get_active("nerves_fw_version")
    fw_uuid = Nerves.Runtime.KV.get_active("nerves_fw_uuid")
    [fw_product, " ", fw_version, " (", fw_uuid, ") ", fw_architecture, " ", fw_platform]
  end

  @spec applications_text(%{loaded: list(), started: list()}) :: IO.ANSI.ansidata()
  def applications_text(%{loaded: loaded_apps, started: started_apps}) do
    loaded_count = length(loaded_apps)
    started_count = length(started_apps)

    if started_count == loaded_count do
      "#{started_count} started"
    else
      not_started_apps = Enum.join(loaded_apps -- started_apps, ", ")
      [:yellow, "#{started_count} started (#{not_started_apps} not started)"]
    end
  end

  @spec active_part_usage_text() :: IO.ANSI.ansidata()
  def active_part_usage_text() do
    app_partition_path = Nerves.Runtime.KV.get_active("nerves_fw_application_part0_devpath")

    with true <- devpath_specified?(app_partition_path),
         {:ok, stats} <- runtime_mod().filesystem_stats(app_partition_path) do
      formatted = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

      if stats.used_percent < 85 do
        formatted
      else
        [:red, formatted]
      end
    else
      _ ->
        [:red, "not available"]
    end
  end

  defp devpath_specified?(nil), do: false
  defp devpath_specified?(""), do: false
  defp devpath_specified?(path) when is_binary(path), do: true

  @spec memory_usage_text() :: IO.ANSI.ansidata()
  def memory_usage_text() do
    case runtime_mod().memory_stats() do
      {:ok, stats} ->
        formatted = :io_lib.format("~p MB (~p%)", [stats.used_mb, stats.used_percent])

        if stats.used_percent < 85 do
          formatted
        else
          [:red, formatted]
        end

      :error ->
        [:red, "not available"]
    end
  end

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
