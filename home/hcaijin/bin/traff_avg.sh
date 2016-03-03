#!/bin/bash
echo -n "which nic?"
read eth
echo "the nic is "$eth
echo -n "how much seconds:"
read sec
echo "duration is "$sec" seconds, wait please..."
infirst=$(awk '/'$eth'/{print $1 }' /proc/net/dev |sed 's/'$eth'://')
outfirst=$(awk '/'$eth'/{print $10 }' /proc/net/dev)
sumfirst=$(($infirst+$outfirst))
sleep $sec"s"
inend=$(awk '/'$eth'/{print $1 }' /proc/net/dev |sed 's/'$eth'://')
outend=$(awk '/'$eth'/{print $10 }' /proc/net/dev)
sumend=$(($inend+$outend))
sum=$(($sumend-$sumfirst))
echo $sec" seconds total :"$sum"bytes"
aver=$(($sum/$sec))
echo "avrage :"$aver"bytes/sec"
