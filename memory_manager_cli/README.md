# MemoryManagerCli

- User interface for the Memory Manager application over the Command-Line.
- Takes in a string as user input in one of the four following formats:
  - `n` -> creates a new `%MemoryState{}` struct
  - `r name` -> removes the process named `name` from the current `%MemoryState{}` struct.
  - `a [ f | b | w ] size` -> adds a process of size `size` into the current `%MemoryState{}` struct, according to the algorithm specified in the second argument: `f` for 'first\_fit', `b` for 'best\_fit', `w` for 'worst\_fit'.
  - `q` -> exit the program
- Any input string that deviates from the formats above will result in an error.
- The output of the situation will be graphically represented by ASCII characters

## Limitations

- The total memory capacity of the simulation will be set at 4000, with the OS sized at 400, this is not due to limitations on the backend, calcualtions can be done for states of arbitrary size, rather it is to simplify the actual displaying of the information, and to make sure it can fit comfortably on screen.
- For this same reason, when adding a process, the size must be a multiple of 50, this is because when representing the output on screen via ASCII, each character will represent 50 bytes in memory.
