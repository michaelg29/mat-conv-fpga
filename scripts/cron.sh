#!/bin/bash

echo -e "Running mat_mult_fpga cronjob"
date
echo -e "\n\n"

# get user environment variables
src_path="${HOME}/.profile"
source ${src_path}
[ -z ${MAT_CONV_BRANCH_NAME} ] && echo "MAT_CONV_BRANCH_NAME not defined in ${src_path}" && exit 1
[ -z ${MAT_CONV_TBS[0]} ] && echo "MAT_CONV_TBS not defined in ${src_path}" && exit 1
echo -n "Pulling from branch ${MAT_CONV_BRANCH_NAME}, running testbenches ["
for tb in "${MAT_CONV_TBS[@]}"; do
    echo -n "${tb}, "
done
echo "]"

# get absolute directory of `cron.sh`
this_path=`dirname $0`
pushd ${this_path}

# pull changes in repository and checkout branch
git pull
[ $? -ne 0 ] && echo "Could not pull from GitHub." && exit 1
git checkout origin/${MAT_CONV_BRANCH_NAME} && git checkout ${MAT_CONV_BRANCH_NAME}
[ $? -ne 0 ] && echo "Could not checkout branch '${MAT_CONV_BRANCH_NAME}'." && exit 1

# create directory
mkdir -p ../reports

# iterate through target testbenches
for tb in "${MAT_CONV_TBS[@]}"; do
  echo "=====COMPILING ${tb}====="
  pushd ./../rtl/sim/${tb} 1> /dev/null
  ./clean.sh
  ./comp.sh > ./../../../reports/comp_report_${tb}_`date +%a-%b-%d_%H-%M-%S`.log
  if [ $? -eq 0 ]; then
    echo "Compilation passed!"
  else 
    echo "Compilation failed, exited with code $?"
  fi
  #./sim.sh > ./../../../reports/sim_report_${tb}_`date +%a-%b-%d_%H-%M-%S`.log
  if [ $? -eq 0 ]; then
    echo "Simulation passed!"
  else 
    echo "Simulation failed, exited with code $?"
  fi
  popd 1> /dev/null
  echo -e "\n\n"
done

popd
