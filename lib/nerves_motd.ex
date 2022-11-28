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

  alias NervesMOTD.SystemInfo

  @excluded_ifnames ['lo', 'lo0']

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
  * `:extra_rows` - custom rows that append to the end of the MOTD.
  """
  @spec print([option()]) :: :ok
  def print(opts \\ []) do
    apps = runtime_mod().applications()

    if ready?(apps) do
      [
        logo(opts),
        IO.ANSI.reset(),
        SystemInfo.uname(),
        "\n",
        Enum.map(rows(apps, opts), &format_row/1),
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

  @spec rows(map(), list()) :: [[cell()]]
  defp rows(apps, opts) do
    [
      [{"Uptime", SystemInfo.uptime_text()}],
      [{"Clock", SystemInfo.clock_text()}],
      if(text = SystemInfo.cpu_temperature_text(), do: [{"Temperature", text}]),
      [],
      [
        {"Firmware", SystemInfo.firmware_status_text()},
        {"Applications", SystemInfo.applications_text(apps)}
      ],
      [
        {"Memory usage", SystemInfo.memory_usage_text()},
        {"Part usage", SystemInfo.active_part_usage_text()}
      ],
      [
        {"Hostname", SystemInfo.hostname_text()},
        {"Load average", SystemInfo.load_average_text()}
      ],
      []
    ] ++
      ip_address_rows() ++
      Keyword.get(opts, :extra_rows, [])
  end

  @spec format_row([cell()]) :: iolist()
  # A blank line
  defp format_row([]), do: ["\n"]

  # A row with full width
  defp format_row([{label, value}]) do
    ["  ", format_cell_label(label), " : ", value, "\n", :reset]
  end

  # A row with two columns
  defp format_row([col0, col1]) do
    ["  ", format_cell(col0, 0), format_cell(col1, 1), "\n"]
  end

  defp format_row(nil), do: []

  @spec format_cell(cell(), 0 | 1) :: IO.ANSI.ansidata()
  defp format_cell({label, value}, column_index) do
    [format_cell_label(label), " : ", format_cell_value(value, column_index, 24), :reset]
  end

  @spec format_cell_label(IO.ANSI.ansidata()) :: IO.ANSI.ansidata()
  defp format_cell_label(label), do: SystemInfo.fit_ansidata(label, 12)

  @spec format_cell_value(IO.ANSI.ansidata(), 0 | 1, pos_integer()) :: IO.ANSI.ansidata()
  defp format_cell_value(value, 0, width), do: SystemInfo.fit_ansidata(value, width)
  defp format_cell_value(value, 1, _width), do: value

  @spec ip_address_rows() :: [[cell()]]
  defp ip_address_rows() do
    {:ok, if_addresses} = :inet.getifaddrs()

    if_addresses
    |> Enum.map(&ip_address_row/1)
    |> Enum.reject(fn row -> row == [] end)
  end

  @spec ip_address_row({charlist(), keyword()}) :: [cell()]
  defp ip_address_row({name, ifaddrs}) when name not in @excluded_ifnames do
    case SystemInfo.extract_ifaddr_addresses(ifaddrs) do
      [] ->
        # Skip interfaces without addresses
        []

      addresses ->
        # Create a comma-separated list of IP addresses
        [{name, SystemInfo.join_ip_addresses(addresses, ", ")}]
    end
  end

  defp ip_address_row(_), do: []

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
