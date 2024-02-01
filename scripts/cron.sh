#!/bin/bash

# get user environment variables
source ${HOME}/.bashrc
[ -z ${MAT_CONV_BRANCH_NAME} ] && echo "MAT_CONV_BRANCH_NAME not defined in ${HOME}/.bashrc" && exit 1
[ -z ${MAT_CONV_TBS} ] && echo "MAT_CONV_TBS not defined in ${HOME}/.bashrc" && exit 1

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
  ./comp.sh > ./../../../reports/report_${tb}_`date +%a-%b-%d_%H-%M-%S`.log
  echo "Exited with code $?"
  popd 1> /dev/null
  echo -e "\n\n"
done

popd
