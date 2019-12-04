defmodule MemoryManagerCli.Cli do
  def main(_args) do
    IO.puts("Welcome to Sam's Terrible Memory Manager!")
    print_help_message()
    print_state()
    recieve_command()
  end

  defp receive_command() do
    IO.gets("\n>")
    |> String.trim()
    |> String.split(" ")
    |> execute_command()
  end

  defp execute_command(["n"]) do
    %SimParameters{action: :new}
    |> MemoryManagerCore.calculate_state()
    |> write_state()

    print_state()
  end

  defp print_help_message() do
    IO.puts(
      """
      \n @
      \n @ ENTER
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

  defp write_state(%MemoryManagerCore.MemoryState{} = state) do
    
  end

  defp print_state() do
    
  end
end
