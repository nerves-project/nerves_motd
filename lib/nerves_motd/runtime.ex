defmodule NervesMOTD.Runtime do
  @moduledoc false
  @callback applications() :: %{started: [atom()], loaded: [atom()]}
  @callback firmware_valid?() :: boolean()
  @callback load_average() :: [String.t()]
  @callback memory_usage() :: [integer()]
  @callback filesystem_stats(String.t()) ::
              {:ok,
               %{
                 size_mb: non_neg_integer(),
                 used_mb: non_neg_integer(),
                 used_percent: non_neg_integer()
               }}
              | :error
end

defmodule NervesMOTD.Runtime.Target do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def applications() do
    started = Enum.map(Application.started_applications(), &elem(&1, 0))
    loaded = Enum.map(Application.loaded_applications(), &elem(&1, 0))

    %{started: started, loaded: loaded}
  end

  @impl NervesMOTD.Runtime
  def firmware_valid?() do
    Nerves.Runtime.firmware_valid?()
  end

  @impl NervesMOTD.Runtime
  def load_average() do
    case File.read("/proc/loadavg") do
      {:ok, data_str} -> String.split(data_str, " ")
      _ -> []
    end
  end

  @impl NervesMOTD.Runtime
  def memory_usage() do
    [_total, _used, _free, _shared, _buff, _available] =
      System.cmd("free", [])
      |> elem(0)
      |> String.split("\n")
      |> tl
      |> hd
      |> String.split()
      |> tl
      |> Enum.map(&String.to_integer/1)
  end

  @impl NervesMOTD.Runtime
  def filesystem_stats(filename) when is_binary(filename) do
    # Use df to determine filesystem statistics. df's output looks like:
    #
    #     Filesystem           1M-blocks      Used Available Use% Mounted on
    #     /dev/mmcblk0p4            1534       205      1329  13% /root

    {df_results, 0} = System.cmd("df", ["-m", filename])
    [_title_row, results_row | _] = String.split(df_results, "\n")
    [_fs, size_mb_str, used_mb_str, _avail, used_percent_str | _] = String.split(results_row)
    {size_mb, ""} = Integer.parse(size_mb_str)
    {used_mb, ""} = Integer.parse(used_mb_str)
    {used_percent, "%"} = Integer.parse(used_percent_str)

    {:ok, %{size_mb: size_mb, used_mb: used_mb, used_percent: used_percent}}
  rescue
    # In case the `df` command is not available or any of the out parses incorrectly
    _error -> :error
  end
end
