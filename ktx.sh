#!/bin/sh

position=0
filepath=$HOME/.kubeconfigs/

# if filepath does not exist, make it!
if [ ! -d $filepath ]; then
    mkdir -p $filepath
    dirs=""
else 
    dirs=$(ls -l $filepath | grep "^d" | awk '{print $9}')
fi

url=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/

print_usage() {
    printf "Usage:
    Running with no arguments will open the selector menu
    add - adds a listing
        eg. ktx add <filename>
            ktx add <filename> --token <tokenfile> 
            ktx add <filename> --token <tokenfile> --name <context-name>
    del - deletes a listing
        eg. ktx del <context-name>
    sel - select a listing
        eg. ktx sel <context-name>
    tldr - prints the TLDR 
        eg. ktx tldr
    help - prints this 
        eg. ktx help"
    exit
}

print_tldr() {
    printf "Add a listing: ktx add <filename> --token <token file> --name <context-name>
    Delete a listing: ktx del <context-name>
    Select a listing (no arguments): ktx OR ktx select <context-name>"
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
        esac    
    else
        [[ -z $arg ]] && print_tldr # nothing here, theyve used it wrong
        case "$grab" in
           "name") input_name=$arg ;;
           "token") input_token=$arg ;;
        esac 
        grab=false
    fi
done

DeleteListing() {
# very short stuff, just deletes the given file
    if [[ $delete = true ]]; then
       [[ -z $input_file ]] && echo "No listing given!" && exit
       if [[ ! -d $filepath$input_file ]]; then 
           echo "No listing exists with the file $input_file"
       else
           rm -r $filepath$input_file
           echo "Deleted $filepath$input_file"
       fi
       exit
    fi
}
#
## read in single character input
#charin() {
#    minor=""
#    major=""
##   essentially when you enter in an arrow key youre actually entering in a string of 3
#    read -rsn1 ui
#    case "$ui" in
#        $'\x1b')    # Handle ESC sequence.
#            read -rsn1  tmp 
#            if [[ "$tmp" == "[" ]]; then
#                read -rsn1  tmp 
#                case "$tmp" in
#                    "A") major="up";;
#                    "B") major="down";;
#                    "C") major="right";;
#                    "D") major="left";;
#                esac
#            fi
#            # Flush "stdin" with 1  sec timeout.
#            read -rsn5 -t 0
#            ;;
#        # Other one byte (char) cases. Here only quit.
#        "") minor="enter";;
#        [Jj]) minor="down";;
#        [Kk]) minor="up";;
#    esac
#
#    if [[ $minor == "" ]]; then
#        char="$major"
#    else
#        char="$minor"
#    fi
#}
#
#movepos() {
#    echo ""
#    ((position+=$1))
#}
#
# # choose the kubeconfig
#choose() {
#    chosen="${dirs[$1]}"
#    eval 'export KUBECONFIG=$filepath$chosen/config'
#    echo Exported to $(kubectl config view -o template --template='{{ index . "current-context" }}')
#    if [[ "$token" = true ]]; then 
#        if [[ -f "$filepath$chosen/token" ]]; then 
#            pbcopy < "$filepath$chosen/token"
#            echo "Copied token to clipboard."
#        else
#            echo "Could not find token at $filepath$chosen/token"
#        fi
#    fi
#    # execute the shell with your new values
#    if [[ "$dashboard" = true ]]; then 
#        echo "Opening dashboard..."
#        open $url
#        kubectl proxy
#    else
#        $SHELL -i
#    fi
#    exit
#}
#
## main function!
#SelectListing() {
#    if [[ "$dirs" = "" ]]; then
#        echo "Looks like you have no kubeconfigs added, see <script> -h to add one"
#        exit
#    fi
#    while true; do
#        clear
#        echo "\033[31;1mKubeconfig Picker\033[0m"
#        [[ "$token" = true ]] && echo "Will try to copy token!"
#        [[ "$dashboard" = true ]] && echo "Will try to open dashboard!"
#        len=${#dirs[@]}
#        ((lensub=len-1))
#
#        # checks for values below 0, and above the maximum
#        [[ $position -gt $lensub ]] && position=$lensub
#        [[ $position -lt 0 ]] && position=0
#
#        for index in ${!dirs[@]}; do
#            if [[ $index = $position ]]; then
#                echo "${dirs[$index]} <<"
#            else
#                echo "${dirs[$index]}"
#            fi
#        done
#
#        charin
#
#        case $char in
#            "up") movepos -1;;
#            "down") movepos 1;;
#            "enter") choose $position;;
#        esac
#    done
#}
#
#AddListing() { 
#    if [[ -z "$input_name" ||  -z "$input_file" ]]; then 
#        echo "Ensure --config (optionally --token) and --name are all set!"
#    else 
#        mkdir -p "$filepath$input_name"
#        if [[ "$raw_file" = false ]]; then
#            [[ ! -f $input_file ]] && echo "Config file $input_name not valid!" && exit
#            cp $input_file $filepath$input_name/config
#            echo "Setting $filepath$input_name/config"
#            if [[ ! -f $input_token ]]; then 
#                echo "Did not recieve a token with --token. Ensure your cluster does not need one!" 
#            else
#                cp $input_token "$filepath$input_name/token"
#                echo "Setting $filepath$input_name/token"
#            fi
#        else
#            if [[ -z "$input_token" ]]; then
#                echo "Token not set! Will not add to listing."
#            else
#                echo $input_token > $filepath$input_name/token
#            fi
#            echo $input_file > "$filepath$input_name/config"
#        fi
#    fi
#}
#
#

# this is the part that actually executes the code!
case "$mode" in
    add) AddListing ;;
    del) DeleteListing ;;
    sel) SelectListing ;;
esac
