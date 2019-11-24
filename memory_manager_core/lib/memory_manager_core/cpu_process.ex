defmodule MemoryManagerCore.CpuProcess do
  defstruct ~w[name start_address end_address]a

  @type t :: %__MODULE__{
          name: String.t(),
          start_address: integer(),
          end_address: integer()
        }
end
