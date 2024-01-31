#!/bin/bash 
#A master script to copy the decoded runs from /data2/ area and run it in grid
#Author: Abinash pun

#variables to use the updated proxy certificate
export ROLE=Analysis
export X509_USER_PROXY=/var/tmp/${USER}.${ROLE}.proxy

dir_scripts=$(dirname $(readlink -f $BASH_SOURCE))
FILE_RECO_STAT=$dir_scripts/reco_status.txt

#grid setup script
source /e906/app/software/script/setup-jobsub-spinquest.sh

##list out all the decoded runs and save the runid (by kenichi)
mysql --defaults-file=/data2/e1039/resource/db_conf/my_db1.cnf     --batch --skip-column-names     --execute='select run_id from deco_status where deco_status = 2 order by run_id desc'     user_e1039_maindaq >$dir_scripts/list.txt

##find out the difference between the two list and copy it to pnfs/e1039/tape_backed/decoded_data area
grep -vxf $dir_scripts/list_hold.txt $dir_scripts/list.txt >$dir_scripts/run_list.txt

##Loop over new decoded data
while read RunNum; do
  
  run_dir=($(printf 'run_%06d' $RunNum) )
  echo $run_dir
  
  ##no. of splits in corresponding run
  N_splits=$(ls /data2/e1039/dst/$run_dir/ | wc -l)
  echo $N_splits

  reco_status=0

  if [ $N_splits -gt 1 ]; then #choose the runs with more than 1 splits only

    #copy the decoded data to tape_backed area
    cp -ru /data2/e1039/dst/$run_dir /pnfs/e1039/tape_backed/decoded_data

    #submit the grid job
    $dir_scripts/gridsub_data.sh $run_dir 0 $RunNum 0 splitting

    reco_status=1    

  fi

 paste <(echo "$RunNum") <(echo "$N_splits") <(echo "$reco_status")>>$FILE_RECO_STAT

done <$dir_scripts/run_list.txt

##update the holding list
cat $dir_scripts/run_list.txt >>$dir_scripts/list_hold.txt

