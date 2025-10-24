#!/bin/bash

####################################################################################################
# 
# Display all 256 colors in the 256-color palette.
# 
# Each color code is printed with its corresponding background and foreground colors.
# The colors are displayed in a grid format for easy visualization.
# 
# Inspiration: https://github.com/gawin/bash-colors-256?tab=readme-ov-file
#
####################################################################################################

list_all_colors() {
     for i in {0..255}; do
          local background_color_i=$(set_text_background_color $i)
          local foreground_color_i=$(set_text_foreground_color $i)
          local reset_formatting=$(reset_text_formatting)
          local fg_default=$(set_text_foreground_color 0) # Will show as white or black depending on the background color.
          local i_with_leading_zeros=$(printf '%03d' $i)

          local color_as_background="${background_color_i}${fg_default}${i_with_leading_zeros}${reset_formatting}"
          local color_as_foreground="${foreground_color_i}${i_with_leading_zeros}${reset_formatting}"
          printf "${color_as_background} ${color_as_foreground} "

          # First 16 colors are displayed in a 2x8 grid.
          # After that, display the remaining colors in 6x6 grids
          # with an extra newline between each box of 36 colors.
          if (( ( $i + 1 ) <= 16 )); then
               if (( $i % 8 == 7 )); then
                    printf "\n"
               fi
               if (( $i == 15 )); then
                    printf "\n"
               fi
          else
               if (( ($i - 16) % 6 == 5 )); then
                    printf "\n"
               fi
               if (( ($i - 16) % 36 == 35 )); then
                    printf "\n"
               fi
          fi
     done
}

list_all_colors
