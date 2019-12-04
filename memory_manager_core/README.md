# MemoryManagerCore

The API of the MemoryManagerCore component consists of one function- `calculate_state/1`, which expects a `%SimParameters{}` struct, structured as follows:

```
%SimParameters{
   state: MemoryState.t(),
   action: :new | :add | :remove | :compact,
   args: keyword() | nil
}
```

where:

- `state` consists of a %MemoryState{} struct, which contains information such as the total memory capcacity of the simulator, the size of the OS, a list of available memory spaces, and a list of CPU processes in memory.
- `action` determines the operation that will be performed on the `state` data.
- `args` contains a keyword list of arguments for each action (where applicable).
  - For the `:new` and `:compact` actions, there are no arguments.
  - For the `:add` action, the arguments are `[algorithm_name, name_of_process, size_of_process]`.
  - For the `:remove` action, the arguments are only `[name_of_process]`.

Each call to `calculate_state/1` will return a new `%MemoryState{}` struct.
