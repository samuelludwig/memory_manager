defmodule MemoryManagerCoreTest do
  use ExUnit.Case
  doctest MemoryManagerCore

  test "greets the world" do
    assert MemoryManagerCore.hello() == :world
  end
end
