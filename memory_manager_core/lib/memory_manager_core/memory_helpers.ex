defmodule MemoryManagerCore.MemoryHelpers do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryBlock, ProcessHelpers}

  alias ProcessHelpers, as: PH

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

  defp get_index_of_memory_block_in_list(list_of_memory_blocks, memory_block) do
    Enum.find_index(list_of_memory_blocks, &(&1 == memory_block))
  end
end
