defmodule MemoryManagerCore do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock}

  def add_process(%MemoryState{} = state, algorithm, p_name, p_size) do
    can_fit? = process_can_fit_into_memory?(state, p_size)
    add_process(state, algorithm, p_name, p_size, can_fit?)
  end

  def add_process(state, algorithm, p_name, p_size, can_fit?) when p_size > 0 and can_fit? do
    {memory_block_to_be_replaced, index_of_block} =
      get_memory_block_to_be_replaced_with_index(state, algorithm, p_size)

    state
    |> add_process_to_list_of_processes_in_memory_state_struct(
      p_name,
      p_size,
      memory_block_to_be_replaced
    )
    |> update_blocks_of_free_memory_in_memory_state_struct(
      memory_block_to_be_replaced,
      index_of_block,
      p_size
    )
  end

  def add_process(state, _algorithm, _p_name, p_size, can_fit?)
      when p_size <= 0 or not can_fit? do
    state
  end

  defp update_blocks_of_free_memory_in_memory_state_struct(
         state,
         memory_block_to_be_replaced,
         index_of_block,
         p_size
       ) do
    reduced_memory_block = reduce_size_of_memory_block(memory_block_to_be_replaced, p_size)

    new_memory_block_list =
      replace_memory_block_at_index_in_memory_state_struct(
        state,
        index_of_block,
        reduced_memory_block
      )

    %{state | blocks_of_free_memory: new_memory_block_list}
  end

  defp get_memory_block_to_be_replaced_with_index(state, algorithm, p_size) do
    index_of_block = get_index_of_memory_block_to_be_replaced(state, algorithm, p_size)

    memory_block_to_be_replaced =
      get_memory_block_at_index_in_memory_state_struct(state, index_of_block)

    {memory_block_to_be_replaced, index_of_block}
  end

  defp process_can_fit_into_memory?(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         p_size
       ) do
    sort_memory_blocks_by_size(blocks_of_free_memory, :descending)
    |> List.first()
    |> process_can_fit_in_memory_block?(p_size)
  end

  defp add_process_to_list_of_processes_in_memory_state_struct(
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

  defp reduce_size_of_memory_block(memory_block, p_size) do
    initial_start_address_of_memory_block = memory_block.start_address
    %{memory_block | start_address: initial_start_address_of_memory_block + p_size}
  end

  defp replace_memory_block_at_index_in_list(list_of_memory_blocks, index, new_memory_block) do
    case get_size_of_memory_block(new_memory_block) do
      0 -> List.delete_at(list_of_memory_blocks, index)
      _ -> List.replace_at(list_of_memory_blocks, index, new_memory_block)
    end
  end

  defp replace_memory_block_at_index_in_memory_state_struct(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         index,
         new_memory_block
       ) do
    case get_size_of_memory_block(new_memory_block) do
      0 -> List.delete_at(blocks_of_free_memory, index)
      _ -> List.replace_at(blocks_of_free_memory, index, new_memory_block)
    end
  end

  defp get_memory_block_at_index_in_memory_state_struct(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
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
         %MemoryState{blocks_of_free_memory: memory_blocks},
         p_size
       ) do
    Enum.filter(memory_blocks, &process_can_fit_in_memory_block?(&1, p_size))
  end

  defp process_can_fit_in_memory_block?(memory_block, p_size) do
    get_size_of_memory_block(memory_block) >= p_size
  end

  defp sort_memory_blocks_by_size(list_of_memory_blocks, :ascending) do
    Enum.sort(
      list_of_memory_blocks,
      &(get_size_of_memory_block(&1) >= get_size_of_memory_block(&2))
    )
  end

  defp sort_memory_blocks_by_size(list_of_memory_blocks, :descending) do
    Enum.sort(
      list_of_memory_blocks,
      &(get_size_of_memory_block(&1) <= get_size_of_memory_block(&2))
    )
  end

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :first_fit,
         p_size
       ) do
    Enum.find_index(blocks_of_free_memory, &process_can_fit_in_memory_block?(&1, p_size))
  end

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :best_fit,
         p_size
       ) do
    memory_block_to_replace =
      sort_memory_blocks_by_size(blocks_of_free_memory, :ascending)
      |> Enum.find(&process_can_fit_in_memory_block?(&1, p_size))

    get_index_of_memory_block_in_list(blocks_of_free_memory, memory_block_to_replace)
  end

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :worst_fit,
         p_size
       ) do
    memory_block_to_replace =
      sort_memory_blocks_by_size(blocks_of_free_memory, :descending)
      |> Enum.find(&process_can_fit_in_memory_block?(&1, p_size))

    get_index_of_memory_block_in_list(blocks_of_free_memory, memory_block_to_replace)
  end

  defp get_index_of_memory_block_in_list(list_of_memory_blocks, memory_block) do
    Enum.find_index(list_of_memory_blocks, &(&1 == memory_block))
  end

  defp append_process_to_list_of_processes_in_memory_state_struct(
         %MemoryState{cpu_processes: cpu_processes} = state,
         new_process
       ) do
    %{state | cpu_processes: cpu_processes ++ [new_process]}
  end
end
