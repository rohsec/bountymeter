#!/bin/bash

#########################################################
#                   CONSTANTS                           #
#########################################################
bred='\033[1;31m'
bblue='\033[1;34m'
bgreen='\033[1;32m'
yellow='\033[0;33m'
red='\033[0;31m'
blue='\033[0;34m'
green='\033[0;32m'
reset='\033[0m'
file=~/.bountymeter/bm.json
filepath=~/.config/bountymeter/

#########################################################
#                   Usage Menu                          #
#########################################################
usage(){
    logo
    printf "Example Usage:"
    echo 
    printf "\n[*] To initalize bountymeter\n\tbm init bounty_target username\n\n[*] Add new bounty amount to specified month\n\tbm add month_name bounty_amount\n\n[*] Remove specified bounty_amount from specidief month\n\tbm sub month_name bounty_amount\n\tMonths Format : [ January, February, March...]<First letter needs to be Capital>\n\n[*] Display an Interactive Stats Card\n\tbm stats"

}

#########################################################
#                   Initialize Function                 #
#########################################################
initt(){
printf "$blue[$green + $blue]$bblue Intitalizing...(✓)$reset"
echo '{"target":'$1',"total":0,"username":"'$2'","progress":0,"months":[]}' > $file
## appending month list to json file...
printf "\n$blue[$green + $blue]$bblue Setting up config $file...(✓)$reset"
for i in $(locale mon|sed 's/;/\n/g')
do
tempjson=$(jq --arg i $i '.months += [{"name":"'${i}'","value":0}]' $file)
echo $tempjson > $file
done
sleep 1
printf "\n$blue[$green + $blue]$bblue BountyMeter set up successfully...(✓)$reset"
}

#########################################################
#                   Initialize Check Function           #
#########################################################
init_check(){
    if [ -f $file ]
    then
    mkdir ~/.bountymeter && touch $file
    initt $1 $2
    else
    rm $file
    initt $1 $2
    fi
}
#########################################################
#                   ProgressBar Util                    #
#########################################################
progressbar(){
   function is_int() { test "$@" -eq "$@" 2> /dev/null; } 

# Parameter 1 must be integer
if ! is_int "$1" ; then
   echo "Not an integer: ${1}"
   exit 1
fi

# Parameter 1 must be >= 0 and <= 100
if [ "$1" -ge 0 ] && [ "$1" -le 100 ]  2>/dev/null
then
    :
else
    echo bad volume: ${1}
    exit 1
fi

# Main function designed for quickly copying to another program 

    Bar=""                      # Progress Bar / Volume level
    Len=25                      # Length of Progress Bar / Volume level
    Div=4                       # Divisor into Volume for # of blocks
    Fill="▒"                    # Fill up to $Len
    Arr=( "▉" "▎" "▌" "▊" )     # UTF-8 left blocks: 7/8, 1/4, 1/2, 3/4

    FullBlock=$((${1} / Div))   # Number of full blocks
    PartBlock=$((${1} % Div))   # Size of partial block (array index)

    while [[ $FullBlock -gt 0 ]]; do
        Bar="$Bar${Arr[0]}"     # Add 1 full block into Progress Bar
        (( FullBlock-- ))       # Decrement full blocks counter
    done

    # If remainder zero no partial block, else append character from array
    if [[ $PartBlock -gt 0 ]]; then
        Bar="$Bar${Arr[$PartBlock]}"
    fi
    while [[ "${#Bar}" -lt "$Len" ]]; do
        Bar="$Bar$Fill"         # Pad Progress Bar with fill character
    done

    echo "$Bar"
    exit 0
} 

#########################################################
#                   STATS                               #
#########################################################
stats(){
    if [ -f $file ]
    then
    total=$(jq -r '.total' $file)
    username=$(jq -r '.username' $file)
    target=$(jq -r '.target' $file)
    progress=$(jq -r '.progress' $file)
    progress_con=$(echo "($progress+0.5)/1" | bc)
    year=$(date +%Y)
    this_month=$(jq -r --arg this_mon $(date +%B) '.months[]|select(.name==$this_mon)|.value' $file)
    highest_profit=$(jq -r '.months | max_by(.value) | "\(.value)(\(.name))"' $file)

    ## Creating Stats Card
    printf "$blue================= Hola, $red$username$reset 👋 $blue=================$reset" #|pv -qL $[95+(-2 + RANDOM%5)]
    printf "\n🎯$blue Target: $green\$$target\t💰$blue Bounty Earned: $green\$$total\n\n$blue💵 This Month: $green\$$this_month\t💸$blue Highest Profit: $green\$$highest_profit\n\n$blue📊 Progress:$green $progress_con%% "
    progressbar $progress_con #|pv -qL $[55+(-2 + RANDOM%5)]
    else
    usage
    fi

}

