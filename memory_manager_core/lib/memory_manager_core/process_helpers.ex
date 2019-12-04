defmodule MemoryManagerCore.ProcessHelpers do
  alias MemoryManagerCore.{MemoryState, CpuProcess, MemoryHelpers}

  alias MemoryHelpers, as: MH

  def add_process(%MemoryState{} = state, algorithm, p_name, p_size) do
    can_fit? = process_can_fit_into_memory?(state, p_size)
    add_process(state, algorithm, p_name, p_size, can_fit?)
  end

  def remove_process(%MemoryState{} = state, p_name) do
    process_exists? = process_exists_in_memory_state_struct?(state, p_name)
    remove_process(state, p_name, process_exists?)
  end

  def derive_name_size_tuples_from_list_of_processes(list) do
    Enum.map(list, fn process ->
      {process.name, get_size_of_process_in_list_by_name(list, process.name)}
    end)
  end

  def add_process_to_state_for_each_name_size_tuple_in_list(list_of_tuples, state) do
    Enum.reduce(list_of_tuples, state, fn {p_name, p_size}, acc ->
      add_process(acc, :first_fit, p_name, p_size)
    end)
  end

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

  def get_process_from_state_struct_by_name(
        %MemoryState{cpu_processes: cpu_processes},
        p_name
      ) do
    Enum.find(cpu_processes, fn process -> process.name == p_name end)
  end

  defp add_process(state, algorithm, p_name, p_size, can_fit?) when p_size > 0 and can_fit? do
    {memory_block_to_be_replaced, index_of_block} =
      MH.get_memory_block_to_be_replaced_with_index(state, algorithm, p_size)

    state
    |> add_process_to_list_of_processes_in_memory_state_struct(
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
    |> MH.add_memory_block_in_place_of_removed_process(p_name)
    |> remove_process_from_memory_state_struct(p_name)
    |> MH.combine_adjacent_memory_blocks()
  end

  defp remove_process(state, _p_name, process_exists?) when not process_exists? do
    state
  end

  defp remove_process_from_memory_state_struct(
         %MemoryState{cpu_processes: cpu_processes} = state,
         p_name
       ) do
    index = find_index_of_process_in_state_struct_by_name(state, p_name)
    new_process_list = List.delete_at(cpu_processes, index)
    %{state | cpu_processes: new_process_list}
  end

  defp append_process_to_list_of_processes_in_memory_state_struct(
         %MemoryState{cpu_processes: cpu_processes} = state,
         new_process
       ) do
    %{state | cpu_processes: cpu_processes ++ [new_process]}
  end

  defp get_size_of_process_in_list_by_name(list_of_processes, name) do
    process = Enum.find(list_of_processes, fn p -> p.name == name end)
    process.end_address - process.start_address
  end
end
