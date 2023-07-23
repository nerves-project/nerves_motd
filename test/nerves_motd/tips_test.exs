defmodule NervesMOTD.TipsTest do
  use ExUnit.Case
  alias NervesMOTD.Tips
  doctest NervesMOTD.Tips

  test "random/0 returns a string" do
    assert {:ok, tip} = Tips.random()
    assert is_binary(tip)
  end
end
