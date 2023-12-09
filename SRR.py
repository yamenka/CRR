# Sample Input
processes = [["p1", 6, 0], ["p2", 5, 1], ["p3", 4, 4], ["p4", 2, 3]]

# Initialization
service_times = [p[1] for p in processes]
arrival_times = [p[2] for p in processes]
priorities = [0] * len(processes)  # Initial priorities all set to 0
new_queue = []
accepted_queue = []
status_queue = ['-', '-', '-', '-']
T = 0
q = 1

# Helper function to update status
def update_status():
    for i in range(len(status_queue)):
        if status_queue[i] not in {'F', 'W'}:
            status_queue[i] = '-'
    for p in new_queue:
        status_queue[processes.index(p)] = 'W'
    for i, p in enumerate(accepted_queue):
        status_queue[processes.index(p)] = 'R' if i == 0 else 'W' 

# Main Loop
while service_times != [0,0,0,0]: 
# status_queue != ['F', 'F', 'F', 'F']
    # Check arrivals
    for p in processes:
        if p[2] == T:
            if not accepted_queue:
                accepted_queue.append(p)
                status_queue[processes.index(p)] = 'R'
            else:
                new_queue.append(p)

    # Update priorities
    # For new queue
    for p in new_queue:
        p_index = processes.index(p)
        priorities[p_index] += 2
    
    # For accepted queue
    for p in accepted_queue:
        p_index = processes.index(p)
        priorities[p_index] += 1

    print(f"T = {T}, Status Queue: {status_queue}, Priorities: {priorities},{service_times}")

    # Process execution in accepted queue

    
      

    # Move processes between queues
    for p in new_queue:
        p_index = processes.index(p)
        if accepted_queue and priorities[p_index] >= min([priorities[processes.index(proc)] for proc in accepted_queue]):
            new_queue.remove(p)
            accepted_queue.append(p)  # Add as the second element

    if accepted_queue:
        running_process = accepted_queue.pop(0)
        process_index = processes.index(running_process)
        service_times[process_index] -= 1  # Decrement service time
        

    
        # Check if process is finished
        if service_times[process_index] <= 0:
            status_queue[process_index] = 'F'
        else:
            accepted_queue.append(running_process)  # Insert at index 1



    # Update statuses
    update_status()

    T += 1

# Output final status
print("Final Status Queue:", status_queue)
print(f"T = {T}, Status Queue: {status_queue}, Priorities: {priorities},{service_times}")
