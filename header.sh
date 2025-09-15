#!/bin/bash

# ASCII art for the header
declare -a ASCII_ART=(
    "        :::      ::::::::"
    "      :+:      :+:    :+:"
    "    +:+ +:+         +:+  "
    "  +#+  +:+       +#+     "
    "+#+#+#+#+#+   +#+        "
    "     #+#    #+#          "
    "    ###   ########.fr    "
)

# Default values
LENGTH=80
MARGIN=5
START_CHAR="/*"
END_CHAR="*/"
FILL_CHAR="*"

# File type associations
declare -A FILE_TYPES=(
    ["c"]="/* */ *"
    ["h"]="/* */ *"
    ["cc"]="/* */ *"
    ["hh"]="/* */ *"
    ["cpp"]="/* */ *"
    ["hpp"]="/* */ *"
    ["tpp"]="/* */ *"
    ["ipp"]="/* */ *"
    ["cxx"]="/* */ *"
    ["go"]="/* */ *"
    ["rs"]="/* */ *"
    ["php"]="/* */ *"
    ["java"]="/* */ *"
    ["kt"]="/* */ *"
    ["kts"]="/* */ *"
    ["htm"]="<!-- --> *"
    ["html"]="<!-- --> *"
    ["xml"]="<!-- --> *"
    ["js"]="// // *"
    ["ts"]="// // *"
    ["tex"]="% % *"
    ["ml"]="(* *) *"
    ["mli"]="(* *) *"
    ["mll"]="(* *) *"
    ["mly"]="(* *) *"
    ["vim"]="\" \" *"
    ["el"]="; ; *"
    ["asm"]="; ; *"
    ["f90"]="! ! /"
    ["f95"]="! ! /"
    ["f03"]="! ! /"
    ["f"]="! ! /"
    ["for"]="! ! /"
    ["lua"]="-- -- -"
    ["py"]="# # *"
    ["sh"]="# # *"
    ["bash"]="# # *"
)

# Function to get file extension
get_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# Function to set comment characters based on file type
set_comment_chars() {
    local ext="$1"

    # Default values
    START_CHAR="#"
    END_CHAR="#"
    FILL_CHAR="*"

    if [[ -n "${FILE_TYPES[$ext]}" ]]; then
        local chars="${FILE_TYPES[$ext]}"
        START_CHAR=$(echo "$chars" | cut -d' ' -f1)
        END_CHAR=$(echo "$chars" | cut -d' ' -f2)
        FILL_CHAR=$(echo "$chars" | cut -d' ' -f3)
    fi
}

# Function to get ASCII art line
get_ascii_line() {
    local line_num=$1
    if [[ $line_num -ge 3 && $line_num -le 9 && $((line_num % 2)) -eq 1 ]]; then
        echo "${ASCII_ART[$((line_num - 3))]}"
    else
        echo ""
    fi
}

