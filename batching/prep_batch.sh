#!/bin/bash

#set -x -v

########################### Params
cells_per_rank_sets=(1000 10000)
nodes_min=1
nodes_max=1024
nodes_scaling=2

config=small
model=ring
dryrun=true
tag=default

ranks_per_node=2
cpus_per_task=24

toppath=$(readlink -f "$(pwd)"/..)
execpath="$toppath"/benchmarks/engines/busyring/arbor
partition=osws_wed_am_large

# flags for building or running jobs: choices (:/false)
build_jobs=:
run_jobs=:
clean=false
###########################

append() {
    eval "$1[\${#$1[@]}]=\$2"
    #if [ -n $1 ]; then
    #    local var=$1; shift
    #fi
    #local val=$1
    #var[${#var[@]}]=$val
}

build-sets() {
    nodes_sets=()
    
    local nodes=$nodes_min
    while (( nodes <= nodes_max )); do
        append nodes_sets $nodes
        nodes=$(( nodes * nodes_scaling ))
    done
}

eval-cmdline() {
    while (($# > 0)); do
        eval $1
        shift
    done
    
    output_path="$toppath"/batching/batch-benchmarks/$tag/$model/$config/$dryrun
    $clean && rm -rf $output_path
    mkdir -p $output_path
}

do-sed() {
    echo "Processing $1"
    sed -r \
        -e "s+@TOPPATH@+$toppath+g" \
        -e "s+@REALRANKS@+$real_ranks+g" \
        -e "s+@REALNODES@+$real_nodes+g" \
        -e "s+@CELLS@+$cells+g" \
        -e "s+@NAME@+$name+g" \
        -e "s+@NODES@+$nodes+g" \
        -e "s+@DRYRUN@+$dryrun+g" \
        -e "s+@RUNPATH@+$runpath+g" \
        -e "s+@INPUT@+$input+g" \
        -e "s+@EXECPATH@+$execpath+g" \
        -e "s+@PARTITION@+$partition+g" \
        -e "s+@CPUSPERTASK@+$cpus_per_task+g" \
        -e "s+@RANKS@+$ranks+g" \
        <"$1" >"$2"
}

build-job() {
    local cells_per_ranks=$1; shift
    local nodes=$1; shift
    mkdir -p "$runpath"

    local cells=$(( cells_per_ranks * ranks ))

    if [[ $dryrun == true ]]; then
        local real_ranks=1
        local real_nodes=1
    else
        local real_ranks=$ranks
        local real_nodes=$nodes
    fi


    local name="run-$tag-$model-$config-$dryrun"

    echo "Building $runpath"
    do-sed $input.json.in "$runpath"/$input.json
    do-sed $input.sh.in "$runpath"/$input.sh

    # use sed to set number of cells in an input file
#    srun -n $ranks -c 40 <run> input.json > run_$cellspernode_$nodes
}

run-job() {
    echo "Batching $runpath"
    sbatch "$runpath"/$input.sh
}

over-nodes() {
    local cells_per_ranks=$1; shift
    local cell_output_path="$output_path/cells-$cells_per_rank"
    mkdir -p "$cell_output_path"

    local nodes
    for nodes in ${nodes_sets[@]}
    do
        local ranks=$(( ranks_per_node * nodes ))
        local runpath="$cell_output_path/ranks-$ranks"
        local input="run-$model-$config"

        $build_jobs && build-job $cells_per_rank $nodes
        $run_jobs && run-job
    done
}

over-cells() {
    local cells_per_rank
    for cells_per_rank in ${cells_per_rank_sets[@]}
    do
        over-nodes $cells_per_rank
    done
}

eval-cmdline "$@"
build-sets
over-cells
