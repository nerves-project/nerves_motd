# SPDX-FileCopyrightText: 2021 Ace Yanagida
# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesMOTDTest do
  use ExUnit.Case
  doctest NervesMOTD

  alias Nerves.Runtime.KV
  import ExUnit.CaptureIO
  import Mox

  # https://hexdocs.pm/mox/Mox.html#module-global-mode
  setup :set_mox_from_context

  # https://hexdocs.pm/mox/Mox.html#verify_on_exit!/1
  setup :verify_on_exit!

  setup do
    Mox.stub_with(NervesMOTD.MockRuntime, NervesMOTD.Runtime.Host)
    :ok
  end

  defp capture_motd(opts \\ []) do
    capture_io(fn -> NervesMOTD.print(opts) end)
  end

  defp default_applications_code() do
    fn -> %{started: [:nerves_runtime], loaded: []} end
  end

  test "print" do
    assert :ok = NervesMOTD.print()
  end

  test "print failure" do
    assert capture_motd("bad option") =~ ~r/Could not print MOTD: .*/
  end

  test "Default logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/N  E  R  V  E  S/
  end

  test "Custom logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd(logo: "custom logo") =~ ~r/custom logo/
    refute capture_motd(logo: "custom logo") =~ ~r/N  E  R  V  E  S/
  end

  test "Custom logo via Application environment" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 2, default_applications_code())
    |> Mox.expect(:active_partition, 2, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 2, fn -> :valid end)

    Application.put_env(:nerves_motd, :logo, "app env logo")
    assert capture_motd() =~ ~r/app env logo/
    assert capture_motd(logo: "override logo") =~ ~r/override logo/
    :application.unset_env(:nerves_motd, :logo)
  end

  test "No logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    refute capture_motd(logo: "") =~ ~r/N  E  R  V  E  S/
  end

  test "Custom rows" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd(extra_rows: [[{"custom row", "hello"}]]) =~ ~r/hello/
  end

  test "Custom rows from function" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    fun = fn -> [[{"custom row", "hello"}]] end
    assert capture_motd(extra_rows: fun) =~ ~r/hello/
  end

  test "Custom rows from an MFArgs" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd(extra_rows: {__MODULE__, :extra_rows_callback, []}) =~ ~r/hello/
  end

  @doc false
  @spec extra_rows_callback() :: list()
  def extra_rows_callback() do
    [[{"custom row", "hello"}]]
  end

  test "Custom rows from bad function prints error" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    bad_fun = fn -> raise "wat!" end
    assert capture_motd(extra_rows: bad_fun) =~ ~r/:extra_rows  : failed \(:error\) -/
  end

  test "Uname" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~
             ~r/nerves_livebook 0.2.17 \(0540f0cd-f95a-5596-d152-221a70c078a9\) arm rpi4/
  end

  test "Serial number" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    # Nerves.Runtime.serial_number() is expected to fail when running
    # the regression tests since not using Nerves.
    assert capture_motd() =~ ~r/Serial       : unconfigured/
  end

  test "Uptime" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Uptime       : .*\d{0,2} seconds/
  end

  test "Clock" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Clock        : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \w{3}/
  end

  test "Clock gets highlighted when not synchronized" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:time_synchronized?, 1, fn -> false end)

    assert capture_motd() =~
             ~r/Clock        : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \w{3} \(unsynchronized\)/
  end

  test "Temperature when available" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:cpu_temperature, 1, fn -> {:ok, 41.234} end)

    assert capture_motd() =~ ~r/Temperature  : 41.2°C/
  end

  test "Temperature when unavailable" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:cpu_temperature, 1, fn -> :error end)

    refute capture_motd() =~ ~r/Temperature/
  end

  test "Firmware when valid" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "B" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Firmware     : Valid \(B\)/
  end

  test "Firmware when invalid" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :invalid end)

    assert capture_motd() =~ ~r/Firmware     : Not validated \(A\)/
  end

  test "Firmware validity is unknown" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :unknown end)

    assert capture_motd() =~ ~r/Firmware     : A/
  end

  test "Previous firmware was reverted" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:firmware_reverted?, 1, fn -> true end)

    assert capture_motd() =~ ~r/Firmware     : Valid \(A\) \[Reverted\]/
  end

  test "Applications when all apps started" do
    apps = %{started: [:a, :b, :nerves_runtime], loaded: [:a, :b, :nerves_runtime]}

    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, fn -> apps end)
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :unknown end)

    assert capture_motd() =~ ~r/Applications : \d* started/
  end

  test "Applications when not all apps started" do
    apps = %{started: [:nerves_runtime], loaded: [:a, :b, :nerves_runtime]}

    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, fn -> apps end)
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Applications : \d* started \(a, b not started\)/
  end

  test "Hostname" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Hostname     : [0-9a-zA-Z\-]*/
  end

  test "Memory usage when ok" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Memory usage : 78 MB \(25%\)/
  end

  test "Memory usage when high" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:memory_stats, 1, fn ->
      {:ok, %{size_mb: 316, used_mb: 316, used_percent: 100}}
    end)

    assert capture_motd() =~ ~r/Memory usage : 316 MB \(100%\)/
  end

  test "Load average" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Load average : 0.35 0.16 0.11/
  end

  test "Load average error" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:load_average, 1, fn -> [] end)

    assert capture_motd() =~ ~r/Load average : error/
  end

  test "Application partition usage" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/Part usage   : 37 MB \(0%\)/
  end

  test "Application partition usage high" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:filesystem_stats, 1, fn _path ->
      {:ok, %{size_mb: 14_300, used_mb: 12_900, used_percent: 90}}
    end)

    assert capture_motd() =~ ~r/Part usage   : 12900 MB \(90%\)/
  end

  test "Application partition usage not available" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)
    |> Mox.expect(:filesystem_stats, 1, fn _path ->
      :error
    end)

    assert capture_motd() =~ ~r/Part usage   : not available/
  end

  test "No application partition" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    old_devpath = KV.get_active("nerves_fw_application_part0_devpath")
    KV.put_active("nerves_fw_application_part0_devpath", "")
    result = capture_motd()
    KV.put_active("nerves_fw_application_part0_devpath", old_devpath)
    assert result =~ ~r/Part usage   : not available/
  end

  test "IP addresses" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:active_partition, 1, fn -> "A" end)
    |> Mox.expect(:firmware_validity, 1, fn -> :valid end)

    assert capture_motd() =~ ~r/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,3}/
  end

  test "Doesn't print if nerves_runtime isn't started" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, fn -> %{started: [], loaded: []} end)

    assert capture_motd() == ""
  end
end