# Function to create a text line with proper spacing
create_text_line() {
    local left_text="$1"
    local right_text="$2"

    # Calculate available space for left text
    local max_left_length=$((LENGTH - MARGIN * 2 - ${#right_text}))
    if [[ ${#left_text} -gt $max_left_length ]]; then
        left_text="${left_text:0:$max_left_length}"
    fi

    # Calculate spaces needed
    local spaces_needed=$((LENGTH - MARGIN * 2 - ${#left_text} - ${#right_text}))
    if [[ $spaces_needed -lt 0 ]]; then
        spaces_needed=0
    fi

    # Build the line
    local line="$START_CHAR"
    line+=$(printf "%*s" $((MARGIN - ${#START_CHAR})) "")
    line+="$left_text"
    line+=$(printf "%*s" $spaces_needed "")
    line+="$right_text"
    line+=$(printf "%*s" $((MARGIN - ${#END_CHAR})) "")
    line+="$END_CHAR"

    echo "$line"
}

# Function to create header line
create_header_line() {
    local line_num=$1
    local filename="$2"
    local created_date="$3"

    case $line_num in
        1|11) # top and bottom border
            local fill_length=$((LENGTH - ${#START_CHAR} - ${#END_CHAR} - 2))
            echo "$START_CHAR $(printf "%*s" $fill_length "" | tr ' ' "$FILL_CHAR") $END_CHAR"
            ;;
        2|10) # blank lines
            create_text_line "" ""
            ;;
        3|5|7) # lines with ASCII art only
            create_text_line "" "$(get_ascii_line $line_num)"
            ;;
        4) # filename line
            create_text_line "$filename" "$(get_ascii_line $line_num)"
            ;;
        6) # author line
            local user="${USER:-marvin}"
            local mail="${MAIL:-marvin@42.fr}"
            create_text_line "By: $user <$mail>" "$(get_ascii_line $line_num)"
            ;;
        8) # created line
            local user="${USER:-marvin}"
            local date="${created_date:-$(date '+%Y/%m/%d %H:%M:%S')}"
            create_text_line "Created: $date by $user" "$(get_ascii_line $line_num)"
            ;;
        9) # updated line
            local user="${USER:-marvin}"
            local date=$(date "+%Y/%m/%d %H:%M:%S")
            create_text_line "Updated: $date by $user" "$(get_ascii_line $line_num)"
            ;;
    esac
}

# Function to extract created date from existing header
extract_created_date() {
    local file="$1"
    if [[ -f "$file" ]]; then
        head -n 11 "$file" | grep "Created:" | sed -n 's/.*Created: \([0-9/: ]*\) by.*/\1/p'
    fi
}

# Function to check if file has header
has_header() {
    local file="$1"
    if [[ -f "$file" ]]; then
        head -n 11 "$file" | grep -q "Created:\|Updated:\|By:\|::::\|+#+\|###"
    else
        return 1
    fi
}

# Function to generate complete header
generate_header() {
    local filename="$1"
    local created_date="$2"
    local ext=$(get_extension "$filename")

    set_comment_chars "$ext"

    for i in {1..11}; do
        create_header_line $i "$filename" "$created_date"
    done
}

# Function to process each file
process_file() {
    local file="$1"
    local filename=$(basename "$file")
    local temp_file=$(mktemp)

    if [[ ! -f "$file" ]]; then
        # File doesn't exist, create it with header only
        generate_header "$filename" > "$file"
        echo >> "$file"
        echo "Header added to new file $file"
        return
    fi

    local total_lines=$(wc -l < "$file")

    if has_header "$file"; then
        # File has a header - extract created date and update
        local created_date=$(extract_created_date "$file")

        # Generate new header with preserved created date
        generate_header "$filename" "$created_date" > "$temp_file"
        echo >> "$temp_file"

        # Find where actual content starts (skip header and empty lines)
        local content_start=12
        while [[ $content_start -le $total_lines ]]; do
            local line=$(sed -n "${content_start}p" "$file")
            if [[ -n "$line" ]]; then
                break
            fi
            content_start=$((content_start + 1))
        done

        # Add remaining content if any
        if [[ $content_start -le $total_lines ]]; then
            tail -n +$content_start "$file" >> "$temp_file"
        fi

        mv "$temp_file" "$file"
        if [[ -n "$created_date" ]]; then
            echo "Header updated in $file (preserved created: $created_date)"
        else
            echo "Header updated in $file"
        fi
    else
        # File doesn't have header - add one
        generate_header "$filename" > "$temp_file"
        echo >> "$temp_file"
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
        echo "Header added to $file"
    fi
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <file1> [file2] [file3] ..."
        echo ""
        echo "The script will automatically:"
        echo "  - Add headers to files without headers"
        echo "  - Update existing headers (preserving created date, updating filename/timestamp)"
        echo ""
        echo "Environment variables:"
        echo "  USER - Username for the header (default: marvin)"
        echo "  MAIL - Email for the header (default: marvin@42.fr)"
        exit 1
    fi

    for file in "$@"; do
        process_file "$file"
    done
}

main "$@"
