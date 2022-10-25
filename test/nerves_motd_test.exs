defmodule NervesMOTDTest do
  use ExUnit.Case
  doctest NervesMOTD

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
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd("bad option") =~ ~r/Could not print MOTD: .*/
  end

  @nerves_logo_regex ~r/N  E  R  V  E  S/

  test "Default logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ @nerves_logo_regex
  end

  test "Custom logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd(logo: "custom logo") =~ ~r/custom logo/
    refute capture_motd(logo: "custom logo") =~ @nerves_logo_regex
  end

  test "No logo" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    refute capture_motd(logo: "") =~ @nerves_logo_regex
  end

  test "Custom rows" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd(extra_rows: [[{"custom row", "hello"}]]) =~ ~r/hello/
  end

  test "Uname" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~
             ~r/nerves_livebook 0.2.17 \(0540f0cd-f95a-5596-d152-221a70c078a9\) arm rpi4/
  end

  test "Uptime" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Uptime       : .*\d{0,2} seconds/
  end

  test "Clock" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Clock        : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \w{3}/
  end

  test "Temperature when available" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:cpu_temperature, 1, fn -> {:ok, 41.234} end)

    assert capture_motd() =~ ~r/Temperature  : 41.2/
  end

  test "Temperature when unavailable" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:cpu_temperature, 1, fn -> :error end)

    refute capture_motd() =~ ~r/Temperature/
  end

  test "Firmware when valid" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:firmware_valid?, 1, fn -> true end)

    assert capture_motd() =~ ~r/Firmware     : \e\[32mValid.*\e\[0m/
  end

  test "Firmware when invalid" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:firmware_valid?, 1, fn -> false end)

    assert capture_motd() =~ ~r/Firmware     : \e\[31mNot validated.*\e\[0m/
  end

  test "Applications when all apps started" do
    apps = %{started: [:a, :b, :nerves_runtime], loaded: [:a, :b, :nerves_runtime]}
    Mox.expect(NervesMOTD.MockRuntime, :applications, 1, fn -> apps end)
    assert capture_motd() =~ ~r/Applications : \d* started/
  end

  test "Applications when not all apps started" do
    apps = %{started: [:nerves_runtime], loaded: [:a, :b, :nerves_runtime]}

    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, fn -> apps end)

    assert capture_motd() =~ ~r/Applications : \e\[33m\d* started \(a, b not started\)\e\[0m/
  end

  test "Hostname" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Hostname     : [0-9a-zA-Z\-]*/
  end

  test "Memory usage when ok" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Memory usage : 78 MB \(25%\)/
  end

  test "Memory usage when high" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:memory_stats, 1, fn ->
      {:ok, %{size_mb: 316, used_mb: 316, used_percent: 100}}
    end)

    assert capture_motd() =~ ~r/Memory usage : \e\[31m316 MB \(100%\).*\e\[0m/
  end

  test "Load average" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Load average : 0.35 0.16 0.11/
  end

  test "Load average error" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:load_average, 1, fn -> [] end)

    assert capture_motd() =~ ~r/Load average : error/
  end

  test "Application partition usage" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/Part usage   : 37 MB \(0%\)/
  end

  test "Application partition usage high" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:filesystem_stats, 1, fn _path ->
      {:ok, %{size_mb: 14_300, used_mb: 12_900, used_percent: 90}}
    end)

    assert capture_motd() =~ ~r/Part usage   : \e\[31m12900 MB \(90%\)\e\[0m/
  end

  test "Application partition usage not available" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())
    |> Mox.expect(:filesystem_stats, 1, fn _path ->
      :error
    end)

    assert capture_motd() =~ ~r/Part usage   : \e\[31mnot available\e\[0m/
  end

  test "No application partition" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    old_devpath = Nerves.Runtime.KV.get_active("nerves_fw_application_part0_devpath")
    Nerves.Runtime.KV.put_active("nerves_fw_application_part0_devpath", "")
    result = capture_motd()
    Nerves.Runtime.KV.put_active("nerves_fw_application_part0_devpath", old_devpath)
    assert result =~ ~r/Part usage   : \e\[31mnot available\e\[0m/
  end

  test "IP addresses" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, default_applications_code())

    assert capture_motd() =~ ~r/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,3}/
  end

  test "Doesn't print if nerves_runtime isn't started" do
    NervesMOTD.MockRuntime
    |> Mox.expect(:applications, 1, fn -> %{started: [], loaded: []} end)

    assert capture_motd() == ""
  end
end
