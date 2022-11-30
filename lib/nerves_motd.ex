defmodule NervesMOTD do
  @moduledoc """
  `NervesMOTD` prints a "message of the day" on Nerves devices.

  To use, add `NervesMOTD.print()` to the `rootfs_overlay/etc/iex.exs` file in
  your Nerves project.
  """

  alias NervesMOTD.{LayoutView, SystemInfo}

  @nerves_logo """
  \e[38;5;24m████▄▄    \e[38;5;74m▐███
  \e[38;5;24m█▌  ▀▀██▄▄  \e[38;5;74m▐█
  \e[38;5;24m█▌  \e[38;5;74m▄▄  \e[38;5;24m▀▀  \e[38;5;74m▐█   \e[39mN  E  R  V  E  S
  \e[38;5;24m█▌  \e[38;5;74m▀▀██▄▄  ▐█
  \e[38;5;24m███▌    \e[38;5;74m▀▀████\e[0m
  """

  @help_text """
  Nerves CLI help: https://hexdocs.pm/nerves/iex-with-nerves.html
  """

  @excluded_ifnames ['lo', 'lo0']

  @typedoc """
  MOTD options
  """
  @type option() :: {:logo, IO.ANSI.ansidata()} | {:extra_rows, [row()]}

  @typedoc """
  One row of information

  A row may contain 0, 1 or 2 cells.
  """
  @type row() :: LayoutView.row()

  @typedoc """
  A label and value
  """
  @type cell() :: LayoutView.cell()

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
        logo: logo(opts),
        header: header(),
        rows: rows(apps, opts),
        help_text: help_text()
      ]
      |> LayoutView.render()
      |> IO.puts()
    end

    :ok
  rescue
    error -> IO.puts("Could not print MOTD: #{inspect(error)}")
  end

  defp ready?(apps), do: :nerves_runtime in apps.started

  @spec logo([option()]) :: IO.ANSI.ansidata()
  defp logo(opts), do: Keyword.get(opts, :logo, @nerves_logo)

  @spec header() :: IO.ANSI.ansidata()
  defp header(), do: SystemInfo.uname()

  @spec rows(map(), list()) :: [[cell()]]
  defp rows(apps, opts) do
    main_rows(apps) ++ ip_address_rows() ++ Keyword.get(opts, :extra_rows, [])
  end

  @spec main_rows(map()) :: [[cell()]]
  defp main_rows(apps) do
    [
      [LayoutView.uptime_cell()],
      [LayoutView.clock_cell()],
      if(temp_cell = LayoutView.cpu_temperature_cell(), do: [temp_cell]),
      [],
      [LayoutView.firmware_cell(), LayoutView.applications_cell(apps)],
      [LayoutView.memory_usage_cell(), LayoutView.part_usage_cell()],
      [LayoutView.hostname_cell(), LayoutView.load_average_cell()],
      []
    ]
  end

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

  @spec help_text() :: IO.ANSI.ansidata()
  defp help_text(), do: @help_text

  defp runtime_mod() do
    Application.get_env(:nerves_motd, :runtime_mod, NervesMOTD.Runtime.Target)
  end
end
