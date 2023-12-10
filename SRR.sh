#!/bin/bash

# Check if three arguments were provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 filename new_queue_increment accepted_queue_increment"
    exit 1
fi

# Assignments from arguments
file="$1"
new_queue_increment="$2"
accepted_queue_increment="$3"

# Check if the file exists
if [ ! -f "$file" ]; then
    echo "Error: File not found: $file"
    exit 1
fi

# Initialization
service_times=()
arrival_times=()
priorities=()  # Initial priorities all set to 0
new_queue=()
accepted_queue=()
status_queue=()
T=0
q=1

# Read file and populate arrays
while IFS= read -r line || [[ -n "$line" ]]; do
    # Split line into words
    read -ra ADDR <<< "$line"

    # Populate arrays
    processes+=("${ADDR[0]} ${ADDR[1]} ${ADDR[2]}")
    service_times+=("${ADDR[1]}")
    arrival_times+=("${ADDR[2]}")
    priorities+=(0)  # Assuming priority is initially 0 for all
    status_queue+=('-')
done < "$file"

# Helper function to update status
update_status() {
    local length=${#status_queue[@]}
    for ((i=0;  i<length; i++)); do
        if [[ "${status_queue[$i]}" != "F" && "${status_queue[$i]}" != "W" ]]; then
            status_queue[$i]='-'
        fi
    done

    for p in "${new_queue[@]}"; do
        index=$(getIndex "$p")
        status_queue[$index]='W'
    done

    for i in "${!accepted_queue[@]}"; do
        p="${accepted_queue[$i]}"
        index=$(getIndex "$p")
        if [[ $i -eq 0 ]]; then
            status_queue[$index]='R'
        else
            status_queue[$index]='W'
        fi
    done
}

# Helper function to get the index of a process in processes array
getIndex() {
    local process="$1"
    for i in "${!processes[@]}"; do
        if [[ "${processes[$i]}" == "$process" ]]; then
            echo "$i"
            return
        fi
    done
}

# Helper function to find the minimum priority in the accepted queue
minPriority() {
    local min=0
    for p in "${accepted_queue[@]}"; do
        index=$(getIndex "$p")
        if [[ "${priorities[$index]}" < "$min" ]]; then
            min=$((priorities[index]))
        fi
    done
    echo "$min"
}

# Main Loop
while :; do  # Infinite loop, will break inside based on condition
    all_finished=true    # Check arrivals
    for p in "${processes[@]}"; do
        IFS=' ' read -ra process_info <<< "$p"
        if [[ "${process_info[2]}" == "$T" ]]; then
            if [[ "${#accepted_queue[@]}" -eq 0 ]]; then
                index=${#accepted_queue[@]}
                accepted_queue[$index]="$p"
                status_queue[$(getIndex "$p")]='R'
            else
                index=${#new_queue[@]}
                new_queue[$index]="$p"
            fi
        fi
    done

    ## For new queue
    for p in "${new_queue[@]}"; do
        index=$(getIndex "$p")
        current_priority=$((priorities[index]))
        priorities[$index]=$((current_priority + $new_queue_increment))
    done

    # For accepted queue
    for p in "${accepted_queue[@]}"; do
        index=$(getIndex "$p")
        current_priority=$((priorities[index]))
        priorities[$index]=$((current_priority + $accepted_queue_increment))
    done

    update_status
    echo "Before T = $T, Status Queue: ${status_queue[@]}, Priorities: ${priorities[@]}, ${service_times[@]}, Accepted queue: ${accepted_queue[@]}, new queue: ${new_queue[@]}"

    # Process execution in accepted queue

    # Move processes between queues
    for p in "${new_queue[@]}"; do
        index=$(getIndex "$p")
        accepted_priority=$(minPriority)
        if [[ "${#accepted_queue[@]}" -ne 0 && "${priorities[$index]}" -ge "$accepted_priority" ]]; then
            new_array=()
            for element in "${new_queue[@]}"; do
                if [ "$element" != "$p" ]; then
                    new_array[${#new_array[@]}]="$element"
                fi
            done
            new_queue=("${new_array[@]}")
            unset new_array
            index=${#accepted_queue[@]}
            accepted_queue[$index]="$p"

        fi
    done

    if [[ "${#accepted_queue[@]}" -ne 0 ]]; then
        running_process="${accepted_queue[0]}"
        new_array=("${accepted_queue[@]:1}")
        accepted_queue=("${new_array[@]}")
        unset new_array
        index=$(getIndex "$running_process")
        service_times[$index]=$((service_times[$index] - 1))

        # Check if process is finished
        if [[ "${service_times[$index]}" -le 0 ]]; then
            status_queue[$index]='F'
        else
            index=${#accepted_queue[@]}
            accepted_queue[$index]="$running_process"
        fi
    fi

    # Update statuses
    update_status
    for status in "${status_queue[@]}"; do
        if [[ "$status" != "F" ]]; then
            all_finished=false
            break  # Break the for loop, not the while loop
        fi
    done
    if [[ "$all_finished" = true ]]; then
        break  # Break the while loop if all processes are finished
    fi


    ((T++))
done

# Output final status
echo "T = $T, Status Queue: ${status_queue[@]}, Priorities: ${priorities[@]}, ${service_times[@]}"
