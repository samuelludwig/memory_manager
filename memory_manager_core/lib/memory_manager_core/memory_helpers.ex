defmodule MemoryManagerCore.MemoryHelpers do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock, ProcessHelpers}

  alias ProcessHelpers, as: PH

  # I could have approached this in a few different ways, in this particular
  # implementation I opted to simply rebuild the MemoryState as if it were brand
  # new, readding each process, one after another, using the add_process/4 function
  def compact_memory(%MemoryState{cpu_processes: cpu_processes} = state) do
    new_state = MemoryState.new(state.total_memory, state.os_size)

    PH.derive_name_size_tuples_from_list_of_processes(cpu_processes)
    |> PH.add_process_to_state_for_each_name_size_tuple_in_list(new_state)
  end

  def update_blocks_of_free_memory_in_memory_state_struct(
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

  def get_memory_block_to_be_replaced_with_index(state, algorithm, p_size) do
    index_of_block = get_index_of_memory_block_to_be_replaced(state, algorithm, p_size)

    memory_block_to_be_replaced =
      get_memory_block_at_index_in_memory_state_struct(state, index_of_block)

    {memory_block_to_be_replaced, index_of_block}
  end

  def sort_memory_blocks_by_size(list_of_memory_blocks, :ascending) do
    Enum.sort(
      list_of_memory_blocks,
      &(get_size_of_memory_block(&1) <= get_size_of_memory_block(&2))
    )
  end

  def sort_memory_blocks_by_size(list_of_memory_blocks, :descending) do
    Enum.sort(
      list_of_memory_blocks,
      &(get_size_of_memory_block(&1) >= get_size_of_memory_block(&2))
    )
  end

  def get_size_of_memory_block(%MemoryBlock{
        start_address: start_address,
        end_address: end_address
      }) do
    end_address - start_address
  end

  def add_memory_block_in_place_of_removed_process(state, p_name) do
    %CpuProcess{name: _name, start_address: start_address, end_address: end_address} =
      PH.get_process_from_state_struct_by_name(state, p_name)

    new_memory_block = MemoryBlock.new(start_address: start_address, end_address: end_address)

    new_block_list =
      (state.blocks_of_free_memory ++ [new_memory_block])
      |> sort_memory_blocks_by_start_address()

    %{state | blocks_of_free_memory: new_block_list}
  end

  def combine_adjacent_memory_blocks(
        %MemoryState{blocks_of_free_memory: blocks_of_free_memory} = state
      ) do
    updated_list = combine_adjacent_memory_blocks(blocks_of_free_memory)

    %{state | blocks_of_free_memory: updated_list}
  end

  def combine_adjacent_memory_blocks(list_of_memory_blocks)
      when is_list(list_of_memory_blocks) do
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

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :first_fit,
         p_size
       ) do
    Enum.find_index(
      blocks_of_free_memory,
      &PH.process_can_fit_in_memory_block?(&1, p_size)
    )
  end

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :best_fit,
         p_size
       ) do
    memory_block_to_replace =
      sort_memory_blocks_by_size(blocks_of_free_memory, :ascending)
      |> Enum.find(&PH.process_can_fit_in_memory_block?(&1, p_size))

    get_index_of_memory_block_in_list(blocks_of_free_memory, memory_block_to_replace)
  end

  defp get_index_of_memory_block_to_be_replaced(
         %MemoryState{blocks_of_free_memory: blocks_of_free_memory},
         :worst_fit,
         p_size
       ) do
    memory_block_to_replace =
      sort_memory_blocks_by_size(blocks_of_free_memory, :descending)
      |> Enum.find(&PH.process_can_fit_in_memory_block?(&1, p_size))

    get_index_of_memory_block_in_list(blocks_of_free_memory, memory_block_to_replace)
  end

  defp reduce_size_of_memory_block(memory_block, p_size) do
    initial_start_address_of_memory_block = memory_block.start_address
    %{memory_block | start_address: initial_start_address_of_memory_block + p_size}
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

  defp get_index_of_memory_block_in_list(list_of_memory_blocks, memory_block) do
    Enum.find_index(list_of_memory_blocks, &(&1 == memory_block))
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
