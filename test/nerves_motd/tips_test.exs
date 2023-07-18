defmodule NervesMOTD.TipsTest do
  use ExUnit.Case
  alias NervesMOTD.Tips
  doctest NervesMOTD.Tips

  test "all returns a list of strings" do
    assert [tip | _] = Tips.all()
    assert is_binary(tip)
  end

  test "random returns a string" do
    assert Tips.random() |> is_binary()
  end
end
