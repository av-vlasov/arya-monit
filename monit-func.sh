#!/bin/bash
option=;
set -x
source_var () {
    for VAR in $(ls *.var); do
        source $VAR
    done
}
check_LA () {
    LA=$(uptime | awk '{print$8}' | rev | cut -c 2- | rev | sed 's/,/./g')
    if (( $( echo "$LA >= $CORE" | bc -l) ))
    then
        $ECHO "ALARM! Load Averege = $LA in $($TIME)"
    elif (( $( echo "$LA >= $LIMIT_LA" | bc -l) ))
    then
        $ECHO "WARNING! Load Averege = $LA in $($TIME)"
    fi    
}
check_mem () {
    AVAIL_MEM=$(free -m | sed -s '1d' | awk '{print$7}' | head -n1)
    AVAIL_SWAP=$(free -m | sed -s '1d' | awk '{print$4}' | tail -n1)
    AVAIL_MEM_PERC=$(echo "scale=2; $AVAIL_MEM / $TOTAL_MEM; last * 100; scale=0" | bc | tail -n1 | cut -d'.' -f1)
    AVAIL_SWAP_PERC=$(echo "scale=2; $AVAIL_SWAP / $TOTAL_SWAP; last * 100; scale=0" | bc | tail -n1 | cut -d'.' -f1)
    if (( $(echo "$AVAIL_MEM <= 1" | bc -l) ))
    then
        $ECHO "ALARM! Free memory less 1% in $($TIME)" >> $LOG
    elif (( $(echo "$AVAIL_MEM_PERC <= $LIMIT_PERC" | bc -l) ))
    then
        $ECHO "Warning! Free memory less $LIMIT_PERC% $($TIME)" >> $LOG
    fi
    if (( $(echo "$AVAIL_SWAP <= 1" | bc -l) ))
    then
        $ECHO "ALARM! Free swap less 1%" >> $LOG
    elif (( $(echo "$AVAIL_SWAP_PERC <= $LIMIT_PERC" | bc -l) ))
    then
        $ECHO "Warning! Free swap less $LIMIT_PERC% $($TIME)" >> $LOG
    fi
}
check_space () {
    EXC="first_path_name"
    for LINE in $EXCLUDE_LIST; do
        EXC="$EXC\|$LINE"
    done
    for LINE in $(df -h | sed -s '1d' | grep -v "$EXC" | awk '{print$1";"$6";"$5}'); do
        NAME=$(echo $LINE | cut -d';' -f1)
        MOUNT_POINT=$(echo $LINE | cut -d';' -f2)
        USED_SPACE=$(echo $LINE | cut -d';' -f3 | cut -d'%' -f1)
        if [ "$USED_SPACE" -ge "$CRITICAL_SPACE_PERC" ]
        then
            $ECHO "ALARM! Used space in $MOUNT_POINT ($NAME) $USED_SPACE% in $($TIME)"
        elif [ "$USED_SPACE" -ge "$MAX_SPACE_PERC" ]
        then
            $ECHO "Warning! Used space in $MOUNT_POINT ($NAME) $USED_SPACE% in $($TIME)"
        fi
    done
}
check_services () {
    for SERV in $SERVICE_LIST; do
        if [[ -z $(ps aux | grep $SERV | grep -v grep 2>/dev/null) ]]
        then
            $ECHO "ALARM! Service $SERV not found in $($TIME)"
        fi
    done
}
source_var
set +x
