#!/bin/bash

[[ -n ${GITHUB_WORKSPACE} ]] || { echo "Should set GITHUB_WORKSPACE first before ci, exit."; exit 1; }
readonly CKPTS_PATH="$GITHUB_WORKSPACE/llm_ckpts"
readonly CKPTS20_PATH="$GITHUB_WORKSPACE/llm_ckpts/20"
readonly CKPTS_OUTPUT="${CKPTS20_PATH}/*.pt"
expected_num=21
exit_code=0

source ./ci_scripts/common/basic_func.sh

echo "Start to test torch training."

if [[ -d ${CKPTS20_PATH} ]]; then
    if ! rm -rf ${CKPTS20_PATH}/*; then
       echo "Cleaning cached file in ${CKPTS20_PATH} failed, exit."
       exit 1
    fi
fi

srun -p llm2 -N 1 torchrun --nnodes=1 --nproc_per_node=8 --master_port=29501 train.py --config ./ci_scripts/train/ci_7B_sft.py --launcher torch

num=$(num_files ${CKPTS_OUTPUT})
if [[ ${num} -ne ${expected_num} ]]; then
    echo "Expect: ${expected_num} files, Actual: ${num} files."
    exit_code=$(($exit_code + 1)) 
fi

# clean the test files.
if ! rm -rf ${CKPTS_PATH}/*; then
    echo "Cleaning cached file in ${CKPTS_PATH} failed."
    exit_code=$(($exit_code + 1))
fi

exit $exit_code
