defmodule MemoryManagerCoreTest do
  use ExUnit.Case

  import MemoryManagerCore
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock}

  setup do
    [
      fresh_state: MemoryState.new(4096, 512),
      complex_state: %MemoryState{
        total_memory: 4000,
        os_size: 400,
        blocks_of_free_memory: [
          %MemoryBlock{start_address: 400, end_address: 600},
          %MemoryBlock{start_address: 800, end_address: 4000}
        ],
        cpu_processes: [
          %CpuProcess{name: "P1", start_address: 600, end_address: 800}
        ]
      },
      state_with_two_processes: %MemoryState{
        total_memory: 4000,
        os_size: 400,
        blocks_of_free_memory: [
          %MemoryBlock{start_address: 400, end_address: 600},
          %MemoryBlock{start_address: 800, end_address: 900},
          %MemoryBlock{start_address: 1200, end_address: 4000}
        ],
        cpu_processes: [
          %CpuProcess{name: "P1", start_address: 600, end_address: 800},
          %CpuProcess{name: "P2", start_address: 900, end_address: 1200}
        ]
      },
      state_with_three_processes: %MemoryState{
        total_memory: 4000,
        os_size: 400,
        blocks_of_free_memory: [
          %MemoryBlock{start_address: 400, end_address: 600},
          %MemoryBlock{start_address: 800, end_address: 900},
          %MemoryBlock{start_address: 950, end_address: 1600},
          %MemoryBlock{start_address: 1800, end_address: 4000}
        ],
        cpu_processes: [
          %CpuProcess{name: "P1", start_address: 600, end_address: 800},
          %CpuProcess{name: "P2", start_address: 900, end_address: 950},
          %CpuProcess{name: "P3", start_address: 1600, end_address: 1800}
        ]
      },
      p1_data: %{name: "p1", size: 400},
      p2_data: %{name: "p2", size: 600}
    ]
  end

  describe "add_process/3" do
    test "returns an unchanged MemoryState when process size is =< 0", context do
      state = context[:fresh_state]
      assert state == add_process(state, :first_fit, "p1", 0)
      assert state == add_process(state, :first_fit, "p1", -1)
    end

    test "returns a MemoryState with one process when one process is added with size > 0",
         context do
      state = context[:fresh_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      new_state = add_process(state, :first_fit, p_name, p_size)

      assert new_state.cpu_processes == [
               %CpuProcess{
                 name: context[:p1_data].name,
                 start_address: context[:fresh_state].os_size,
                 end_address: context[:fresh_state].os_size + context[:p1_data].size
               }
             ]
    end

    test "returns a MemoryState with a MemoryBlock that is reduced in size when one process is added",
         context do
      state = context[:fresh_state]
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
      state = context[:fresh_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      p_name = context[:p2_data].name
      p_size = context[:p2_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      assert state.cpu_processes == [
               %CpuProcess{
                 name: context[:p1_data].name,
                 start_address: context[:fresh_state].os_size,
                 end_address: context[:fresh_state].os_size + context[:p1_data].size
               },
               %CpuProcess{
                 name: context[:p2_data].name,
                 start_address: context[:fresh_state].os_size + context[:p1_data].size,
                 end_address:
                   context[:fresh_state].os_size + context[:p1_data].size + context[:p2_data].size
               }
             ]
    end

    test "returns a MemoryState with correctly reduced memory blocks when two processes are added with size > 0",
         context do
      state = context[:fresh_state]
      p_name = context[:p1_data].name
      p_size = context[:p1_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      p_name = context[:p2_data].name
      p_size = context[:p2_data].size
      state = add_process(state, :first_fit, p_name, p_size)

      assert state.blocks_of_free_memory == [
               %MemoryBlock{
                 start_address: state.os_size + context[:p1_data].size + context[:p2_data].size,
                 end_address: state.total_memory
               }
             ]
    end

    test "returns a MemoryState with no memory blocks when all space has been taken up by processes",
         context do
      state = context[:fresh_state]
      p_size = state.total_memory - state.os_size
      new_state = add_process(state, :first_fit, "Pn", p_size)
      assert new_state.blocks_of_free_memory == []
    end

    test "returns an unchanged MemoryState when a process is given that cannot fit into any available memory blocks",
         context do
      state = context[:fresh_state]
      p_size = state.total_memory + 1
      assert state == add_process(state, :first_fit, "fail", p_size)
    end

    test "returns correct MemoryState when using Best-Fit algorithm", context do
      state = context[:complex_state]

      assert add_process(state, :best_fit, "Px", 100) ==
               %MemoryState{
                 total_memory: 4000,
                 os_size: 400,
                 blocks_of_free_memory: [
                   %MemoryBlock{start_address: 500, end_address: 600},
                   %MemoryBlock{start_address: 800, end_address: 4000}
                 ],
                 cpu_processes: [
                   %CpuProcess{name: "P1", start_address: 600, end_address: 800},
                   %CpuProcess{name: "Px", start_address: 400, end_address: 500}
                 ]
               }
    end

    test "returns correct MemoryState when using Worst-Fit algorithm", context do
      state = context[:complex_state]

      assert add_process(state, :worst_fit, "Px", 100) ==
               %MemoryState{
                 total_memory: 4000,
                 os_size: 400,
                 blocks_of_free_memory: [
                   %MemoryBlock{start_address: 400, end_address: 600},
                   %MemoryBlock{start_address: 900, end_address: 4000}
                 ],
                 cpu_processes: [
                   %CpuProcess{name: "P1", start_address: 600, end_address: 800},
                   %CpuProcess{name: "Px", start_address: 800, end_address: 900}
                 ]
               }
    end
  end

  describe "remove_process/2" do
    test "returns a MemoryState with a removed process", context do
      state = context[:complex_state]
      new_state = remove_process(state, "P1")
      assert new_state.cpu_processes == []
    end

    test "returns an unchanged MemoryState when an invalid process name is given", context do
      state = context[:complex_state]
      assert remove_process(state, "failure") == state
    end

    test "returns a MemoryState with an altered MemoryBlock list", context do
      state = context[:complex_state]
      new_state = remove_process(state, "P1")
      refute new_state.blocks_of_free_memory == state.blocks_of_free_memory
    end

    test "returns a MemoryState with each adjacent memory block combined", context do
      state = context[:complex_state]
      new_state = remove_process(state, "P1")

      assert new_state.blocks_of_free_memory == [
               %MemoryBlock{start_address: 400, end_address: 4000}
             ]
    end
  end

  describe "compact_memory/1" do
    test "returns an unaltered MemoryState when there are no processes present", context do
      state = context[:fresh_state]
      assert compact_memory(state) == state
    end

    test "returns a MemoryState with contiguous processes", context do
      state1 = context[:state_with_two_processes] |> compact_memory()
      state2 = context[:state_with_three_processes] |> compact_memory()

      assert state1.cpu_processes == [
               %CpuProcess{name: "P1", start_address: 400, end_address: 600},
               %CpuProcess{name: "P2", start_address: 600, end_address: 900}
             ]

      assert state2.cpu_processes == [
               %CpuProcess{name: "P1", start_address: 400, end_address: 600},
               %CpuProcess{name: "P2", start_address: 600, end_address: 650},
               %CpuProcess{name: "P3", start_address: 650, end_address: 850}
             ]
    end
  end
end
