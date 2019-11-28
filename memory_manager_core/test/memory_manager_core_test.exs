defmodule MemoryManagerCoreTest do
  use ExUnit.Case

  import MemoryManagerCore
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock}

  setup do
    [
      init_state: MemoryState.new(4096, 512),
      p1_data: %{name: "p1", size: 400},
      p2_data: %{name: "p2", size: 600}
    ]
  end

  describe "add_process/3 with :first_fit algorithm" do
    test "returns an unchanged MemoryState when process size is =< 0", context do
      state = context[:init_state]
      assert state == add_process(state, :first_fit, "p1", 0)
      assert state == add_process(state, :first_fit, "p1", -1)
    end

    test "returns a MemoryState with one process when one process is added with size > 0",
         context do
      state = context[:init_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      new_state = add_process(state, :first_fit, p_name, p_size)

      assert new_state.cpu_processes == [
               %CpuProcess{
                 name: context[:p1_data].name,
                 start_address: context[:init_state].os_size,
                 end_address: context[:init_state].os_size + context[:p1_data].size
               }
             ]
    end

    test "returns a MemoryState with a MemoryBlock that is reduced in size when one process is added",
         context do
      state = context[:init_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      new_state = add_process(state, :first_fit, p_name, p_size)

      assert new_state.blocks_of_free_memory == [
               %MemoryBlock{
                 start_address: p_size + state.os_size,
                 end_address: state.total_memory
               }
             ]
    end

    test "returns a MemoryState with multiple processes when two processes are added with sizes > 0",
         context do
      state = context[:init_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      p_name = context[:p2_data].name
      p_size = context[:p2_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      assert state.cpu_processes == [
               %CpuProcess{
                 name: context[:p1_data].name,
                 start_address: context[:init_state].os_size,
                 end_address: context[:init_state].os_size + context[:p1_data].size
               },
               %CpuProcess{
                 name: context[:p2_data].name,
                 start_address: context[:init_state].os_size + context[:p1_data].size,
                 end_address:
                   context[:init_state].os_size + context[:p1_data].size + context[:p2_data].size
               }
             ]
    end
  end
end
