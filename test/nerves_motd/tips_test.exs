defmodule NervesMOTD.TipsTest do
  use ExUnit.Case
  alias NervesMOTD.Tips
  doctest NervesMOTD.Tips

  test "all" do
    assert [{_title, _content} | _] = Tips.all()
  end

  test "random" do
    assert {_title, _content} = Tips.random()
  end
end
