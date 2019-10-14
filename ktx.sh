#!/bin/sh
position=0
filepath=$HOME/.kubeconfigs/
oIFS="$IFS"

# if filepath does not exist, make it!
if [ ! -d $filepath ]; then
    echo "Didn't find $filepath, making."
    mkdir -p $filepath
    dirs=""
else 
    dirs=( $(ls -l $filepath | grep "^d" | awk '{print $9}') )
fi

url=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/

print_usage() {
cat << EOF
Usage:  
ktx [add | del | sel] [filename] [--name context-name]  

Running with no arguments will open the selector menu  
ktx dash will attempt to open a dashboard after exporting.

add - adds a listing  
    ktx add <filename>  
    ktx add <filename> --name <context-name>  
del - deletes a listing  
    ktx del <context-name>  
tldr - prints the TLDR   
    ktx tldr  
usage: ktx [add | del | sel] [<filename>] [--token <plain token file>] [--name <context-name>]
Running with no arguments will open the selector menu
add - adds a listing
    eg. ktx add <filename>
del - deletes a listing
    eg. ktx del <context-name>
sel - select a listing
    eg. ktx sel <context-name>
tldr - prints the TLDR 
    eg. ktx tldr
help - prints this 
        eg. ktx help
EOF
    exit
}

print_tldr() {
cat << EOF
    Add a listing: ktx add <filename>
    Delete a listing: ktx del <context-name>
    Select a listing (no arguments): ktx OR ktx dash 
EOF
    exit
}

mode="sel"
grab=false

# check flags and args
for arg in "$@"; do
    if [ $grab = false ]; then
        case "$arg" in
            "add") mode="add" && grab="file" ;;
            "del") mode="del" && grab="file" ;;
            "--name") grab="name" ;;
            "-n") grab="name" ;;
            "--token") grab="token" ;;
            "-t") grab="token" ;;
            "tldr") print_tldr ;;
            "help") print_usage ;;
            "dash") dashboard=true && token=true ;;
        esac    
    else
        case "$grab" in
           "file") input_file=$arg ;;
           "name") input_name=$arg ;;
           "token") input_token=$arg ;;
        esac 
        grab=false
    fi
done

[[ ! $grab = false ]] && print_usage # shouldn't still be grabbing. theyve used it wrong

DeleteListing() {
    # very short stuff, just deletes the given file
    [[ -z $input_file ]] && echo "No listing given!" && exit
    if [[ ! -d $filepath$input_file ]]; then 
       echo "No listing exists with the file $input_file"
    else
       rm -r $filepath$input_file
       echo "Deleted $filepath$input_file"
    fi
    exit
}

# reads in $input_file, trying to extract context_name and token
ReadInFile() {
    old_config=$KUBECONFIG
    eval 'export KUBECONFIG=$input_file'
    while IFS= read -r line
    do
        input_name=$(kubectl config view -o template --template='{{ index . "current-context" }}')

        if [[ $line =~ "token:" ]]; then
            input_token=$( echo $line | awk '{print $2}' )
        fi
    done < "$1" # read in the file by lines
    eval 'export KUBECONFIG=$old_config'
}

Verify() {
    [[ -z $input_token ]] && echo "No token found!"
    [[ -z $input_name ]] && echo "No name found!" && print_tldr
    [[ -z $input_file ]] && print_usage
}

# read in single character input
charin() {
    minor=""
    major=""
#   essentially when you enter in an arrow key youre actually entering in a string of 3
    read -rsn1 ui
    case "$ui" in
        $'\x1b')    # Handle ESC sequence.
            read -rsn1  tmp 
            if [[ "$tmp" == "[" ]]; then
                read -rsn1  tmp 
                case "$tmp" in
                    "A") major="up";;
                    "B") major="down";;
                    "C") major="right";;
                    "D") major="left";;
                esac
            fi
            # Flush "stdin" with 1  sec timeout.
            read -rsn5 -t 0
            ;;
        # Other one byte (char) cases. Here only quit.
        "") minor="enter";;
        [Jj]) minor="down";;
        [Kk]) minor="up";;
    esac

    if [[ $minor == "" ]]; then
        char="$major"
    else
        char="$minor"
    fi
}

movepos() {
    echo ""
    ((position+=$1))
}

 # choose the kubeconfig
choose() {
    chosen="${dirs[$1]}"
    eval 'export KUBECONFIG=$filepath$chosen/config'
    echo Exported to $(kubectl config view -o template --template='{{ index . "current-context" }}')
    if [[ "$token" = true ]]; then 
        if [[ -f "$filepath$chosen/token" ]]; then 
            pbcopy < "$filepath$chosen/token"
            echo "Copied token to clipboard."
        else
            echo "Could not find token at $filepath$chosen/token"
        fi
    fi
    # execute the shell with your new values
    if [[ "$dashboard" = true ]]; then 
        echo "Opening dashboard..."
        open $url
        kubectl proxy
    else
        $SHELL -i
    fi
    exit
}

# main function!
SelectListing() {
    IFS="$oIFS"
    if [[ "$dirs" = "" ]]; then
        echo "Looks like you have no kubeconfigs added, see '<script> tldr' to add one"
        exit
    fi
    while true; do
        clear
        echo "\033[31;1mKubeconfig Picker\033[0m"
        len=${#dirs[@]}
        ((lensub=len-1))

        # checks for values below 0, and above the maximum
        [[ $position -gt $lensub ]] && position=$lensub
        [[ $position -lt 0 ]] && position=0

        for index in ${!dirs[@]}; do
            if [[ $index = $position ]]; then
                echo "${dirs[$index]} <<"
            else
                echo "${dirs[$index]}"
            fi
        done

        charin

        case $char in
            "up") movepos -1;;
            "down") movepos 1;;
            "enter") choose $position;;
        esac
    done
}

AddListing() { 
    ReadInFile $input_file
    Verify
    mkdir -p $filepath$input_name
    [[ ! -z "$input_token" ]] && echo "$input_token" >> $filepath$input_name/token && echo "Found and wrote token."
    cp $input_file $filepath$input_name/config
    echo "Added $input_name"
}


# this is the part that actually executes the code!
case "$mode" in
    add) AddListing ;;
    del) DeleteListing ;;
    sel) SelectListing ;;
esac
