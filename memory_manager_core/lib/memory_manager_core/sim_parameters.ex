defmodule MemoryManagerCore.SimParameters do
  alias MemoryManagerCore.MemoryState

  defstruct ~w[state action args]a

  @type t :: %__MODULE__{
          state: MemoryState.t(),
          action: :new | :add | :remove | :compact,
          args: keyword() | nil
        }
end
