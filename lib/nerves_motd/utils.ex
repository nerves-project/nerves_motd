defmodule NervesMOTD.Utils do
  @moduledoc false

  @doc """
  Extract IP addresses for one interface returned by `:inet.getifaddrs/0`

  ## Example:

      iex> if_addresses = [
      ...>   flags: [:up, :broadcast, :running, :multicast],
      ...>   addr: {10, 0, 0, 202},
      ...>   netmask: {255, 255, 255, 0},
      ...>   broadaddr: {10, 0, 0, 202},
      ...>   addr: {65152, 0, 0, 0, 47655, 60415, 65227, 8746},
      ...>   netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0},
      ...>   hwaddr: [184, 39, 235, 203, 34, 42]
      ...> ]
      iex> NervesMOTD.Utils.extract_ifaddr_addresses(if_addresses)
      [
        {{10, 0, 0, 202}, {255, 255, 255, 0}},
        {{65152, 0, 0, 0, 47655, 60415, 65227, 8746}, {65535, 65535, 65535, 65535, 0, 0, 0, 0}}
      ]
  """
  @spec extract_ifaddr_addresses(keyword()) :: [String.t()]
  def extract_ifaddr_addresses(kv_pairs, acc \\ [])

  def extract_ifaddr_addresses([], acc), do: Enum.reverse(acc)

  def extract_ifaddr_addresses([{:addr, addr}, {:netmask, netmask} | rest], acc) do
    extract_ifaddr_addresses(rest, [{addr, netmask} | acc])
  end

  def extract_ifaddr_addresses([_other | rest], acc) do
    extract_ifaddr_addresses(rest, acc)
  end

  @doc """
  Convert an IP address and subnet mask to a nice string

  Examples:

      iex> NervesMOTD.Utils.ip_address_mask_to_string({{10, 0, 0, 202}, {255, 255, 255, 0}})
      "10.0.0.202/24"
      iex> NervesMOTD.Utils.ip_address_mask_to_string({{65152, 0, 0, 0, 47655, 60415, 65227, 8746}, {65535, 65535, 65535, 65535, 0, 0, 0, 0}})
      "fe80::ba27:ebff:fecb:222a/64"

  """
  @spec ip_address_mask_to_string({:inet.ip_address(), :inet.ip_address()}) :: String.t()
  def ip_address_mask_to_string({address, mask}) do
    "#{:inet.ntoa(address)}/#{subnet_mask_to_prefix(mask)}"
  end

  @doc """
  Convert a subnet mask tuple to a prefix length

  Examples:

      iex> NervesMOTD.Utils.subnet_mask_to_prefix({255, 255, 255, 0})
      24

      iex> NervesMOTD.Utils.subnet_mask_to_prefix({65535, 65535, 65535, 65535, 0, 0, 0, 0})
      64
  """
  @spec subnet_mask_to_prefix(:inet.ip_address()) :: 0..128
  def subnet_mask_to_prefix(address) do
    address |> ip_to_binary() |> leading_ones(0)
  end

  defp ip_to_binary({a, b, c, d}), do: <<a, b, c, d>>

  defp ip_to_binary({a, b, c, d, e, f, g, h}),
    do: <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>

  defp leading_ones(<<0b11111111, rest::binary>>, sum), do: leading_ones(rest, sum + 8)
  defp leading_ones(<<0b11111110, _rest::binary>>, sum), do: sum + 7
  defp leading_ones(<<0b11111100, _rest::binary>>, sum), do: sum + 6
  defp leading_ones(<<0b11111000, _rest::binary>>, sum), do: sum + 5
  defp leading_ones(<<0b11110000, _rest::binary>>, sum), do: sum + 4
  defp leading_ones(<<0b11100000, _rest::binary>>, sum), do: sum + 3
  defp leading_ones(<<0b11000000, _rest::binary>>, sum), do: sum + 2
  defp leading_ones(<<0b10000000, _rest::binary>>, sum), do: sum + 1
  defp leading_ones(_, sum), do: sum
end
