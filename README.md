# memory_manager

GitHub repo located at: https://github.com/samuelludwig/memory_manager

Memory Manager Simulation project for COM 310

## Project Structure

- This project consists of two main components:
  - `memory_manager_core`: houses the main business logic for calculating the state of memory.
  - `memory_manager_cli`: the ascii-based UI for the simulator, which makes calls to the `memory_manager_core` API. This component is separately packaged and run as an escript, with the core module included as a dependancy. 

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

#### Best/Worst fit

- Best and Worst fit will be largely similar to the First-Fit algorithm, only with an intermediary step of sorting the memory blocks by size before evaluating the validity of each memory block.

### Algorithm for Removing a Processes

```
Step 1: Delete process from the list
Step 2: Add a block of free memory in its place
Step 3: Combine that block of memory with surrounding ones if possible
```
