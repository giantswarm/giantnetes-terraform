#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ]
then
        echo "Insufficient number of args"
        echo "$0 <ive_ip_address>:<port> <output_file>"
        exit
fi
echo Connecting to $1
while ! `echo -n | openssl s_client -showcerts -connect $1 2>err.txt 1>out.txt`
do
      sleep 1s
      echo retrying
done
if [ "$?" -ne "0" ]
then
        cat err.txt
        exit
fi
echo -n Generating Certificate
grep -in "\-----.*CERTIFICATE-----"  out.txt | cut -f 1 -d ":" 1> out1.txt
let start_line=`tail -n 2 out1.txt | head -n 1`
let end_line=`tail -n 1 out1.txt`
if [ -z "$start_line" ]
then
        echo "error"
        exit
fi
let nof_lines=$end_line-$start_line+1
#echo "from $start_line to $end_line total lines $nof_lines"
echo -n " .... "
head -n $end_line out.txt | tail -n $nof_lines 1> out1.txt
openssl x509 -in out1.txt -outfo$ pem -out $2
echo done.
$ out.txt out1.txt err.txt