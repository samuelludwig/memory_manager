defmodule MemoryManagerCore do
  alias MemoryManagerCore.{
    MemoryState,
    ProcessHelpers,
    MemoryHelpers,
    SimParameters
  }

  @moduledoc """
  Public API for the core Memory Manager component.

  The API consists of one function: `calculate_state/1`, which expects a `%SimParameters{}` struct, structured as follows:

  ```
  %SimParameters{
    state: MemoryState.t(),
    action: :new | :add | :remove | :compact,
    args: keyword() | nil
  }
  ```

  where
  - `state` consists of a %MemoryState{} struct, which contains information such as the total memory capcacity of the simulator, the size of the OS, a list of available memory spaces, and a list of CPU processes in memory.
  - `action` determines the operation that will be performed on the `state` data.
  - `args` contains a keyword list of arguments for each action (where applicable).

  Each call to `calculate_state/1` will return a new `%MemoryState{}` struct.
  """

  def calculate_state(%SimParameters{action: :new}) do
    MemoryState.new(4000, 400)
  end

  def calculate_state(%SimParameters{
        state: state,
        action: :add,
        args: [algorithm: algorithm, name: name, size: size]
      }) do
    ProcessHelpers.add_process(state, algorithm, name, size)
  end

  def calculate_state(%SimParameters{state: state, action: :remove, args: [name: name]}) do
    ProcessHelpers.remove_process(state, name)
  end

  def calculate_state(%SimParameters{state: state, action: :compact}) do
    MemoryHelpers.compact_memory(state)
  end

  def calculate_state(_) do
    raise "Invalid Parameters!"
  end
end
