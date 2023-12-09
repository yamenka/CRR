#!/bin/bash

# Sample Input
processes=("p1 6 0" "p2 5 1" "p3 4 3" "p4 2 4")

# Initialization
service_times=(6 5 4 2)
arrival_times=(0 1 3 4)
priorities=(0 0 0 0)  # Initial priorities all set to 0
new_queue=()
accepted_queue=()
status_queue=('-' '-' '-' '-')
T=0
q=1

# Helper function to update status
update_status() {
    for i in {0..3}; do
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
while [[ "${status_queue[*]}" != "F F F F" ]]; do
    # Check arrivals
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
        priorities[$index]=$((current_priority + 2))
    done

    # For accepted queue
    for p in "${accepted_queue[@]}"; do
        index=$(getIndex "$p")
        current_priority=$((priorities[index]))
        priorities[$index]=$((current_priority + 1))
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
    echo "After T = $T, Status Queue: ${status_queue[@]}, Priorities: ${priorities[@]}, ${service_times[@]}, Accepted queue: ${accepted_queue[@]}, new queue: ${new_queue[@]}"

    ((T++))
done

# Output final status
echo "T = $T, Status Queue: ${status_queue[@]}, Priorities: ${priorities[@]}, ${service_times[@]}"
