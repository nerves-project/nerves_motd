defmodule NervesMOTDTest do
  use ExUnit.Case
  doctest NervesMOTD

  import Mox

  # https://hexdocs.pm/mox/Mox.html#module-global-mode
  setup :set_mox_from_context

  # https://hexdocs.pm/mox/Mox.html#verify_on_exit!/1
  setup :verify_on_exit!

  setup do
    Mox.stub_with(NervesMOTD.MockRuntime, NervesMOTD.Runtime.Test)
    Mox.stub_with(NervesMOTD.MockRuntimeKV, NervesMOTD.RuntimeKV.Test)
    Mox.stub_with(NervesMOTD.MockLinux, NervesMOTD.Linux.Test)
    :ok
  end

  test "print" do
    IO.puts("")
    assert :ok = NervesMOTD.print()
    IO.puts("---")
    assert :ok = NervesMOTD.print(logo: false)
  end

  test "uptime" do
    assert String.match?(NervesMOTD.uptime(), ~r/\d{0,2} seconds\z/)
  end

  test "clock" do
    assert String.match?(NervesMOTD.clock(), ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC\z/)
  end

  test "fw_active" do
    assert NervesMOTD.fw_active() == "a"
  end

  test "fw_architecture" do
    assert NervesMOTD.fw_architecture() == "arm"
  end

  test "fw_platform" do
    assert NervesMOTD.fw_platform() == "rpi4"
  end

  test "fw_product" do
    assert NervesMOTD.fw_product() == "nerves_livebook"
  end

  test "fw_version" do
    assert NervesMOTD.fw_version() == "0.2.17"
  end

  test "fw_uuid" do
    assert NervesMOTD.fw_uuid() == "0540f0cd-f95a-5596-d152-221a70c078a9"
  end

  test "validate_firmware" do
    assert NervesMOTD.validate_firmware() == :ok
  end

  test "network_names" do
    assert is_list(NervesMOTD.network_names())
  end

  test "memory_usage" do
    assert NervesMOTD.memory_usage() == [316_664, 78_408, 126_776, 12, 111_480, 238_564]
  end

  test "load_average" do
    assert NervesMOTD.load_average() == "0.35 0.16 0.11 2/70 1536"
  end
end
