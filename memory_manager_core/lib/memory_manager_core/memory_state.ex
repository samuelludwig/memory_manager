defmodule MemoryManagerCore.MemoryState do
  defstruct ~w[total_memory os_size cpu_processes blocks_of_free_memory]a

  @type t :: %__MODULE__{
          total_memory: integer(),
          os_size: integer(),
          cpu_processes: [CpuProcess.t()],
          blocks_of_free_memory: [MemoryBlock.t()]
        }

  def new(total_memory, os_size) when os_size <= total_memory do
    %__MODULE__{
      total_memory: total_memory,
      os_size: os_size,
      cpu_processes: [],
      blocks_of_free_memory: [
        %MemoryManagerCore.MemoryBlock{
          start_address: os_size,
          end_address: total_memory
        }
      ]
    }
  end

  def new(total_memory, os_size) when os_size > total_memory do
    %__MODULE__{
      total_memory: total_memory,
      os_size: total_memory,
      cpu_processes: [],
      blocks_of_free_memory: []
    }
  end
end
