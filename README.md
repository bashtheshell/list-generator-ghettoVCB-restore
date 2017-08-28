# list-generator-ghettoVCB-restore
Automatically generate a list of "ghettoVCB" backed-up VMs to be restored.


### SUMMARY: 
This script generates a list of applicable VMs (VMs backed-up by 'ghettoVCB.sh' script) to be restored. This script will automatically determine the appropriate disk format for each VM. The output file is intended to be used with 'ghettoVCB-restore.sh' script. Supported disk formats are 'thin', 'eagerzeroedthick', and 'zeroedthick'. '2gbsparse' and other unidentified disk formats are not supported in this script and would ultimately assumed to be 'zeroedthick'.


Ex.

`./list-generator-ghettoVCB-restore.sh -s /vmfs/volumes/ -d /vmfs/volumes/main-datastore`


### WARNING: 
This script assumes all disks on each VM are using the same disk format as its first attached disk. Proceed at your own risk. However, this script is harmless as it only generates output to a file used as input file for William Lam's 'ghettoVCB restore.sh' script. Please review the resulting file from this script before using.


### DISCLAIMER: 
This script is not affiliated, endorsed, or sponsored by William Lam or VMware Inc., or one of their affiliated companies ("Dell Technologies, Inc.").

