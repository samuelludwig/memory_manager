defmodule MemoryManagerCore do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock, ProcessHelpers, MemoryHelpers}

  alias MemoryHelpers, as: MH
  alias ProcessHelpers, as: PH

  def add_process(%MemoryState{} = state, algorithm, p_name, p_size) do
    can_fit? = PH.process_can_fit_into_memory?(state, p_size)
    add_process(state, algorithm, p_name, p_size, can_fit?)
  end

  def remove_process(%MemoryState{} = state, p_name) do
    process_exists? = PH.process_exists_in_memory_state_struct?(state, p_name)
    remove_process(state, p_name, process_exists?)
  end

  defp add_process(state, algorithm, p_name, p_size, can_fit?) when p_size > 0 and can_fit? do
    {memory_block_to_be_replaced, index_of_block} =
      MH.get_memory_block_to_be_replaced_with_index(state, algorithm, p_size)

    state
    |> PH.add_process_to_list_of_processes_in_memory_state_struct(
      p_name,
      p_size,
      memory_block_to_be_replaced
    )
    |> MH.update_blocks_of_free_memory_in_memory_state_struct(
      memory_block_to_be_replaced,
      index_of_block,
      p_size
    )
  end

  defp add_process(state, _algorithm, _p_name, p_size, can_fit?)
       when p_size <= 0 or not can_fit? do
    state
  end

  defp remove_process(state, p_name, process_exists?)
       when process_exists? do
    state
    |> add_memory_block_in_place_of_removed_process(p_name)
    |> remove_process_from_memory_state_struct(p_name)
    |> combine_adjacent_memory_blocks()
  end

  defp remove_process(state, _p_name, process_exists?) when not process_exists? do
    state
  end

  defp add_memory_block_in_place_of_removed_process(state, p_name) do
    %CpuProcess{name: _name, start_address: start_address, end_address: end_address} =
      PH.get_process_from_state_struct_by_name(state, p_name)

    new_memory_block = MemoryBlock.new(start_address: start_address, end_address: end_address)

    new_block_list =
      (state.blocks_of_free_memory ++ [new_memory_block])
      |> sort_memory_blocks_by_start_address()

    %{state | blocks_of_free_memory: new_block_list}
  end

  defp remove_process_from_memory_state_struct(
         %MemoryState{cpu_processes: cpu_processes} = state,
         p_name
       ) do
    index = PH.find_index_of_process_in_state_struct_by_name(state, p_name)
    new_process_list = List.delete_at(cpu_processes, index)
    %{state | cpu_processes: new_process_list}
  end

  def combine_adjacent_memory_blocks(
        %MemoryState{blocks_of_free_memory: blocks_of_free_memory} = state
      ) do
    updated_list = combine_adjacent_memory_blocks(blocks_of_free_memory)

    %{state | blocks_of_free_memory: updated_list}
  end

  def combine_adjacent_memory_blocks(list_of_memory_blocks) when is_list(list_of_memory_blocks) do
    combine_adjacent_memory_blocks(list_of_memory_blocks, 0)
  end

  def combine_adjacent_memory_blocks(list_of_memory_blocks, index_of_current_block) do
    case Enum.at(list_of_memory_blocks, index_of_current_block) do
      nil ->
        list_of_memory_blocks

      _ ->
        if start_address_of_next_block_equals_end_address_of_block_at_index?(
             list_of_memory_blocks,
             index_of_current_block
           ) do
          combine_next_and_current_block_at_index(list_of_memory_blocks, index_of_current_block)
          |> combine_adjacent_memory_blocks(index_of_current_block)
        else
          combine_adjacent_memory_blocks(list_of_memory_blocks, index_of_current_block + 1)
        end
    end
  end

  defp sort_memory_blocks_by_start_address(list_of_memory_blocks) do
    Enum.sort(list_of_memory_blocks, &(&1.start_address <= &2.start_address))
  end

  defp combine_next_and_current_block_at_index(list_of_blocks, index_of_current_block) do
    list_of_blocks
    |> set_current_blocks_end_address_to_next_blocks_end_address(index_of_current_block)
    |> remove_memory_block_from_list_at_index(index_of_current_block + 1)
  end

  defp set_current_blocks_end_address_to_next_blocks_end_address(
         list_of_blocks,
         index_of_current_block
       ) do
    current_block = get_memory_block_at_index_from_list(list_of_blocks, index_of_current_block)
    next_block = get_memory_block_at_index_from_list(list_of_blocks, index_of_current_block + 1)
    combined_block = %{current_block | end_address: next_block.end_address}
    List.replace_at(list_of_blocks, index_of_current_block, combined_block)
  end

  defp get_start_address_of_next_block_in_list(list_of_memory_blocks, index_of_current_block) do
    case Enum.at(list_of_memory_blocks, index_of_current_block + 1) do
      %MemoryBlock{start_address: start_address} -> start_address
      _ -> 0
    end
  end

  defp start_address_of_next_block_equals_end_address_of_block_at_index?(
         list_of_memory_blocks,
         index_of_current_block
       ) do
    current_block = Enum.at(list_of_memory_blocks, index_of_current_block)

    current_block.end_address ==
      get_start_address_of_next_block_in_list(list_of_memory_blocks, index_of_current_block)
  end

  defp remove_memory_block_from_list_at_index(list_of_memory_blocks, index) do
    List.delete_at(list_of_memory_blocks, index)
  end

  defp get_memory_block_at_index_from_list(list_of_memory_blocks, index) do
    Enum.at(list_of_memory_blocks, index)
  end
end
