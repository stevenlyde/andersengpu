#!/bin/sh

dir='input'
make 

for test in $1
# for test in ex gcc nh perl vim svn tshark python gimp gdb php pine mplayer linux gap gs
   do
    if [ "$test" = "gcc" ] 
       then
         export GCC=1
    fi
    for i in `seq 1 $2`
      do
        ../../bin/linux/release/andersen  ${dir}/${test}_nodes.txt.gz ${dir}/${test}_constraints_after_hcd.txt.gz ${dir}/${test}_hcd.txt.gz ${dir}/${test}_correct_soln_001.txt.gz 1 1                
    done
done
