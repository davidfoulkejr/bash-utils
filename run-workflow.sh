#!/bin/bash

# Custom CLI utility I vibe coded as a shortcut to rebuild my desktop environment for Power BI Development.
# The `run-workflow` function is generic and can be leveraged to automate any sequence of commands
# with the same step-by-step status indicator and logging behavior.

# Generic workflow runner with named parameters and step/command tuples
# Usage: run-workflow --workflow-name "My Workflow" \
#            --log-file "/path/to/log" \
#            --step "Description" "command" \
#            --step "Description2" "command2"
# Note: "--workflow-name" defaults to "Workflow" and "--log-file" defaults to "/dev/null" (no log output)
run-workflow() {
    # Default values
    local workflow_name="Workflow"
    local log_file="/dev/null"
    local -a steps=()
    local -a commands=()
    
    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --workflow-name|-w)
                workflow_name="$2"
                shift 2
                ;;
            --log-file|-l)
                log_file="$2"
                shift 2
                ;;
            --step|-s)
                if [[ $# -lt 3 ]]; then
                    echo -e "\033[1;31mError: --step requires both description and command\033[0m" >&2
                    echo -e "Usage: --step \"Step Description\" \"shell command\"" >&2
                    return 1
                fi
                steps+=("$2")
                commands+=("$3")
                shift 3
                ;;
            --help|-h)
                echo -e "\033[1;34m🚀 run-workflow - Execute a sequence of commands with live progress display\033[0m"
                echo
                echo -e "\033[1;33mUSAGE:\033[0m"
                echo "  run-workflow [OPTIONS] --step \"description\" \"command\" [--step \"desc2\" \"cmd2\" ...]"
                echo
                echo -e "\033[1;33mOPTIONS:\033[0m"
                echo "  --workflow-name \"Name\"    Display name for the workflow (default: \"Workflow\")"
                echo "  --log-file \"/path/log\"     Log file path (default: \"/dev/null\" - no logging)"
                echo "  --step \"desc\" \"command\"   Add a step with description and shell command"
                echo "  --help, -h                Show this help message"
                echo
                echo -e "\033[1;33mEXAMPLES:\033[0m"
                echo "  # Simple workflow without logging:"
                echo "  run-workflow --workflow-name \"Quick Test\" \\"
                echo "    --step \"Running tests\" \"pnpm test\" \\"
                echo "    --step \"Linting code\" \"pnpm lint\""
                echo
                echo "  # Full workflow with logging:"
                echo "  run-workflow --workflow-name \"Deploy\" \\"
                echo "    --log-file \"\$HOME/deploy.log\" \\"
                echo "    --step \"Building\" \"pnpm build\" \\"
                echo "    --step \"Testing\" \"pnpm test\" \\"
                echo "    --step \"Deploying\" \"pnpm deploy\""
                echo
                echo -e "\033[1;33mFEATURES:\033[0m"
                echo "  • Live progress indicator with colored status"
                echo "  • Real-time output display of current command"
                echo "  • Clean log files with ANSI codes stripped"
                echo "  • Automatic failure detection and reporting"
                echo "  • Steps and commands are paired as tuples"
                echo
                return 0
                ;;
            *)
                echo -e "\033[1;31mError: Unknown parameter $1\033[0m" >&2
                echo -e "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done
    
    # Validate that we have at least one step
    if [[ ${#steps[@]} -eq 0 ]]; then
        echo -e "\033[1;31mError: At least one --step is required\033[0m" >&2
        return 1
    fi
    
    # Colors for status indicators
    local YELLOW='\033[1;33m'
    local GREEN='\033[1;32m'
    local BLUE='\033[1;34m'
    local RED='\033[1;31m'
    local RESET='\033[0m'
    
    # Ensure log directory exists (skip if /dev/null)
    if [[ "$log_file" != "/dev/null" ]]; then
        mkdir -p "$(dirname "$log_file")"
        # Initialize log with timestamp
        echo "=== $workflow_name Started at $(date) ===" > "$log_file"
    fi
    
    # Function to print step status
    print_step() {
        local step_num=$1
        local step_desc=$2
        local status=$3  # "current", "completed", "pending"
        
        local prefix=""
        local color=""
        
        case $status in
            "current")
                prefix="⏳"
                color="$YELLOW"
                ;;
            "completed")
                prefix="✅"
                color="$GREEN"
                ;;
            "pending")
                prefix="⚪"
                color=""
                ;;
        esac
        
        echo -e "${color}${prefix} Step ${step_num}: ${step_desc}${RESET}"
    }
    
    # Function to print all steps with current status
    print_status() {
        local current_step=$1
        echo -e "\n${BLUE}🚀 $workflow_name Progress:${RESET}"
        
        for i in "${!steps[@]}"; do
            local step_num=$((i + 1))
            if [ $step_num -lt $current_step ]; then
                print_step $step_num "${steps[$i]}" "completed"
            elif [ $step_num -eq $current_step ]; then
                print_step $step_num "${steps[$i]}" "current"
            else
                print_step $step_num "${steps[$i]}" "pending"
            fi
        done
        echo
    }
    
    # Execute each step
    for i in "${!commands[@]}"; do
        local step_num=$((i + 1))
        local command="${commands[$i]}"
        
        # Clear screen and show current status
        clear
        print_status $step_num
        
        # Log the command (skip if /dev/null)
        if [[ "$log_file" != "/dev/null" ]]; then
            echo >> "$log_file"
            echo "--- Executing: $command ---" >> "$log_file"
        fi
        
        # Execute command with real-time output display
        local temp_output=$(mktemp)
        local temp_clean=$(mktemp)
        local last_line=""
        
        # Start command in background and capture its PID
        eval "$command" > "$temp_output" 2>&1 &
        local cmd_pid=$!
        
        # Monitor output in real-time
        while kill -0 $cmd_pid 2>/dev/null; do
            if [ -f "$temp_output" ]; then
                # Get the last non-empty line from output
                local current_line=$(tail -n 20 "$temp_output" | grep -v '^[[:space:]]*$' | tail -n 1)
                
                # Only update display if line changed and is not empty
                if [ "$current_line" != "$last_line" ] && [ -n "$current_line" ]; then
                    # Strip ANSI codes for display (but keep them in the original output)
                    local clean_line=$(echo "$current_line" | sed 's/\x1b\[[0-9;]*[mGKH]//g')
                    # Move cursor to line below progress, clear it, and show current output
                    echo -ne "\033[1G\033[K${BLUE}Current: ${RESET}${clean_line}"
                    last_line="$current_line"
                fi
            fi
            sleep 0.1
        done
        
        # Wait for command to complete and get exit status
        wait $cmd_pid
        local exit_status=$?
        
        # Strip ANSI escape sequences and append clean output to log file (skip if /dev/null)
        if [[ "$log_file" != "/dev/null" ]]; then
            sed 's/\x1b\[[0-9;]*[mGKH]//g' "$temp_output" > "$temp_clean"
            cat "$temp_clean" >> "$log_file"
        fi
        
        # Clean up temp files
        rm -f "$temp_output" "$temp_clean"
        
        # Clear the current output line
        echo -ne "\033[1G\033[K"
        
        # Check if command succeeded
        if [ $exit_status -ne 0 ]; then
            # Command failed
            clear
            print_status $step_num
            echo -e "${RED}❌ Step ${step_num} failed!${RESET}"
            echo -e "${RED}Failed command: ${command}${RESET}"
            echo
            
            # Show the last few lines of output for immediate context
            if [ -f "$temp_output" ] && [ -s "$temp_output" ]; then
                echo -e "${RED}Error output:${RESET} (last 10 lines of captured logs)"
                # Get last 10 lines of output
                tail -n 10 "$temp_output"
                echo
            fi
            
            if [[ "$log_file" != "/dev/null" ]]; then
                echo -e "${BLUE}📄 Full log available at: ${log_file}${RESET}"
            fi
            return 1
        fi
    done
    
    # All steps completed successfully
    clear
    print_status $((${#steps[@]} + 1))
    echo -e "${GREEN}🎉 $workflow_name completed successfully!${RESET}"
    if [[ "$log_file" != "/dev/null" ]]; then
        echo -e "${BLUE}📄 Full log available at: ${log_file}${RESET}"
    fi
}
