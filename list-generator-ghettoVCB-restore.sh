# Author: Travis Johnson
# 08/27/2017
# http://www.github.com/bashtheshell
#####################################


# SUMMARY: This script generates a list of applicable VMs (VMs backed-up by 'ghettoVCB.sh' script) to be restored.
# This script will automatically determine the appropriate disk format for each VM. The output file is intended to be 
# used with 'ghettoVCB-restore.sh' script. Supported disk formats are 'thin', 'eagerzeroedthick', and 'zeroedthick'.
# '2gbsparse' and other unidentified disk formats are not supported in this script and would ultimately assumed to be 
# 'zeroedthick'.


# WARNING: This script assumes all disks on each VM are using the same disk format as its first attached disk. 
# Proceed at your own risk. However, this script is harmless as it only generates output to a file used as input 
# file for William Lam's 'ghettoVCB-restore.sh' script. Please review the resulting file from this script before using.


# DISCLAIMER: This script is not affiliated, endorsed, or sponsored by William Lam or VMware Inc., or one of their affiliated 
# companies ("Dell Technologies, Inc.").


##############
# INSTRUCTION:
##############
# This script uses the following options: '[-s ARG]' and '-d ARG'
# '-s' is the directory where the script will search the subdirectories for backup. This can even be '/.' (root).
# '-d' is the destinated directory where the backup VMs will be restored to.


# vmfstools executable path
VMKFSTOOLS_CMD=/usr/bin/vmkfstools


# Desination restore directory
destinationDir=


# Find potential VMs that were backed up using ghettoVCB.sh ('/vmfs/volumes/' is the default)
searchDir=/vmfs/volumes/


#----------------------------START OF SCRIPT--------------------------------- 


# Help message
usage="Usage: [-s SOURCE_DIR_OF_BACKUP] -d DESTINATION_DIR_OF_RESTORE_LOCATION"


# Set flags for getopts loop
getOptsFlag=0
sFlag=0
dFlag=0


while getopts ":s:d:" ARGS
do
	getOptsFlag=1

	case $ARGS in
		s )
			searchDir="${OPTARG}"
			sFlag=1
	
			# Make sure there's a slash at the end of the path for 'find' command to work
			if [ -z "$(echo $searchDir | sed -n 's/\(\/\)$/\1/p')" ]
			then
				searchDir=${searchDir}"/"
			fi
			;;
		d )
			destinationDir="${OPTARG}"
			dFlag=1

			# Exit if directory is non-existent
			if [ ! -d "$destinationDir" ]
			then
				echo "Error: Invalid destination directory = \"${OPTARG}\""
				exit 1
			fi
			;;
		\? )
			echo "Invalid option: -${OPTARG}"
			echo $usage
			exit 1
			;;
		: )
			echo "Option -${OPTARG} requires an argument."
			echo $usage
			exit 1
			;;
		* )
			echo $usage
			exit 1
			;;
	esac
done


# Ensure each option has only one argument
totalArgsAllowed=0
if [[ $sFlag -eq 1 ]]
then
	totalArgsAllowed=$((totalArgsAllowed+2))
fi
if [[ $dFlag -eq 1 ]]
then
	totalArgsAllowed=$((totalArgsAllowed+2))
fi


# Exit if invalid argument(s) were used
if [[ $getOptsFlag -eq 0 ]] || [[ $dFlag -eq 0 ]] || [[ $totalArgsAllowed -ne $# ]]
then
	echo $usage
	exit 1
fi


# Prepare the output file
newfile=$PWD/restore-ghettoVCB-"$(date +%F_%H-%M-%S)"
echo '#"<DIRECTORY or .TGZ>;<DATASTORE_TO_RESTORE_TO>;<DISK_FORMAT_TO_RESTORE>"' >> $newfile
echo '# DISK_FORMATS' >> $newfile
echo '# 1 = zeroedthick' >> $newfile
echo '# 2 = 2gbsparse' >> $newfile
echo '# 3 = thin' >> $newfile
echo '# 4 = eagerzeroedthick' >> $newfile
echo '# e.g.' >> $newfile
echo '# "/vmfs/volumes/dlgCore-NFS-bigboi.VM-Backups/WILLIAM_BACKUPS/STA202I/STA202I-2009-08-18--1;/vmfs/volumes/himalaya-local-SATA.RE4-GP:Storage;1"' >> $newfile


# Search the subdirectories in the given directory
potentialPaths="$(find $searchDir -name "STATUS.ok" -type f -exec dirname {} \;)"


# List of valid VMs
validPaths=""


# Collect list of valid VM paths
for path in $potentialPaths
do
	if [ -n "$(find $path -name '*.vmx' -type f)" ] && [ -n "$(find $path -name '*.vmdk' -type f)" ]
	then
		validPaths="$validPaths${path} "
	fi
done


# Exit script if no valid VM path exists
if [ -z "$validPaths" ]
then
	echo "Error: No valid VM available to restore. Exiting script now."
	rm $newfile
	exit 1
fi


# For each vm, determine the correct disk format                                                                  
for path in $validPaths                                                                                           
do
	# Initialize the value for the current VM                                                                                   
	diskformat=""


	# Determine the appropriate disk format
	for diskfile in $(ls ${path} | grep -E '_[0-9]+.vmdk' | sort)
	do
		diskNum=$(echo $diskfile | sed 's/.*_\([0-9]\+\).vmdk$/\1/')
		filenamePrefix=$(echo $diskfile | sed 's/\(.*_\)[0-9]\+.vmdk$/\1/')

		if [ -n "$(grep 'ddb.thinProvisioned = "1"' ${path}/${diskfile})" ]
		then
			diskformat="3" # 'thin'
			break
		elif [ -n "$(${VMKFSTOOLS_CMD} -D ${path}/${filenamePrefix}${diskNum}-flat.vmdk | grep 'tbz 0')" ]
		then
			diskformat="4" # 'eagerzeroedthick'
			break
		else
			diskformat="1" # 'zeroedthick'
			break
		fi
	done


	# Append the result to file
	echo \""$path;$destinationDir;$diskformat"\" >> $newfile

done

#------------------------------END OF SCRIPT--------------------------------- 

