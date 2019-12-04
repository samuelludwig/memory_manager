defmodule MemoryManagerCliTest do
  use ExUnit.Case
  doctest MemoryManagerCli

  test "greets the world" do
    assert MemoryManagerCli.hello() == :world
  end
end
