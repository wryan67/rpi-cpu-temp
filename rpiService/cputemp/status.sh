#!/bin/bash

CT=`ps -ef | grep python | grep cputemp.py | wc -l`

if [ $CT -lt 1 ];then
  echo cputemp is not running
else
  ps -ef | grep python | grep cputemp.py 
  echo cputemp is running
fi
