defmodule MemoryManagerCli.Cli do
  alias MemoryManagerCore.{CpuProcess, MemoryBlock, MemoryState, SimParameters}

  @state "./config/state.json"

  def main(_args) do
    IO.puts("Welcome to Sam's Terrible Memory Manager!")
    print_help_message()
    print_state()
    receive_command()
  end

  def receive_command() do
    IO.gets("\n>")
    |> String.trim()
    |> String.split(" ")
    |> execute_command()
  end

  def execute_command(["n"]) do
    %SimParameters{action: :new}
    |> MemoryManagerCore.calculate_state()
    |> write_state()

    # print_state()
  end

  def execute_command(["a", "f", size]) when size > 150 and rem(size, 50) == 0 do
    state = read_state()
    %SimParameters{state: state, action: :add, args: [algorithm: :first_fit, name: "P#{get_number_of_processes(state)}", size: size]}
    |> MemoryManagerCore.calculate_state()
    |> write_state

    # print_state()
  end

  def execute_command(["a", "b", size]) when size > 150 and rem(size, 50) == 0 do
    state = read_state()
    %SimParameters{state: state, action: :add, args: [algorithm: :first_fit, name: "P#{get_number_of_processes(state)}", size: size]}
    |> MemoryManagerCore.calculate_state()
    |> write_state

    # print_state()
  end

  def execute_command(["a", "w", size]) when size > 150 and rem(size, 50) == 0 do
    state = read_state()
    %SimParameters{state: state, action: :add, args: [algorithm: :first_fit, name: "P#{get_number_of_processes(state)}", size: size]}
    |> MemoryManagerCore.calculate_state()
    |> write_state

    # print_state()
  end

  def execute_command(["r", name]) do
    state = read_state()
    %SimParameters{state: state, action: :remove, args: [name: name]}
    |> MemoryManagerCore.calculate_state()
    |> write_state

    # print_state()
  end

  def execute_command(["c"]) do
    state = read_state()
    %SimParameters{state: state, action: :compact}
    |> MemoryManagerCore.calculate_state()
    |> write_state()

    # print_state()
  end

  def execute_command(_) do
    IO.puts("ERROR: Invalid input!")
    print_help_message()
    print_state()
  end

  def print_help_message() do
    IO.puts(
      """
      \n @
      \n @ n 'RET'
      \n @ \\__ Start from scratch with a new memory state
      \n @
      \n @ a f_or_b_or_w size 'RET'
      \n @ \\__ Add a process of size `size` into the memory state, according to the
      \n @      algorithm indicated by the letter in the second field (f = first_fit, b = best_fit, w = worst_fit)
      \n @
      \n @ r name 'RET'
      \n @ \\__ Remove the process with name `name` from the memory state
      \n @
      \n @ c 'RET'
      \n @ \\__ Compact the current memory state
      \n @ \n
      """
    )
  end

  def print_state() do
    %MemoryState{
      total_memory: total_memory,
      os_size: os_size,
      blocks_of_free_memory: blocks_of_free_memory,
      cpu_processes: cpu_processes
    } = read_state()

  end

  def write_state(%MemoryState{} = state) do
    jsonified_state = encode_state_to_json(state)
    File.write!(@state, jsonified_state)
  end

  def read_state() do
    get_state_string_from_config()
    |> decode_state_from_json()
  end

  def decode_state_from_json(state_string) do
    state = Jason.decode!(state_string, keys: :atoms!)
    blocks =  Enum.map(state.blocks_of_free_memory, fn block ->
      MemoryBlock.new(block)
    end)

    state = %{state | blocks_of_free_memory: blocks}

    processes = Enum.map(state.cpu_processes, fn process ->
      CpuProcess.new(process)
    end)

    state = %{state | cpu_processes: processes}

    MemoryState.new(state)
  end

  def get_state_string_from_config() do
    File.read!(@state)
  end

  def encode_state_to_json(state) do
    state
    |> convert_cpu_processes_to_maps()
    |> convert_memory_blocks_to_maps()
    |> Map.from_struct()
    |> Jason.encode!()
  end

  def convert_cpu_processes_to_maps(%MemoryState{cpu_processes: cpu_processes} = state) do
    converted_processes =
      Enum.map(cpu_processes, fn process -> Map.from_struct(process) end)
    %{state | cpu_processes: converted_processes}
  end

  def convert_memory_blocks_to_maps(%MemoryState{blocks_of_free_memory: memory_blocks} = state) do
    converted_memory_blocks =
      Enum.map(memory_blocks, fn block -> Map.from_struct(block) end)
    %{state | blocks_of_free_memory: converted_memory_blocks}
  end

  def get_number_of_processes(state) do
    Enum.count(state.cpu_processes)
  end
end
