defmodule NervesMotdTest do
  use ExUnit.Case
  doctest NervesMotd

  test "greets the world" do
    assert NervesMotd.hello() == :world
  end
end
