defmodule MemoryManagerCore.MemoryBlock do
  defstruct ~w[start_address end_address]a

  @type t :: %__MODULE__{
          start_address: integer(),
          end_address: integer()
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
