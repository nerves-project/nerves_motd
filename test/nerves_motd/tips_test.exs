defmodule NervesMOTD.TipsTest do
  use ExUnit.Case
  alias NervesMOTD.Tips
  doctest NervesMOTD.Tips

  @extra_tip """
  There are only two hard things in Computer Science: cache invalidation and naming things.
  """

  test "all/1 returns a list of default tips" do
    assert [tip | _] = Tips.all()
    assert is_binary(tip)
  end

  test "all/1 with extra tips returns tips that contain extra tips" do
    tips = Tips.all(extra_tips: [@extra_tip])
    assert @extra_tip in tips
  end

  test "random/1 returns a string" do
    tip = Tips.random(extra_tips: [@extra_tip])
    assert is_binary(tip)
  end
end
