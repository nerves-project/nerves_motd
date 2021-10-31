defmodule NervesMOTD.UtilsTest do
  use ExUnit.Case
  doctest NervesMOTD.Utils

  alias NervesMOTD.Utils

  defp ipv6(str) do
    {:ok, address} = :inet.parse_ipv6_address(to_charlist(str))
    address
  end

  describe "subnet_mask_to_prefix/1" do
    test "ipv4 subnet masks" do
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 255}) == 32
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 252}) == 30
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 248}) == 29
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 240}) == 28
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 224}) == 27
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 192}) == 26
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 128}) == 25
      assert Utils.subnet_mask_to_prefix({255, 255, 255, 0}) == 24
      assert Utils.subnet_mask_to_prefix({255, 255, 0, 0}) == 16
      assert Utils.subnet_mask_to_prefix({255, 0, 0, 0}) == 8
      assert Utils.subnet_mask_to_prefix({0, 0, 0, 0}) == 0
    end

    test "ipv6 subnet masks" do
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")) ==
               128

      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffff::")) == 64
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fffe::")) == 63
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fffc::")) == 62
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fff8::")) == 61
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fff0::")) == 60
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffe0::")) == 59
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffc0::")) == 58
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ff80::")) == 57
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ff00::")) == 56
      assert Utils.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fe00::")) == 55
      assert Utils.subnet_mask_to_prefix(ipv6("::")) == 0
    end
  end

  # the dependency :nerves_time_zones requires Elixir "~> 1.11"
  if {:module, NervesTimeZones} == Code.ensure_loaded(NervesTimeZones) do
    describe "time_with_nerves_time_zones/0" do
      test "formats correctly based on current time zone" do
        assert Utils.time_with_nerves_time_zones() =~ ~r/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} JST/
      end
    end
  end

  describe "utc_time/0" do
    test "formats correctly" do
      assert Utils.utc_time() =~ ~r/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/
    end
  end
end
