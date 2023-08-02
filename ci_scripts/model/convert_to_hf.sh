#!/bin/bash

source ./ci_scripts/common/variables.sh
[[ -n ${DATA_VOLUME} ]] || { echo "Should set DATA_VOLUME first before ci, exit."; exit 1; }
[[ -n ${GITHUB_WORKSPACE} ]] || { echo "Should set GITHUB_WORKSPACE first before ci, exit."; exit 1; }

readonly CKPTS_INPUT="${DATA_VOLUME}/lm_data/alpaca_data/llm_ckpts/20"
readonly CKPTS_OUTPUT="${GITHUB_WORKSPACE}/hf_ckpt"
readonly TOKENIZER="${GITHUB_WORKSPACE}/hf_ckpt/tokenizer.model"
readonly CONFIG="${GITHUB_WORKSPACE}/hf_ckpt/config.json"
readonly INERNLM="${GITHUB_WORKSPACE}/hf_ckpt/modeling_internlm.py"
exit_code=0
expected_num=9

source ./ci_scripts/common/basic_func.sh

echo "Start to test convert2hf.py."

if [[ -d ${CKPTS_OUTPUT} ]]; then
    if ! rm -rf ${CKPTS_OUTPUT}/*; then
       echo "Cleaning cached file in ${CKPTS_OUTPUT} failed, exit."
       exit 1
    fi
fi

python ./tools/transformers/convert2hf.py --src_folder ${CKPTS_INPUT} --tgt_folder ${CKPTS_OUTPUT} --tokenizer ./tools/V7_sft.model

#assert exists model
file_list=($TOKENIZER $CONFIG $INERNLM)
for file in ${file_list[@]}; do
    if [[ ! -f ${file} ]];then
        echo "File ${file} does not exist."
        exit_code=$(($exit_code + 1))
    fi
done

num=$(num_files ${CKPTS_OUTPUT})

if [[ ${num} -ne ${expected_num} ]]; then
    echo "Expect: ${expected_num} files, Actual: ${num} files."
    exit_code=$(($exit_code + 1)) 
fi

# clean the test files.
if ! rm -rf ${CKPTS_OUTPUT}/*; then
    echo "Cleaning cached file in ${CKPTS_OUTPUT} failed."
    exit_code=$(($exit_code + 1))
fi

exit $exit_code
