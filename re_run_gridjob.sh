#!/bin/bash
#Script for reusbmission of failed grid jobs (bad job nodes and mysql server error)

#variables to use the updated proxy certificate
export ROLE=Analysis
export X509_USER_PROXY=/var/tmp/${USER}.${ROLE}.proxy

source /e906/app/software/script/setup-jobsub-spinquest.sh

dir_scripts=$(dirname $(readlink -f $BASH_SOURCE))
dir_recofile=/pnfs/e1039/persistent/cosmic_recodata/$jobname

#loop over submitted runs after ~1 hour of job submission
while read -r RunNum N_splits reco_status; do
    
    #[[ $RunNum = \#* ]] && paste <(echo RunNum) <(echo N_splits) <(echo reco_status)>>reco_status_tmp.txt && continue

    if [[ $reco_status -eq 1 ]]; then #&& continue
	
	run_dir=($(printf 'run_%06d' $RunNum) )

	N_GOOD_LOG=0
	
	
	#loop over the log files of the submitted runs
	for i in $dir_recofile/$run_dir/*/log/log.txt; do
	    echo $i
	    [[ ! -e $i ]] && continue
            
	    job_status=$(tail -1 "$i" | head -1) #reco_status from root -l {macro} command in gridrun_data.sh	
	    
	    echo $job_status

            if [ "$job_status" = "0" ]; then
		(( N_GOOD_LOG++ ))
	    fi

	    if [ "$job_status" != "0" ]; then #if there is error

		resub_file=$(tail -2 "$i" | head -1) #data file cout from gridrun
		resub_file_dir=${resub_file%'.root'}

		
		#remove the log and output files if any   
		rm $dir_recofile/$run_dir/$resub_file_dir/log/log.txt
		rm $dir_recofile/$run_dir/$resub_file_dir/out/*.root
		
		#resubmit the grid job
		$dir_scripts/gridsub_data.sh $run_dir 1 $run_name 0 splitting echo $resub_file
		
	    fi
	done

	if [ $N_splits -eq $N_GOOD_LOG ]; then
	    reco_status=2
	fi

    fi

    paste <(echo "$RunNum") <(echo "$N_splits") <(echo "$reco_status")>>$dir_scripts/reco_status_tmp.txt
    
done <$dir_scripts/reco_status.txt

#update the reco_status
mv $dir_scripts/reco_status_tmp.txt $dir_scripts/reco_status.txt
