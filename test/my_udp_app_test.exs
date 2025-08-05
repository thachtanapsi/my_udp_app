defmodule MyUdpAppTest do
  use ExUnit.Case
  doctest MyUdpApp

  test "greets the world" do
    assert MyUdpApp.hello() == :world
  end
end
