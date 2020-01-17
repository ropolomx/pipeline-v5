#!/bin/bash

export NAME_RUN=SRR3185137
# max limit of memory that would be used by toil to restart
export MEMORY=8G
# number of cores to run toil
export NUM_CORES=8
# clone of pipeline-v5 repo
export PIPELINE_FOLDER=/hps/research1/finn/saary/projects/skin_rna/pipeline-v5
export CUR_DIR=/hps/research1/finn/saary/projects/skin_rna/
# YML pattern would be modified with paths to raw file(s)
export YML=$PIPELINE_FOLDER/workflows/paul/wf.yml
# first part pipeline (before qc + qc step)
export CWL=$PIPELINE_FOLDER/workflows/paul/wf.cwl

echo "Activating envs"
source /hps/nobackup2/production/metagenomics/pipeline/tools-v5/auto_env.rc
source /hps/nobackup/production/metagenomics/software/toil-venv/bin/activate

# set dirs
export WORK_DIR=${CUR_DIR}/work-dir
export JOB_TOIL_FOLDER=${WORK_DIR}/job-store-wf
export TMPDIR=${WORK_DIR}/temp-dir/${NAME_RUN}

export OUT_DIR=${CUR_DIR}
export LOG_DIR=${OUT_DIR}/log-dir/${NAME_RUN}
export OUT_DIR_FINAL=${OUT_DIR}/results/${NAME_RUN}

echo "Create empty ${LOG_DIR}"
mkdir -p $LOG_DIR # && ` -rf $LOG_DIR/*


export JOB_GROUP=skin-rna
bgadd -L 200 /${USER}_${JOB_GROUP} > /dev/null
bgmod -L 200 /${USER}_${JOB_GROUP} > /dev/null
export TOIL_LSF_ARGS="-q production-rh74 -g /${USER}_${JOB_GROUP}"

mkdir -p $JOB_TOIL_FOLDER $TMPDIR $OUT_DIR_FINAL && \
cd $WORK_DIR && \
time cwltoil \
  --no-container \
  --batchSystem LSF \
  --disableCaching \
  --defaultMemory $MEMORY \
  --defaultCores $NUM_CORES \
  --jobStore $JOB_TOIL_FOLDER/${NAME_RUN} \
  --outdir $OUT_DIR_FINAL \
  --retryCount 3 \
  --logFile $LOG_DIR/${NAME_RUN}.log \
  --stats \
$CWL ${YML} > ${NUM_RUN}_out.json  # 2> $OUT_TOOL_1/run.log


echo " Reminder:
job-store-wf: ${JOB_TOIL_FOLDER}
temp-dir: ${TMPDIR}
log-dir: ${LOG_DIR}
result-dir: ${OUT_DIR_FINAL}"

echo "PIPELINE DONE"