#########################################################
#                   Total Function                      #
#########################################################

total(){
    if [ -f $file ]
    then
    total=$(jq -r '.total' $file)
    printf "💰$bblue Total Bounty: $bgreen\$$total $reset"
    else
    usage
    fi
}

#########################################################
#                   Monthly Function                    #bm
#########################################################
monthly(){
    if [ -f $file ]
    then
    monthly=$(jq -r --arg mon $1 '.months[]|select(.name == $mon)|.value' $file)
    printf "💰$bblue Bounty earned in $yellow$1 : $bgreen\$$monthly $reset"
    else
    usage
    fi
}

#########################################################
#                   ADD Function                        #
#########################################################
add(){
    if [ -f $file ]
    then
    jq --argjson new_value $2 --arg mon_name $1 '.months |= map(if .name == $mon_name then .value += $new_value else . end) | . ' $file > temp.json && mv temp.json $file
    jq '.total = (reduce .months[] as $m (0; . + $m.value))' $file > tmp.json && mv tmp.json $file
    jq '.progress = (.total / .target * 100)' $file > tmp.json && mv tmp.json $file
    printf "$blue[$green + $blue]$bblue Bounty of $red\$$2$bblue added to $byellow$1 $blue(✓) $reset"
    else
    usage
    fi
}

#########################################################
#                   SUB Function                        #
#########################################################
sub(){
    if [ -f $file ]
    then
    jq --argjson new_value $2 --arg mon_name $1 '.months |= map(if .name == $mon_name then .value -= $new_value else . end) | . ' $file > temp.json && mv temp.json $file
    jq '.total = (reduce .months[] as $m (0; . + $m.value))' $file > tmp.json && mv tmp.json $file
    jq '.progress = (.total / .target * 100)' $file > tmp.json && mv tmp.json $file
    printf "$blue[$green - $blue]$bblue Bounty of $red\$$2$bblue removed from $byellow$1 $blue(✓) $reset"
    else
    usage
    fi
}

#########################################################
#                   Logo                                #
#########################################################
logo(){
printf "${bred}"
printf '''    __                      __                       __           
   / /_  ____  __  ______  / /___  ______ ___  ___  / /____  _____
  / __ \/ __ \/ / / / __ \/ __/ / / / __ `__ \/ _ \/ __/ _ \/ ___/
 / /_/ / /_/ / /_/ / / / / /_/ /_/ / / / / / /  __/ /_/  __/ /    
/_.___/\____/\__,_/_/ /_/\__/\__, /_/ /_/ /_/\___/\__/\___/_/     
                            /____/                                                        
 '''
 printf "${green}==================== ${blue}Developed By: ${yellow}@hackinsec${bred} " 

# '''
printf "${reset}"
printf "\n${yellow}=========== A utility tool for Bug Hunters ==========\n${reset}" #|pv -qL $[55+(-2 + RANDOM%5)]


}


#########################################################
#                   Main Script                         #
#         Will Fix This when I get Time...              #
#########################################################
if [[ $# -gt 0 ]] ; then
case $1 in
    init)
    if [[ $2 != "" ]] && [[ $2 == ?(-)+([0-9]) ]] && [[ $3 != "" ]]; then
    init_check $2 $3
    else
    usage
    fi
    ;;
    add)
    if [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]] && [[ $3 == ?(-)+([0-9]) ]] 
    then
    add $2 $3
    else 
    usage
    fi
     ;;
    sub)
    if [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]] && [[ $3 == ?(-)+([0-9]) ]] ; then
    sub $2 $3
    else
    usage
    fi
     ;;
    total)
    total
     ;;
    monthly)
    if [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]]; then
    monthly $2
    else
    usage
    fi
    ;;
    stats)
    stats
     ;;
    *) 
    usage
    ;;
esac
else
usage
fi

## This was first implemntation but we like to do it fancy so used switch case ;)

# if [[ $1 == "init" ]] && [[ $2 != "" ]] && [[ $2 == ?(-)+([0-9]) ]] && [[ $3 != "" ]]
# then
# init_check $2 $3
# elif [[ $1 == "add" ]] && [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]] && [[ $3 == ?(-)+([0-9]) ]]
# then
# add $2 $3
# elif [[ $1 == "sub" ]] && [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]] && [[ $3 == ?(-)+([0-9]) ]]
# then
# sub $2 $3
# elif [[ $1 == "total" ]]
# then
# total
# elif [[ $1 == "monthly" ]] && [[ $2 != "" ]] && [[ $2 != ?(-)+([0-9]) ]]
# then
# monthly $2
# elif [[ $1 == "stats" ]]
# then
# stats
# else
# usage
# fi 