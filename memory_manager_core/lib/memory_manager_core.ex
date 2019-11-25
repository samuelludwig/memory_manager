defmodule MemoryManagerCore do
  # NOTE: The term "high" is used in this context to refer to the address with the larger numeric value.
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock}

  def add_process(%MemoryState{cpu_processes: process_list} = state, :first_fit, p_name, p_size)
      when p_size > 0 do
    state_with_added_process =
      add_process_to_list_of_processes_in_memory_state_struct(state, :first_fit, p_name, p_size)

    reduced_memory_block = %MemoryBlock{
      start_address: state.os_size + p_size,
      end_address: state.total_memory
    }

    %{state_with_added_process | blocks_of_free_memory: [reduced_memory_block]}
  end

  def add_process(%MemoryState{} = state, _algorithm, _p_name, p_size) when p_size <= 0 do
    state
  end

  defp add_process_to_list_of_processes_in_memory_state_struct(
         %MemoryState{cpu_processes: process_list} = state,
         :first_fit,
         p_name,
         p_size
       ) do
    start_address = state.os_size
    end_address = state.os_size + p_size
    p = %CpuProcess{name: p_name, start_address: start_address, end_address: end_address}
    %{state | cpu_processes: process_list ++ [p]}
  end

  defp get_size_of_memory_block(%MemoryBlock{
         start_address: start_address,
         end_address: end_address
       }) do
    end_address - start_address
  end

  defp get_list_of_valid_spaces_for_process(
         %MemoryState{blocks_of_free_memory: memory_blocks} = state,
         p_size
       ) do
    Enum.filter(memory_blocks, &process_can_fit_in_memory_block?(&1, p_size))
  end

  defp process_can_fit_in_memory_block?(%MemoryBlock{} = block, p_size) do
    get_size_of_memory_block(block) >= p_size
  end
end
