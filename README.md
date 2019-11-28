# memory_manager

GitHub repo located at: https://github.com/samuelludwig/memory_manager

Memory Manager Simulation project for COM 310

Task: Create an interactive webapp that displays the impact of different kinds 
of algorithms regarding the management of an OS's memory resources.

The tech stack employed will be as follows:

- Backend: Elixir (using Cowboy to manage the server connections)
- Frontend: Elm

## Strategy Breakdown

- There are 3 main actions that need to be performed:
  - Insert a process
  - Remove a process
  - Compact processes/memory

### Algorithm for Inserting a Process 

#### First-Fit

```
For each in list of memory blocks:
  if (size_of_memory_block > process_size)
    insert process into process_list with:
      start_address = memory_block.start_address
      end_address = block.start_address + process_size
    AND
    set memory block fields to:
      start_adress = process.end_address
    AND
    break
  else if (size_of_memory_block == process_size)
    insert process into process_list with:
      start_address = memory_block.start_address
      end_address = block.start_address + process_size
    AND
      remove memory block from list
    AND
    break
```
