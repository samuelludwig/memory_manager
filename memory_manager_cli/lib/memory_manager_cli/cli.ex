defmodule MemoryManagerCli.Cli do
  alias MemoryManagerCore.{CpuProcess, MemoryBlock, MemoryState, SimParameters}

  @state "./config/state.json"
  @bytes_per_char 50

  def main(_args) do
    IO.puts("Welcome to Sam's Terrible Memory Manager!")
    print_help_message()
    print_state()
    receive_command()
  end

  def receive_command() do
    command_args =
      IO.gets("\n>")
      |> String.trim()
      |> String.split(" ")

    if List.first(command_args) == "a" do
      size = List.last(command_args)
      List.replace_at(command_args, 2, String.to_integer(size))
      |> execute_command()
    else
      execute_command(command_args)
    end
  end

  def execute_command(["n"]) do
    %SimParameters{action: :new}
    |> MemoryManagerCore.calculate_state()
    |> write_state()

    print_state()
    receive_command()
  end

  def execute_command(["a", "f", size]) when size > (5 * @bytes_per_char) and rem(size, @bytes_per_char) == 0 do
    state = read_state()

    %SimParameters{
      state: state,
      action: :add,
      args: [algorithm: :first_fit, name: "P#{get_highest_process_number(state)}", size: size]
    }
    |> MemoryManagerCore.calculate_state()
    |> write_state

    print_state()
    receive_command()
  end

  def execute_command(["a", "b", size]) when size > (5 * @bytes_per_char)and rem(size, @bytes_per_char) == 0 do
    state = read_state()

    %SimParameters{
      state: state,
      action: :add,
      args: [algorithm: :best_fit, name: "P#{get_highest_process_number(state)}", size: size]
    }
    |> MemoryManagerCore.calculate_state()
    |> write_state

    print_state()
    receive_command()
  end

  def execute_command(["a", "w", size]) when size > (5 * @bytes_per_char)and rem(size, @bytes_per_char) == 0 do
    state = read_state()

    %SimParameters{
      state: state,
      action: :add,
      args: [algorithm: :worst_fit, name: "P#{get_highest_process_number(state)}", size: size]
    }
    |> MemoryManagerCore.calculate_state()
    |> write_state

    print_state()
    receive_command()
  end

  def execute_command(["r", name]) do
    state = read_state()

    %SimParameters{state: state, action: :remove, args: [name: name]}
    |> MemoryManagerCore.calculate_state()
    |> write_state

    print_state()
    receive_command()
  end

  def execute_command(["c"]) do
    state = read_state()

    %SimParameters{state: state, action: :compact}
    |> MemoryManagerCore.calculate_state()
    |> write_state()

    print_state()
    receive_command()
  end

  def execute_command(_) do
    IO.puts("ERROR: Invalid input!")
    print_help_message()
    print_state()
    receive_command()
  end

  def print_help_message() do
    IO.puts("""
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
    """)
  end

  def print_state() do
    state = read_state()

    print_state_ascii_end(state)
    print_state_ascii_gap(state)
    print_state_ascii_middle(state)
    print_state_ascii_gap(state)
    print_state_ascii_end(state)
    print_memory_markers(state)
  end

  def print_state_ascii_end(%MemoryState{} = state) do
    IO.puts("#{os_ascii_end(state)}" <> "#{process_and_memory_ascii_end(state)}")
  end

  def print_state_ascii_gap(state) do
    IO.puts("#{os_ascii_gap(state)}" <> "#{process_and_memory_ascii_gap(state)}")
  end

  def print_state_ascii_middle(state) do
    IO.puts("#{os_ascii_middle(state)}" <> "#{process_and_memory_ascii_middle(state)}")
  end

  def print_memory_markers(state) do
    IO.puts("#{print_carrots(state)}")
    IO.puts("#{print_pipes(state)}")
      IO.puts("#{print_thousands(state)}")
  end

  def print_carrots(state) do
    String.duplicate(" ", div(1000, @bytes_per_char))
    |> String.replace_suffix(" ", "^")
    |> String.duplicate(div(state.total_memory, 1000))
  end

  def print_pipes(state) do
    String.duplicate(" ", div(1000, @bytes_per_char))
    |> String.replace_suffix(" ", "|")
    |> String.duplicate(div(state.total_memory, 1000))
  end

  def print_thousands(state) do
    String.duplicate(" ", div(1000, @bytes_per_char))
    |> String.replace_suffix(" ", "k")
    |> String.duplicate(div(state.total_memory, 1000))
  end

  def process_and_memory_ascii_end(state) do
    put_processes_and_memory_blocks_into_sorted_list(state)
    |> Enum.reduce("", fn item, acc ->
      case item do
        %CpuProcess{start_address: start_address, end_address: end_address} ->
          acc <> String.duplicate("#", div(end_address - start_address, @bytes_per_char))

        %MemoryBlock{start_address: start_address, end_address: end_address} ->
          acc <> String.duplicate("-", div(end_address - start_address, @bytes_per_char))
      end
    end)
  end

  def os_ascii_end(%MemoryState{os_size: os_size}) do
    String.duplicate("#", div(os_size, @bytes_per_char))
  end

  def os_ascii_gap(%MemoryState{os_size: os_size}) do
    String.duplicate(" ", div(os_size, @bytes_per_char))
    |> String.replace_prefix(" ", "#")
    |> String.replace_suffix(" ", "#")
  end

  def process_and_memory_ascii_gap(state) do
    put_processes_and_memory_blocks_into_sorted_list(state)
    |> Enum.reduce("", fn item, acc ->
      case item do
        %CpuProcess{start_address: start_address, end_address: end_address} ->
          str =
            String.duplicate(" ", div(end_address - start_address, @bytes_per_char))
            |> String.replace_prefix(" ", "#")
            |> String.replace_suffix(" ", "#")
          acc <> str

        %MemoryBlock{start_address: start_address, end_address: end_address} ->
          acc <> String.duplicate(" ", div(end_address - start_address, @bytes_per_char))
      end
    end)
  end

  def os_ascii_middle(%MemoryState{os_size: os_size}) do
    base = "# OS "
    cap = String.duplicate(" ", div(os_size, @bytes_per_char) - 5) |> String.replace_suffix(" ", "#")
    base <> cap
  end

  def process_and_memory_ascii_middle(state) do
    put_processes_and_memory_blocks_into_sorted_list(state)
    |> Enum.reduce("", fn item, acc ->
      case item do
        %CpuProcess{name: name, start_address: start_address, end_address: end_address} ->
          base =
            "# #{name} "
          cap =
            String.duplicate(" ", div(end_address - start_address, @bytes_per_char) - 6)
            |> String.replace_suffix(" ", "#")
          acc <> base <> cap

        %MemoryBlock{start_address: start_address, end_address: end_address} ->
          acc <> String.duplicate(" ", div(end_address - start_address, @bytes_per_char))
      end
    end)
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

    blocks =
      Enum.map(state.blocks_of_free_memory, fn block ->
        MemoryBlock.new(block)
      end)

    state = %{state | blocks_of_free_memory: blocks}

    processes =
      Enum.map(state.cpu_processes, fn process ->
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
    converted_processes = Enum.map(cpu_processes, fn process -> Map.from_struct(process) end)
    %{state | cpu_processes: converted_processes}
  end

  def convert_memory_blocks_to_maps(%MemoryState{blocks_of_free_memory: memory_blocks} = state) do
    converted_memory_blocks = Enum.map(memory_blocks, fn block -> Map.from_struct(block) end)
    %{state | blocks_of_free_memory: converted_memory_blocks}
  end

  def get_highest_process_number(%MemoryState{cpu_processes: cpu_processes}) when length(cpu_processes) > 0 do
    number =
      Enum.map(cpu_processes, fn process ->
      "P" <> num = process.name
      num |> String.to_integer()
    end)
    |> Enum.max()
    |> Kernel.+(1)

    if number < 10, do: "0" <> "#{number}"
  end

  def get_highest_process_number(%MemoryState{cpu_processes: cpu_processes}) when length(cpu_processes) == 0 do
    "00"
  end

  def put_processes_and_memory_blocks_into_sorted_list(%MemoryState{
        blocks_of_free_memory: blocks_of_free_memory,
        cpu_processes: cpu_processes
      }) do
    merged_list = cpu_processes ++ blocks_of_free_memory
    Enum.sort(merged_list, &(&1.start_address <= &2.start_address))
  end
end
