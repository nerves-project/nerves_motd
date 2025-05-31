# SPDX-FileCopyrightText: 2021 Ace Yanagida
# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesMOTDTest do
  use ExUnit.Case
  use Mimic
  doctest NervesMOTD

  import ExUnit.CaptureIO

  alias Nerves.Runtime.KV
  alias NervesMOTD.Model

  setup do
    Model
    |> stub(:applications, fn ->
      %{started: [:nerves_runtime], expected: [:nerves_runtime], loaded: [:nerves_runtime]}
    end)
    |> stub(:active_partition, fn -> "A" end)
    |> stub(:firmware_validity, fn -> :valid end)
    |> stub(:cpu_temperature, fn -> {:ok, 41.234} end)
    |> stub(:load_average, fn -> ["0.35", "0.16", "0.11", "2/70", "1536"] end)
    |> stub(:memory_stats, fn -> {:ok, %{size_mb: 316, used_mb: 78, used_percent: 25}} end)
    |> stub(:filesystem_stats, fn "/dev/mmcblk0p3" ->
      {:ok, %{size_mb: 14_619, used_mb: 37, used_percent: 0}}
    end)
    |> stub(:time_synchronized?, fn -> true end)
    |> stub(:firmware_id, fn -> "energy-bid (53233641-82a4-5576-b75d-d227a234c626)" end)

    :ok
  end

  defp capture_motd(opts \\ []) do
    capture_io(fn -> NervesMOTD.print(opts) end)
  end

  test "print" do
    assert :ok = NervesMOTD.print()
  end

  test "print failure" do
    assert capture_motd("bad option") =~ ~r/Could not print MOTD: .*/
  end

  test "Default logo" do
    assert capture_motd() =~ ~r/N  E  R  V  E  S/
  end

  test "daily logo schemes" do
    for {date, scheme} <- [
          {~D[2026-10-31], :pumpkin},
          {~D[2027-10-31], :pumpkin},
          {~D[2026-05-25], :elixir},
          {~D[2026-06-14], :rainbow},
          {~D[2026-10-25], :nerves},
          {~D[2026-12-25], :christmas}
        ] do
      expect(Date, :utc_today, fn -> date end)
      logo = NervesMOTD.nerves_logo()
      assert logo == NervesMOTD.nerves_logo(scheme)

      if scheme != :nerves do
        refute logo == NervesMOTD.nerves_logo(:nerves)
      end
    end
  end

  test "Print defaults to the daily scheme and permits an explicit override" do
    stub(Date, :utc_today, fn -> ~D[2026-10-31] end)

    pumpkin = NervesMOTD.nerves_logo(:pumpkin) |> IO.iodata_to_binary()
    blue = NervesMOTD.nerves_logo(:nerves) |> IO.iodata_to_binary()

    assert String.starts_with?(capture_motd(), pumpkin)
    assert String.starts_with?(capture_motd(nerves_logo_scheme: :nerves), blue)
    assert String.starts_with?(capture_motd(logo: "custom logo"), "custom logo")
    refute capture_motd(logo: "") =~ IO.ANSI.color(208)
  end

  test "Custom logo" do
    assert capture_motd(logo: "custom logo") =~ ~r/custom logo/
    refute capture_motd(logo: "custom logo") =~ ~r/N  E  R  V  E  S/
  end

  test "Custom logo via Application environment" do
    Application.put_env(:nerves_motd, :logo, "app env logo")
    on_exit(fn -> Application.delete_env(:nerves_motd, :logo) end)

    assert capture_motd() =~ ~r/app env logo/
    assert capture_motd(logo: "override logo") =~ ~r/override logo/
  end

  test "No logo" do
    refute capture_motd(logo: "") =~ ~r/N  E  R  V  E  S/
  end

  test "Custom rows" do
    assert capture_motd(extra_rows: [[{"custom row", "hello"}]]) =~ ~r/hello/
  end

  test "Custom rows from function" do
    fun = fn -> [[{"custom row", "hello"}]] end
    assert capture_motd(extra_rows: fun) =~ ~r/hello/
  end

  test "Custom rows from an MFArgs" do
    assert capture_motd(extra_rows: {__MODULE__, :extra_rows_callback, []}) =~ ~r/hello/
  end

  @doc false
  @spec extra_rows_callback() :: list()
  def extra_rows_callback() do
    [[{"custom row", "hello"}]]
  end

  test "Custom rows from bad function prints error" do
    bad_fun = fn -> raise "wat!" end
    assert capture_motd(extra_rows: bad_fun) =~ ~r/:extra_rows  : failed \(:error\) -/
  end

  test "firmware_designation" do
    assert capture_motd() =~
             ~r/nerves_livebook 0.2.17 - energy-bid \(53233641-82a4-5576-b75d-d227a234c626\)/
  end

  test "Serial number" do
    # Nerves.Runtime.serial_number() is expected to fail when running
    # the regression tests since not using Nerves.
    assert capture_motd() =~ ~r/Serial       : unconfigured/
  end

  test "Uptime" do
    assert capture_motd() =~ ~r/Uptime       : .*\d{0,2} seconds/
  end

  test "Clock" do
    assert capture_motd() =~ ~r/Clock        : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \w{3}/
  end

  test "Clock gets highlighted when not synchronized" do
    expect(Model, :time_synchronized?, fn -> false end)

    assert capture_motd() =~
             ~r/Clock        : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \w{3} \(unsynchronized\)/
  end

  test "Temperature when available" do
    assert capture_motd() =~ ~r/Temperature  : 41.2°C/
  end

  test "Temperature when unavailable" do
    expect(Model, :cpu_temperature, fn -> :error end)

    assert capture_motd() =~ ~r/Temperature  : N\/A/
  end

  test "Firmware when valid" do
    expect(Model, :active_partition, fn -> "B" end)

    assert capture_motd() =~ ~r/Firmware     : Valid \(B\)/
  end

  test "Firmware when invalid" do
    expect(Model, :firmware_validity, fn -> :invalid end)

    assert capture_motd() =~ ~r/Firmware     : Not validated \(A\)/
  end

  test "Applications when all apps started" do
    all_apps = [:a, :b, :nerves_runtime]
    apps = %{started: all_apps, expected: all_apps, loaded: all_apps}
    expect(Model, :applications, fn -> apps end)

    assert capture_motd() =~ ~r/Applications : 3 started/
  end

  test "Applications when not all apps started" do
    all_apps = [:a, :b, :nerves_runtime]
    apps = %{started: [:nerves_runtime], expected: all_apps, loaded: all_apps}
    expect(Model, :applications, fn -> apps end)

    assert capture_motd() =~ ~r/Applications : 1 started \(a, b not started\)/
  end

  test "Hostname" do
    assert capture_motd() =~ ~r/Hostname     : [0-9a-zA-Z\-]*/
  end

  test "Memory usage when ok" do
    assert capture_motd() =~ ~r/Memory usage : 78 MB \(25%\)/
  end

  test "Memory usage when high" do
    expect(Model, :memory_stats, fn ->
      {:ok, %{size_mb: 316, used_mb: 316, used_percent: 100}}
    end)

    assert capture_motd() =~ ~r/Memory usage : 316 MB \(100%\)/
  end

  test "Load average" do
    assert capture_motd() =~ ~r/Load average : 0.35 0.16 0.11/
  end

  test "Load average error" do
    expect(Model, :load_average, fn -> [] end)

    assert capture_motd() =~ ~r/Load average : error/
  end

  test "Application partition usage" do
    assert capture_motd() =~ ~r/Part usage   : 37 MB \(0%\)/
  end

  test "Application partition usage high" do
    expect(Model, :filesystem_stats, fn "/dev/mmcblk0p3" ->
      {:ok, %{size_mb: 14_300, used_mb: 12_900, used_percent: 90}}
    end)

    assert capture_motd() =~ ~r/Part usage   : 12900 MB \(90%\)/
  end

  test "Application partition usage not available" do
    expect(Model, :filesystem_stats, fn "/dev/mmcblk0p3" -> :error end)

    assert capture_motd() =~ ~r/Part usage   : not available/
  end

  test "No application partition" do
    old_devpath = KV.get_active("nerves_fw_application_part0_devpath")
    on_exit(fn -> KV.put_active("nerves_fw_application_part0_devpath", old_devpath) end)
    KV.put_active("nerves_fw_application_part0_devpath", "")

    assert capture_motd() =~ ~r/Part usage   : not available/
  end

  test "IP addresses" do
    assert capture_motd() =~ ~r/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,3}/
  end

  test "Doesn't print if nerves_runtime isn't started" do
    expect(Model, :applications, fn -> %{started: [], loaded: [], expected: []} end)

    assert capture_motd() == ""
  end
end
