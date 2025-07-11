# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2025 Marc Lainez
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesMOTD.Runtime do
  @moduledoc false
  alias Nerves.Runtime.KV
  @excluded_ifnames [~c"lo", ~c"lo0"]

  def data() do
    %{
      applications: applications(),
      cpu_temperature: cpu_temperature(),
      active_partition: active_partition(),
      firmware_status: firmware_status(),
      uptime: uptime(),
      serial_number: serial_number(),
      hostname: hostname(),
      io_statistics: io_statistics(),
      ip_addresses: ip_addresses(),
      time_synchronized?: time_synchronized?(),
      cpu_sup: cpu_sup(),
      memsup: memsup(),
      disksup: disksup()
    }
  end

  def active_partition() do
    case KV.get("nerves_fw_active") do
      nil -> "unknown"
      partition -> String.upcase(partition)
    end
  end

  defp applications() do
    started = Enum.map(Application.started_applications(), &elem(&1, 0))
    loaded = Enum.map(Application.loaded_applications(), &elem(&1, 0))

    %{started: started, loaded: loaded}
  end

  defp cpu_temperature() do
    # Read the file /sys/class/thermal/thermal_zone0/temp which
    # has the CPU temperature in millidegree Celsius.
    read_int("/sys/class/thermal/thermal_zone0/temp") / 1000
  end

  defp firmware_status() do
    if Nerves.Runtime.firmware_valid?(), do: :valid, else: :invalid
  end

  defp io_statistics() do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    %{input: input, output: output}
  end

  defp uptime() do
    {total, _last_call} = :erlang.statistics(:wall_clock)
    div(total, 1000)
  end

  defp serial_number() do
    Nerves.Runtime.serial_number()
  end

  defp hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  case Code.ensure_compiled(NervesTime) do
    {:module, _} ->
      def time_synchronized?(), do: NervesTime.synchronized?()

    _ ->
      def time_synchronized?(), do: true
  end

  defp cpu_sup() do
    _ = :cpu_sup.util()
    Process.sleep(100)
    {cpus, busy, non_busy, _misc} = :cpu_sup.util([:detailed])
    cpu_count = length(cpus)

    %{
      cpu_count: cpu_count,
      busy: busy,
      non_busy: non_busy,
      speed_mhz: round(cpu_speed_khz() / 1000),
      load_avg1: :cpu_sup.avg1() / 256,
      load_avg5: :cpu_sup.avg5() / 256,
      load_avg15: :cpu_sup.avg15() / 256
    }
  end

  def cpu_speed_khz() do
    Path.wildcard("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")
    |> Enum.map(&read_int/1)
    |> Enum.reject(&is_nil/1)
    |> average()
  end

  defp memsup() do
    memsup_data = :memsup.get_system_memory_data()

    %{
      dram_size_bytes: memsup_data[:total_memory],
      dram_used_bytes: memsup_data[:total_memory] - memsup_data[:available_memory]
    }
  end

  defp disksup() do
    data_partition = :disksup.get_disk_info() |> List.keyfind(~c"/root", 0)

    case data_partition do
      nil ->
        %{
          data_partition_size_bytes: 0,
          data_partition_used_bytes: 0
        }

      {_, size, used, _percent} ->
        %{
          data_partition_size_bytes: size,
          data_partition_used_bytes: used
        }
    end
  end

  defp average([]), do: 0.0
  defp average(list), do: Enum.sum(list) / length(list)

  defp ip_addresses() do
    {:ok, if_addresses} = :inet.getifaddrs()

    if_addresses
    |> Enum.flat_map(&extract_addresses/1)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp extract_addresses({name, ifaddrs}) when name not in @excluded_ifnames do
    case Utils.extract_ifaddr_addresses(ifaddrs) do
      [] -> []
      addresses -> [{name, addresses}]
    end
  end

  defp extract_addresses({_name, _ifaddrs}), do: []

  defp read_int(path, default \\ 0) do
    case File.read(path) do
      {:ok, contents} -> String.trim(contents) |> String.to_integer()
      _ -> default
    end
  end
end
