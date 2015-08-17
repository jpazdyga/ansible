#!/bin/bash

updatehosts() {

        awk '{print} /\[newcoreoshosts\]/ {exit}' $ansiblehosts > $tmpfilenamenew
        cat $tmpfilenameold >> $tmpfilenamenew
        echo -e "$ipaddress\n" >> $tmpfilenamenew
        sed -n '/\[newcoreoshosts:vars\]/,//p' $ansiblehosts >> $tmpfilenamenew
        cat $tmpfilenamenew
exit 0
        cp $ansiblehosts $ansiblehosts.bkp
        cp $tmpfilenamenew $ansiblehosts
        rm -fr tmpfilenameold
        rm -fr tmpfilenamenew

}

proceed() {

        sed -n '/\[newcoreoshosts\]$/,/\[newcoreoshosts:vars\]/p' $ansiblehosts | grep -v "\[" | grep . > $tmpfilenameold
        echo "----"; cat $tmpfilenameold
        alreadythere=`grep $ipaddress $tmpfilenameold`
        if [ -z "$alreadythere" ];
        then   
                updatehosts
        else   
                exit 1
        fi

}

conncheck() {

        result=`ping -q -c5 -i .5 $ipaddress 2>&1 > /dev/null; echo $?`
        if [ "$result" -eq "0" ];
        then
                proceed
        else
                echo "Waiting for host to appear..."
                sleep 10
                conncheck
        fi

}

ipaddress="$1"
ansiblehosts="/etc/ansible/hosts"
tmpfilenameold="$HOME/tmp/newcoreoshost.old"
tmpfilenamenew="$HOME/tmp/newcoreoshost.new"

conncheck
