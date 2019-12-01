defmodule MemoryManagerCore.ProcessHelpers do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock, MemoryHelpers}

  alias MemoryHelpers, as: MH

  def process_can_fit_into_memory?(
        %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
        p_size
      ) do
    MH.sort_memory_blocks_by_size(blocks_of_free_memory, :descending)
    |> List.first()
    |> process_can_fit_in_memory_block?(p_size)
  end

  def find_index_of_process_in_state_struct_by_name(
        %MemoryState{cpu_processes: cpu_processes},
        p_name
      ) do
    Enum.find_index(cpu_processes, fn process -> process.name == p_name end)
  end

  def add_process_to_list_of_processes_in_memory_state_struct(
        state,
        p_name,
        p_size,
        memory_block_being_replaced
      ) do
    start_address = memory_block_being_replaced.start_address
    end_address = start_address + p_size
    p = %CpuProcess{name: p_name, start_address: start_address, end_address: end_address}
    append_process_to_list_of_processes_in_memory_state_struct(state, p)
  end

  def process_can_fit_in_memory_block?(memory_block, p_size) do
    MH.get_size_of_memory_block(memory_block) >= p_size
  end

  def process_exists_in_memory_state_struct?(%MemoryState{cpu_processes: cpu_processes}, p_name) do
    Enum.any?(cpu_processes, fn process -> process.name == p_name end)
  end

  defp get_process_from_state_struct_by_index(%MemoryState{cpu_processes: cpu_processes}, index) do
    Enum.at(cpu_processes, index)
  end

  defp get_list_of_valid_spaces_for_process(
         %MemoryState{blocks_of_free_memory: memory_blocks},
         p_size
       ) do
    Enum.filter(memory_blocks, &process_can_fit_in_memory_block?(&1, p_size))
  end

  defp append_process_to_list_of_processes_in_memory_state_struct(
         %MemoryState{cpu_processes: cpu_processes} = state,
         new_process
       ) do
    %{state | cpu_processes: cpu_processes ++ [new_process]}
  end

  def get_process_from_state_struct_by_name(
        %MemoryState{cpu_processes: cpu_processes} = state,
        p_name
      ) do
    Enum.find(cpu_processes, fn process -> process.name == p_name end)
  end
end
