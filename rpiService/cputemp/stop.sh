#!/bin/bash

CT=`ps -ef | grep python | grep cputemp.py | wc -l`

if [ $CT -lt 1 ];then
  echo cputemp is not running
else
  sudo kill -9 `ps -ef | grep python | grep cputemp.py | awk '{print $2}'`
  echo killed cputemp 
fi
