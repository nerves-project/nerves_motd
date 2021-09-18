defmodule NervesMOTD.Runtime do
  @moduledoc false
  @callback applications() :: %{started: [atom()], loaded: [atom()]}
  @callback firmware_valid?() :: boolean()
  @callback load_average() :: [String.t()]
  @callback memory_usage() :: [integer()]
  @callback filesystem_stats(String.t()) ::
              %{
                size_mb: non_neg_integer(),
                used_mb: non_neg_integer(),
                used_percent: non_neg_integer()
              }
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
    with {df_results, 0} <- System.cmd("df", ["-m", filename]) do
      [size_mb, used_mb, _, used_percent, _] =
        df_results
        |> String.split("\n")
        |> tl
        |> Enum.map(&String.split/1)
        |> Enum.reject(&match?([], &1))
        |> Enum.map(fn [_path | data] -> data end)
        |> hd

      %{
        size_mb: elem(Integer.parse(size_mb), 0),
        used_mb: elem(Integer.parse(used_mb), 0),
        used_percent: elem(Integer.parse(used_percent), 0)
      }
    else
      _ -> raise "File not found"
    end
  end
end
