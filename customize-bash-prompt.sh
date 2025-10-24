#!/bin/bash

####################################################################################################
# Custom Bash Prompt
#
# This script customizes the bash shell prompt to display the current user, directory, and git branch.
# The prompt uses ANSI escape codes to set text formatting and colors for each component.
#
# For more information on customizing the bash prompt, see:
# https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
#
# For more information on ANSI escape codes, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code
#
####################################################################################################

delete_matching_regex() {
     # The regex pattern is passed as the first argument to this function.
     local regex_pattern=$1
     # `sed` is a stream editor for filtering and transforming text.
     # The `-e` flag allows us to specify a command to run.
     # The command `/regex/d` deletes lines that match the regex pattern.
     sed -e "/${regex_pattern}/d"
}

replace_matching_regex() {
     # The regex pattern and replacement value are passed as arguments to this function.
     local regex_pattern=$1
     local replacement_value=$2
     # `sed` is a stream editor for filtering and transforming text.
     # The `-e` flag allows us to specify a command to run.
     # The command `s/regex/replacement/` replaces the regex pattern with the replacement value.
     sed -e "s/${regex_pattern}/${replacement_value}/"
}

# deletes all lines that do not start with an asterisk, which I'm using to filter
# the output of `git branch` to only show the current branch line (ex: "* master")
filter_to_current_branch_only() {
     local line_does_not_start_with_asterisk='^[^\*]'
     delete_matching_regex $line_does_not_start_with_asterisk
}

# strips the leading '* ' from the `git branch` output,
# returning only the current branch name (ex: "master")
get_current_branch_name() {
     local leading_star_and_space='^\*\s'
     local empty_string=""
     replace_matching_regex $leading_star_and_space $empty_string
}

# formats the current branch name by wrapping it in parentheses
# (ex: "(master)")
# If the branch name is empty, this function will return an empty string.
format_branch_name() {
     local branch_name=$1
     if [ -n "$branch_name" ]; then
          echo "(${branch_name})"
     else
          echo ""
     fi
}

# Takes the output of `git branch`, filters the output to only the current branch,
# then prints the current branch wrapped in parentheses. (ex: "(master)").
# If not in a git repository, this function will dump the stderr stream to /dev/null
# so we don't end up displaying the error message in the shell prompt.
parse_git_branch() {
     purgatory=/dev/null
     git branch 2> $purgatory | filter_to_current_branch_only | format_branch_name $(get_current_branch_name)
}

# Functions to set text formatting and colors in the shell prompt.
# These functions use ANSI escape codes to control text formatting and colors.
# The code '\033' (or '\e') is the escape character, followed by '['.
# The pattern '38;5;COLOR_CODE' sets the foreground color to the specified color code.
# The pattern '48;5;COLOR_CODE' sets the background color to the specified color code.
# The pattern '0' resets the text formatting to default.
# The color codes range from 0 to 255, representing the 256-color palette.
# Use the function 'list_all_colors' (defined below) to display all 256 colors in the palette.
set_text_foreground_color() {
     local color_code=$1
     echo "\033[38;5;${color_code}m"
}
set_text_background_color() {
     local color_code=$1
     echo "\033[48;5;${color_code}m"
}
reset_text_formatting() {
     echo "\033[0m"
}

build_prompt() {
     # Define text colors for the prompt.
     local pink_text=$(set_text_foreground_color 207)
     local blue_text=$(set_text_foreground_color 51)
     local green_text=$(set_text_foreground_color 46)
     local reset_formatting=$(reset_text_formatting)

     # Define prompt components.
     local username="\u"  # Use '$GITHUB_USER' for Codespaces
     local current_directory="\w"
     local current_git_branch="\$(parse_git_branch)"
     local cursor="🔥 "

     # Assemble the prompt components with text colors.
     # Will display the following format:
     #   <username> <current_directory>/ <current_git_branch>
     #   Example: "john_doe ~/projects/my_project/ (master)"
     echo -e "${pink_text}\n${username} ${blue_text}${current_directory}/ ${green_text}${current_git_branch}${reset_formatting}\n${cursor}"
}

# Set the environment variable for the bash shell prompt by calling the 'build_prompt' function.
export PS1=$(build_prompt)
