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

  test "print" do
    IO.puts("")
    assert :ok = NervesMOTD.print()
  end

  @nerves_logo_regex ~r/\e\[34m████▄▖    \e\[36m▐███\n/

  test "Default logo" do
    assert capture_motd() =~ @nerves_logo_regex
  end

  test "Custom logo" do
    assert capture_motd(logo: "custom logo") =~ ~r/custom logo/
    refute capture_motd(logo: "custom logo") =~ @nerves_logo_regex
  end

  test "No logo" do
    refute capture_motd(logo: "") =~ @nerves_logo_regex
  end

  test "Uname" do
    assert capture_motd() =~
             ~r/nerves_livebook 0.2.17 \(0540f0cd-f95a-5596-d152-221a70c078a9\) arm rpi4/
  end

  test "Uptime" do
    assert capture_motd() =~ ~r/Uptime : .*\d{0,2} seconds/
  end

  test "Clock" do
    assert capture_motd() =~ ~r/Clock  : \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/
  end

  test "Firmware when valid" do
    Mox.expect(NervesMOTD.MockRuntime, :firmware_valid?, 1, fn -> true end)
    assert capture_motd() =~ ~r/\e\[32mValid/
  end

  test "Firmware when invalid" do
    Mox.expect(NervesMOTD.MockRuntime, :firmware_valid?, 1, fn -> false end)
    assert capture_motd() =~ ~r/\e\[31mNot validated/
  end

  test "Applications when all apps started" do
    apps = %{started: [:a, :b, :c], loaded: [:a, :b, :c]}
    Mox.expect(NervesMOTD.MockRuntime, :applications, 1, fn -> apps end)
    assert capture_motd() =~ ~r/Applications : \e\[32m\d* \/ \d*\e\[0m/
  end

  test "Applications when not all apps started" do
    apps = %{started: [:b], loaded: [:a, :b, :c]}
    Mox.expect(NervesMOTD.MockRuntime, :applications, 1, fn -> apps end)
    assert capture_motd() =~ ~r/Applications : \e\[31m\d* \/ \d* \(a, c not started\)\e\[0m/
  end

  test "Hostname" do
    assert capture_motd() =~ ~r/Hostname     : \e\[0m[0-9a-zA-Z\-]*\e\[0m/
  end

  test "Networks" do
    assert capture_motd() =~ ~r/Networks     : [0-9a-zA-Z]+(,[0-9a-zA-Z]+)*/
  end

  test "Memory usage when ok" do
    Mox.expect(NervesMOTD.MockRuntime, :memory_usage, 1, fn -> [316_664, 78_408, 0, 0, 0, 0] end)
    assert capture_motd() =~ ~r/Memory usage : \e\[0m78 MB \(24%\)\e\[0m/
  end

  test "Memory usage when high" do
    Mox.expect(NervesMOTD.MockRuntime, :memory_usage, 1, fn -> [316_664, 316_664, 0, 0, 0, 0] end)
    assert capture_motd() =~ ~r/Memory usage : \e\[31m316 MB \(100%\)\e\[0m/
  end

  test "Load average" do
    assert capture_motd() =~ ~r/Load average : 0.35 0.16 0.11/
  end

  test "Load average error" do
    Mox.expect(NervesMOTD.MockRuntime, :load_average, 1, fn -> [] end)
    assert capture_motd() =~ ~r/Load average : error/
  end
end
