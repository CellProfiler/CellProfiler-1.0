#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MCR environment for the current $ARCH and executes 
# the specified command.
#

#########################################
## ** Assuming default location of MCR -- Change if you have a non-standard MCR install **
MCRROOT=/Applications/MATLAB/MATLAB_Compiler_Runtime/v711

## Added for OS X version checking.  
## DISPLAY variable needs to be set for OS < 10.5
sysver=`sw_vers -productVersion | cut -c 1-4`

if [ $sysver = 10.5 -o $sysver = 10.6 ]
then
	#echo "The DISPLAY variable is not being set manually, because you are running OS $sysver.  This "
	echo ""
elif [ $sysver = 10.4 -o $sysver = 10.3 ]
then
	export DISPLAY=":0.0"
else
	echo "This system is too old, before OS 10.3"
fi
###########################################

exe_name=$0
exe_dir=`dirname $0`
echo "------------------------------------------"
echo Setting up environment variables
echo ---
MWE_ARCH="maci" ;
if [ "$MWE_ARCH" = "sol64" ] ; then
	LD_LIBRARY_PATH=.:/usr/lib/lwp:${MCRROOT}/runtime/maci ; 
else
  	DYLD_LIBRARY_PATH=.:${MCRROOT}/runtime/maci ;
fi
DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/bin/maci ;
DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/os/maci;
if [ "$MWE_ARCH" = "maci" -o "$MWE_ARCH" = "maci64" ]; then
	DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:/System/Library/Frameworks/JavaVM.framework/JavaVM:/System/Library/Frameworks/JavaVM.framework/Libraries;
else
	MCRJRE=${MCRROOT}/sys/java/jre/maci/jre/lib/ ;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
fi
XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
export DYLD_LIBRARY_PATH;
export XAPPLRESDIR;
echo DYLD_LIBRARY_PATH is ${DYLD_LIBRARY_PATH};
shift 1
${exe_dir}/CellProfiler $*
exit
