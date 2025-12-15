defmodule NervesMotd.OSMon do
  def update(info) do
    info |> add_disksup_data() |> add_memsup_data() |> add_cpu_sup_data()
  end

  defp add_memsup_data(info) do
    memsup_data = :memsup.get_system_memory_data()

    %{
      info
      | dram_size_bytes: memsup_data[:total_memory],
        dram_used_bytes: memsup_data[:total_memory] - memsup_data[:available_memory]
    }
  end

  defp add_disksup_data(info) do
    data_partition = :disksup.get_disk_info() |> List.keyfind(~c"/root", 0)

    case data_partition do
      nil ->
        info

      {_, size, used, _percent} ->
        %{
          info
          | data_partition_size_bytes: size,
            data_partition_used_bytes: used
        }
    end
  end

  defp add_cpu_sup_data(info) do
    %{
      info
      | load_averages: [:cpu_sup.avg1() / 256, :cpu_sup.avg5() / 256, :cpu_sup.avg15() / 256]
    }
  end
end
