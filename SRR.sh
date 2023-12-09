#!/bin/bash

# Initialize arrays
process=()
nut=()
arrival=()
status=()
priority=()
final_status=()
final_priority=()
accepted_queue=()
time_steps=() # Array to store the status of each process at each time step

# Read file and populate arrays
while IFS= read -r line || [[ -n "$line" ]]; do
    read -r p n a <<< "$line"
    process+=("$p")
    nut+=("$n")
    arrival+=("$a")
    status+=("-")  # Initialize status as "-" for each process
    priority+=("0") # Initialize priority as 0
    final_status+=("-")
    final_priority+=("0")
done < "data.txt"

# Function to sort arrays based on arrival times
sort_arrays() {
    local i j
    for ((i = 0; i < ${#arrival[@]}; i++)); do
        for ((j = i + 1; j < ${#arrival[@]}; j++)); do
            if (( arrival[i] > arrival[j] )); then
                # Swap in all arrays
                tmp=${arrival[i]}
                arrival[i]=${arrival[j]}
                arrival[j]=$tmp

                tmp=${process[i]}
                process[i]=${process[j]}
                process[j]=$tmp

                tmp=${nut[i]}
                nut[i]=${nut[j]}
                nut[j]=$tmp

                tmp=${status[i]}
                status[i]=${status[j]}
                status[j]=$tmp

                tmp=${priority[i]}
                priority[i]=${priority[j]}
                priority[j]=$tmp

                tmp=${final_status[i]}
                final_status[i]=${final_status[j]}
                final_status[j]=$tmp

                tmp=${final_priority[i]}
                final_priority[i]=${final_priority[j]}
                final_priority[j]=$tmp
            fi
        done
    done
}

# Sort the arrays
sort_arrays

# Function to update time_steps array with the current status of each process
update_time_steps() {
    local current_status=()
    for st in "${status[@]}"; do
        current_status+=("$st")
    done
    time_steps+=("$(IFS=' '; echo "${current_status[*]}")")
}

# Time variable
t=0

# Main processing loop
while true; do
    # Check for new arrivals and add them to the queue
    for i in "${!arrival[@]}"; do
        if [[ "${arrival[i]}" -eq "$t" ]]; then
            accepted_queue+=("${process[i]}")
            status[i]="W" # W for Waiting
        fi
    done

    # Reset status to Waiting for all processes except the one currently running
    for i in "${!status[@]}"; do
        if [[ "${status[i]}" = "R" ]]; then
            status[i]="W" # W for Waiting
        fi
    done

    # Process the first item in the queue
    if [[ ${#accepted_queue[@]} -gt 0 ]]; then
        current_process=${accepted_queue[0]}
        for i in "${!process[@]}"; do
            if [[ "${process[i]}" == "$current_process" ]]; then
                status[i]="R" # R for Running
                ((nut[i]--))
                ((priority[i]++))

                # Check if the process is finished
                if [[ "${nut[i]}" -eq 0 ]]; then
                    status[i]="F" # F for Finished
                    final_status[i]="F"
                    final_priority[i]=${priority[i]}
                else
                    # Move to the end of the queue if not finished
                    accepted_queue+=("${current_process}")
                fi
                unset accepted_queue[0] # Remove from front of queue
                break
            fi
        done
    fi

    # Update time_steps array with current status
    update_time_steps

    # Re-index accepted_queue array to remove gaps
    accepted_queue=("${accepted_queue[@]}")

    # Check if all processes are finished
    all_finished=true
    for st in "${status[@]}"; do
        if [[ "$st" != "F" ]]; then
            all_finished=false
            break
        fi
    done

    if [[ "$all_finished" == true ]]; then
        break
    fi

    # Increment time
    ((t++))
done

# Print the consolidated status table with increased spacing
printf "T\t"
for p in "${process[@]}"; do
    printf "%s\t" "$p"
done
echo

for ((i = 0; i < ${#time_steps[@]}; i++)); do
    printf "%d\t" "$i"
    IFS=' ' read -r -a current_status <<< "${time_steps[i]}"
    for st in "${current_status[@]}"; do
        printf "%s\t" "$st"
    done
    echo
done

# Print final state
echo "Final state of arrays after processing:"
echo "Processes: ${process[*]}"
echo "Nut: ${nut[*]}"
echo "Arrival: ${arrival[*]}"
echo "Status: ${final_status[*]}"
echo "Priority: ${final_priority[*]}"
