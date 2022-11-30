defmodule NervesMOTD.SystemInfoTest do
  use ExUnit.Case
  alias NervesMOTD.SystemInfo
  import NervesMOTD.SystemInfo
  doctest NervesMOTD.SystemInfo

  defp ipv6(str) do
    {:ok, address} = :inet.parse_ipv6_address(to_charlist(str))
    address
  end

  describe "subnet_mask_to_prefix/1" do
    test "ipv4 subnet masks" do
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 255}) == 32
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 252}) == 30
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 248}) == 29
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 240}) == 28
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 224}) == 27
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 192}) == 26
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 128}) == 25
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 255, 0}) == 24
      assert SystemInfo.subnet_mask_to_prefix({255, 255, 0, 0}) == 16
      assert SystemInfo.subnet_mask_to_prefix({255, 0, 0, 0}) == 8
      assert SystemInfo.subnet_mask_to_prefix({0, 0, 0, 0}) == 0
    end

    test "ipv6 subnet masks" do
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")) ==
               128

      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffff::")) == 64
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fffe::")) == 63
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fffc::")) == 62
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fff8::")) == 61
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fff0::")) == 60
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffe0::")) == 59
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ffc0::")) == 58
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ff80::")) == 57
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:ff00::")) == 56
      assert SystemInfo.subnet_mask_to_prefix(ipv6("ffff:ffff:ffff:fe00::")) == 55
      assert SystemInfo.subnet_mask_to_prefix(ipv6("::")) == 0
    end
  end

  describe "clock_text/0" do
    @tag :has_nerves_time_zones
    test "formats correctly with zone information" do
      # Japan doesn't observe daylight savings time so the time zone is JST all year
      assert SystemInfo.clock_text() =~ ~r/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} JST/
    end

    @tag :no_nerves_time_zones
    test "formats correctly without zone information" do
      assert SystemInfo.clock_text() =~ ~r/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/
    end
  end
end
