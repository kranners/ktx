#!/bin/sh

position=0
filepath=~/.kubeconfigs/

if [[ ! -d $filepath ]]; then
    mkdir -p $filepath
    dirs=""
else 
    dirs=($(ls -l $filepath | grep "^d" | awk '{print $9}'))
fi

url=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/

function print_usage() {
    printf "Usage:
    -h Show this list
    -d Start dashboard instead of shell
    -t Copy a token if one is present
    -D <name> delete a listing
    -a Add new kubeconfig to list!
        -r raw input instead of file location
        -f Relative location of kubeconfig file
        -T Relative location of token file (just the token! no 'token:')
        -n Name of entry in list"
}

# flag values
token=false
dashboard=false
delete=false
raw_file=false
add_new=false # whether to select or to add a new config
do_main=true # if false, will not execute main script. used for error catching

while getopts 'hrtdaD:f:T:n:' opt; do
    case $opt in
        t) token=true ;;
        d) dashboard=true ;;
        r) raw_file=true ;;
        a) add_new=true && do_main=false ;;
        f) input_file="${OPTARG}" ;;
        T) input_token="${OPTARG}" ;;
        n) input_name="${OPTARG}" ;;
        D) input_file="${OPTARG}" && delete=true && do_main=false ;;
        h) print_usage && exit ;;
        *) print_usage && exit ;;
    esac
done

# very short stuff, just deletes the given file
if [[ $delete = true ]]; then
   [[ -z $input_file ]] && echo "No listing given!" && exit
   if [[ ! -d $filepath$input_file ]]; then 
       echo "No listing exists with the name $input_file"
   else
       rm -r $filepath$input_file
       echo "Deleted $filepath$input_file"
   fi
   exit
fi

# read in single character input
function charin() {
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

function movepos() {
    echo ""
    ((position+=$1))
}

 # choose the kubeconfig
function choose() {
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
if [[ "$do_main" = true ]]; then
    if [[ "$dirs" = "" ]]; then
        echo "Looks like you have no kubeconfigs added, see <script> -h to add one"
        exit
    fi
    while true; do
        clear
        echo "\033[31;1mKubeconfig Picker\033[0m"
        [[ "$token" = true ]] && echo "Will try to copy token!"
        [[ "$dashboard" = true ]] && echo "Will try to open dashboard!"
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
fi

if [[ "$add_new" = true ]]; then
    if [[ -z "$input_name" ||  -z "$input_file" ]]; then 
        echo "Ensure --config (optionally --token) and --name are all set!"
    else 
        mkdir -p "$filepath$input_name"
        if [[ "$raw_file" = false ]]; then
            [[ ! -f $input_file ]] && echo "Config file $input_name not valid!" && exit
            cp $input_file $filepath$input_name/config
            echo "Setting $filepath$input_name/config"
            if [[ ! -f $input_token ]]; then 
                echo "Did not recieve a token with --token. Ensure your cluster does not need one!" 
            else
                cp $input_token "$filepath$input_name/token"
                echo "Setting $filepath$input_name/token"
            fi
        else
            if [[ -z "$input_token" ]]; then
                echo "Token not set! Will not add to listing."
            else
                echo $input_token > $filepath$input_name/token
            fi
            echo $input_file > "$filepath$input_name/config"
        fi
    fi
fi
