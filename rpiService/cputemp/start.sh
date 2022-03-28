#!/bin/bash

CT=`ps -ef | grep python | grep cputemp.py | wc -l`

if [ $CT -lt 1 ];then
  cd `dirname $0`
  nohup sudo ./cputemp.py > cputemp.log 2>&1 &
  echo cputemp started
else
  ps -ef | grep python | grep cputemp.py 
  echo cputemp is running
fi
