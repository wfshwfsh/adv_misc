#!/bin/bash
if [ $1 -eq 1 ]; then
       # L3 cache way: 0xfff
       sudo wrmsr 0xc90 0x3f
       sudo wrmsr 0xc91 0xfc0
 
       # Ecore L2 cache way: 0xffff
       sudo wrmsr -p4 0xd10 0xff
       sudo wrmsr -p5 0xd10 0xff
       sudo wrmsr -p6 0xd11 0xff00
       sudo wrmsr -p7 0xd10 0xff
 
       # Set RT Core 6 affinity to CLOS 1, other cores still use CLOS 0
       sudo wrmsr -p6 0xc8f 0x100000000
else
       # Set COS of all cores to COS0
       sudo wrmsr 0xc8f 0x0 -a
 
       # L3 cache way: 0xfff
       sudo wrmsr 0xc90 0xfff
       sudo wrmsr 0xc91 0xfff
 
       # Ecore L2 cache way: 0xffff
       sudo wrmsr -p4 0xd10 0xffff
       sudo wrmsr -p5 0xd10 0xffff
       sudo wrmsr -p6 0xd10 0xffff
       sudo wrmsr -p7 0xd10 0xffff
 
       sudo wrmsr -p4 0xd11 0xffff
       sudo wrmsr -p5 0xd11 0xffff
       sudo wrmsr -p6 0xd11 0xffff
       sudo wrmsr -p7 0xd11 0xffff
 
fi
