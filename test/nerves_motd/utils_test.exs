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
end
