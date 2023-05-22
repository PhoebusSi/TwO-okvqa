#!/bin/bash
#!/usr/bin/env bash
#!/bin/sh
export load_pthpath=${10}
export pre_epo=${11}
export load_pthmodel=$load_pthpath/model_for_epoch_$pre_epo.pth

export NCCL_P2P_LEVEL=NVL
cd /opt/tiger/okvqa
export dataset=$1

export model_dir=$2
mkdir $model_dir
mkdir $load_pthpath


echo "$1, $2, $3, $4, $5, $6, $7, $8, $9, ${10}, ${11}, ${12}"
echo "dataset $1, model dir $2, input type $3, describe $4, lr $5, lr_LXM $6, batch_size $7, wiki num $8, gpu_num $9, load path ${10}, pre_epo ${11}, seed ${12}"


export input_type=$3
export describe=$4
export lr=$5
export lr_LXM=$6
export batch_size=$7
export wiki_num=$8
export gpu_num=$9
export seed=${12}
ports=(`echo $METIS_WORKER_0_PORT | tr ',' ' '`)
port=${ports[0]}

echo "total workers: ${ARNOLD_WORKER_NUM}"
echo "cur worker id: ${ARNOLD_ID}"
echo "gpus per worker: ${ARNOLD_WORKER_GPU}"
echo "master ip: ${METIS_WORKER_0_HOST}"
echo "master port: ${port}"



export OMP_NUM_THREADS=8
export NCCL_IB_DISABLE=0
export NCCL_IB_GID_INDEX=3
export NCCL_IB_HCA=${ARNOLD_RDMA_DEVICE}
export NCCL_SOCKET_IFNAME=eth0


python3 -m torch.distributed.launch --nproc_per_node $gpu_num  \
    --nnodes=${ARNOLD_WORKER_NUM} --node_rank=${ARNOLD_ID} --master_addr=${METIS_WORKER_0_HOST} --master_port ${port} \
    train4LXMT5_DDP.py \
    --dataset $dataset \
    --model_dir $model_dir \
    --input_type $input_type \
    --describe $describe \
    --learning_rate $lr \
    --learning_rate_LXM $lr_LXM \
    --validate \
    --gpt3 \
    --ofa finetune \
    --batch_size $batch_size \
    --load_pthpath $load_pthmodel \
    --num_wiki $wiki_num \
    --seed $seed
