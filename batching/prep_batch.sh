#!/bin/bash

########################### Params
cells_per_node_sets=(1000 10000)
nodes_min=1
nodes_max=1024
node_scaling=2
config=small
model=ring
dryrun=true
tag=default
ranks_per_node=2
execpath=/p/project/cslns/exascale/nsuite/benchmarks/engines/busyring/arbor
partition=osws_tue_pm_large
cpus_per_task=48
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
    while $#; do
        eval $1
        shift
    done
    output_path="$(pwd)/batch-benchmarks/$tag/$model/$config/$dryrun"
    mkdir -p $output_path
}

do-sed() {
    sed -r \
        -e "s/@CELLS@/$cells/og" \
        -e "s/@NAME@/$name/og" \
        -e "s/@NODES@/$nodes/og" \
        -e "s/@DRYRUN@/$dryrun/og" \
        -e "s/@RUNPATH@/$runpath/og" \
        -e "s/@INPUT@/$input/og" \
        -e "s/@EXECPATH@/$execpath/og" \
        -e "s/@PARTITION@/$partition/og" \
        -e "s/@CPUSPERTASK@/$cpus_per_task/og" \
        <"$1" >"$2"
}

build-job() {
    local cells_per_node=$1; shift
    local nodes=$1; shift

    local cells=$(( cells_per_node * nodes ))
    local ranks=$(( ranks_per_node * nodes ))

    local input="run-$model-$config"
    local runpath="$output_path/ranks-$ranks"
    mkdir -p "$output"

    local name="run-$tag-$model-$config-$dryrun"

    do-sed $input.json.in "$runpath"/$input.json
    do-sed $input.sh.in "$runpath"/$input.sh

    # use sed to set number of cells in an input file
#    srun -n $ranks -c 40 <run> input.json > run_$cellspernode_$nodes
}

run-job() {
    local nodes=$1; shift
    local ranks=$(( ranks_per_node * nodes ))
    local runpath="$output_path/ranks-$ranks"

    sbatch "$runpath"/$input.sh
}

over-nodes() {
    local cells_per_node=$1; shift

    local nodes
    for nodes in ${node_sets}
    do
        build-job $cells_per_node $nodes
    done
}

over-cells() {
    local cells_per_node
    for cells_per_node in ${cells_per_node_sets[@]}
    do
        over-nodes $cells_per_node
    done
}

eval-cmdline "$@"
build-sets
over-cells
