defmodule MemoryManagerCore do
  # NOTE: The term "high" is used in this context to refer to the address with the larger numeric value.
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock}

  def add_process(
        %MemoryState{cpu_processes: process_list, blocks_of_free_memory: blocks_of_free_memory} =
          state,
        :first_fit,
        p_name,
        p_size
      )
      when p_size > 0 do
    index_of_first_replacable_memory_block =
      Enum.find_index(blocks_of_free_memory, &process_can_fit_in_memory_block?(&1, p_size))

    first_replacable_memory_block =
      get_memory_block_at_index_in_list(
        blocks_of_free_memory,
        index_of_first_replacable_memory_block
      )

    state_with_added_process =
      add_process_to_list_of_processes_in_memory_state_struct(
        state,
        :first_fit,
        p_name,
        p_size,
        first_replacable_memory_block
      )

    reduced_memory_block = reduce_size_of_memory_block(first_replacable_memory_block, p_size)

    new_memory_block_list =
      replace_memory_block_at_index_in_list(
        blocks_of_free_memory,
        reduced_memory_block,
        index_of_first_replacable_memory_block
      )

    %{state_with_added_process | blocks_of_free_memory: new_memory_block_list}
  end

  def add_process(%MemoryState{} = state, _algorithm, _p_name, p_size) when p_size <= 0 do
    state
  end

  defp add_process_to_list_of_processes_in_memory_state_struct(
         %MemoryState{cpu_processes: process_list, blocks_of_free_memory: blocks_of_free_memory} =
           state,
         :first_fit,
         p_name,
         p_size,
         memory_block_being_replaced
       ) do
    start_address = memory_block_being_replaced.start_address
    end_address = start_address + p_size
    p = %CpuProcess{name: p_name, start_address: start_address, end_address: end_address}
    %{state | cpu_processes: process_list ++ [p]}
  end

  defp reduce_size_of_memory_block(%MemoryBlock{} = memory_block, p_size) do
    initial_start_address_of_memory_block = memory_block.start_address
    %{memory_block | start_address: initial_start_address_of_memory_block + p_size}
  end

  defp replace_memory_block_at_index_in_list(list_of_memory_blocks, new_memory_block, index) do
    List.replace_at(list_of_memory_blocks, index, new_memory_block)
  end

  defp get_memory_block_at_index_in_list(list_of_memory_blocks, index) do
    Enum.at(list_of_memory_blocks, index)
  end

  defp get_memory_block_at_index_in_memory_state_struct(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory} = state,
         index
       ) do
    Enum.at(blocks_of_free_memory, index)
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

  defp sort_memory_blocks_by_size(order \\ :descending, list_of_memory_blocks)

  defp sort_memory_blocks_by_size(:descending, list_of_memory_blocks) do
    Enum.sort(
      list_of_memory_blocks,
      &(get_size_of_memory_block(&1) >= get_size_of_memory_block(&2))
    )
  end
end
