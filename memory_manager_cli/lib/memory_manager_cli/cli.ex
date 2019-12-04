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
    
  end

  defp write_state(%MemoryManagerCore.MemoryState{} = state) do
    
  end

  defp print_state() do
    
  end
end
