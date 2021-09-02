defmodule NervesMotdTest do
  use ExUnit.Case
  doctest NervesMotd

  import Mox

  # https://hexdocs.pm/mox/Mox.html#module-global-mode
  setup :set_mox_from_context

  # https://hexdocs.pm/mox/Mox.html#verify_on_exit!/1
  setup :verify_on_exit!

  setup do
    Mox.stub_with(NervesMotd.MockRuntime, NervesMotd.Runtime.Test)
    Mox.stub_with(NervesMotd.MockRuntimeKV, NervesMotd.RuntimeKV.Test)
    Mox.stub_with(NervesMotd.MockLinux, NervesMotd.Linux.Test)
    :ok
  end

  test "print" do
    IO.puts("")
    assert :ok = NervesMotd.print()
  end

  test "uptime" do
    assert String.match?(NervesMotd.uptime(), ~r/\d{0,2} seconds\z/)
  end

  test "clock" do
    assert String.match?(NervesMotd.clock(), ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC\z/)
  end

  test "fw_active" do
    assert NervesMotd.fw_active() == "a"
  end

  test "fw_architecture" do
    assert NervesMotd.fw_architecture() == "arm"
  end

  test "fw_platform" do
    assert NervesMotd.fw_platform() == "rpi4"
  end

  test "fw_product" do
    assert NervesMotd.fw_product() == "nerves_livebook"
  end

  test "fw_version" do
    assert NervesMotd.fw_version() == "0.2.17"
  end

  test "fw_uuid" do
    assert NervesMotd.fw_uuid() == "0540f0cd-f95a-5596-d152-221a70c078a9"
  end

  test "validate_firmware" do
    assert NervesMotd.validate_firmware() == :ok
  end

  test "network_names" do
    assert is_list(NervesMotd.network_names())
  end

  test "memory_usage" do
    assert NervesMotd.memory_usage() == [316_664, 78_408, 126_776, 12, 111_480, 238_564]
  end

  test "load_average" do
    assert NervesMotd.load_average() == "0.35 0.16 0.11 2/70 1536"
  end
end
