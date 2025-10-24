#!/bin/bash

####################################################################################################
# Functions to work with the LS_COLORS environment variable.
# The LS_COLORS environment variable controls the colors used by the `ls` command.
# 
# Each segment of the LS_COLORS variable is a pair of the form 'KEY=ANSI_COLOR_CODE'.
# The KEY is a file type or attribute, and the ANSI_COLOR_CODE is the color code to use.
# 
# For example, 'di=01;34' sets the color for directories to bold blue
# (01 is bold, and 34 is blue).
# 
# Use the function 'print_ls_colors' (defined below) to display the LS_COLORS variable
# with each segment on its own line and the corresponding color code applied.
# (Optionally, you can pipe the output to `strip_file_types` to remove file types like *.tgz).
#
# To view the default LS_COLORS presets, run `dircolors -p`.
#
# LS_COLORS segment codes:
# rs - Reset (reset to normal color)
# di - Directory
# ln - Symbolic link
# mh - Multi-hardlink (file with multiple hard links)
# pi - Named pipe (FIFO)
# so - Socket
# do - Door (Solaris special file)
# bd - Block device
# cd - Character device
# or - Orphaned symbolic link (broken link)
# mi - Missing file (target of orphaned symlink)
# su - File with setuid bit set
# sg - File with setgid bit set
# ca - File with capability
# tw - Directory that is sticky and world-writable
# ow - Directory that is world-writable but not sticky
# st - Directory with sticky bit set
# ex - Executable file
####################################################################################################

separate_by_lines() {
     tr ':' '\n'
}

strip_file_types() {
     sed -e '/*/d' # Delete lines that contain '*' (file types, e.g. '*.tgz')
}

apply_color_codes() {
     sed -e 's/\([^=]\+\)=\(.*\)/\x1b[\2m\1\x1b[0m/'
}

# Print the LS_COLORS environment variable with each segment on its own line,
# and apply the corresponding color codes to each segment.
# This makes it easier to read and understand the color codes.
print_ls_colors() {
     echo $LS_COLORS | separate_by_lines | apply_color_codes
}

help() {
     echo "Usage: ls_colors.sh [OPTION]"
     echo "Print the LS_COLORS environment variable with each segment on its own line. Excludes file types by default."
     echo "  -f    Include file types in the output (e.g. *.tgz)."
     echo "  -h    Display this help message."
}

while getopts "fh" opt; do
     case $opt in
          f) print_ls_colors; exit 0 ;;
          h) help; exit 0 ;;
          \?) echo "Invalid option: -$OPTARG" >&2 ;;
     esac
done

print_ls_colors | strip_file_types
