defmodule MemoryManagerCoreTest do
  use ExUnit.Case

  import MemoryManagerCore

  describe "add_process/3" do
    test "returns an unchanged MemoryState when process size is =< 0" do
      state = MemoryManagerCore.MemoryState.new(4096, 512)
      assert state == add_process(state, "p1", 0)
      assert state == add_process(state, "p1", -1)
    end
  end
end
