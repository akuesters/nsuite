#!/bin/bash

#set -x -v

##################################################
# ./pre_batch.sh build|run|table [param1=val1]*
##################################################

######### Mode
# build | run | table
# flags for building or running jobs: choices (:/false)
mode=

# build:
# clean up before running
clean=false

########################### Params

cells_per_rank_sets=(1000 10000)
nodes_min=1
nodes_max=2048
nodes_scaling=2

config=small
model=ring
dryrun=true
tag=default

ranks_per_node=2
cpus_per_task=24
timelimit=2:30:00

toppath=$(readlink -f "$(pwd)"/..)
execpath="$toppath"/benchmarks/engines/busyring/arbor
partition=osws_wed_am_large

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

cmdline/build() {
    $clean && rm -rf $output_path
    mkdir -p $output_path
}

cmdline/run() {
    :
}

cmdline/table() {
    :
}

eval-cmdline() {
    mode=$1; shift
    while (($# > 0)); do
        eval $1
        shift
    done
    
    output_path="$toppath"/batching/batch-benchmarks/$tag/$model/$config/$dryrun
    
    cmdline/$mode # setup for mode
}

do-sed() {
    echo "Processing $1"
    sed -r \
        -e "s+@TIMELIMIT@+$timelimit+g" \
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

job/build() {
    mkdir -p "$runpath"

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
}

job/run() {
    echo "Batching $runpath"
    sbatch "$runpath"/$input.sh
}

job/table() {
    table_line "$runpath"/run.out $cells $ranks \
               >>"$output_path/table.txt"
}

over-nodes() {
    local cells_per_ranks=$1; shift
    local cell_output_path="$output_path/cells-$cells_per_rank"
    mkdir -p "$cell_output_path"

    local nodes
    for nodes in ${nodes_sets[@]}
    do
        local ranks=$(( ranks_per_node  * nodes ))
        local cells=$(( cells_per_ranks * ranks ))
        local runpath="$cell_output_path/ranks-$ranks"
        local input="run-$model-$config"

        job/$mode
    done
}

over-cells() {
    local cells_per_rank
    for cells_per_rank in ${cells_per_rank_sets[@]}
    do
        over-nodes $cells_per_rank
    done
}

##### processing output ######
table_line() {
    local fid="$1"; shift
    
    if [ ! -f "$fid" ]; then
        echo "ERROR: the benchmark output file \"$fid\" does not exist."
    else
        printf "%7d%7d%7d%7d" $tag $model $config $dryrun
        
        printf "%7d%7d" $cells $ranks   

        local tts=`awk '/^model-run/ {print $2}' $fid`
        local ncell=`awk '/^cell stats/ {print $3}' $fid`
        local ncomp=`awk '/^cell stats/ {print $7}' $fid`
        local cell_rate=`echo "$ncell/$tts" | bc -l`

        printf "%7d%12d%12.3f%12.1f" $ncell $ncomp $tts $cell_rate

        local mempos=`awk '/^meter / {j=-1; for(i=1; i<=NF; ++i) if($i =="memory(MB)") j=i; print j}' $fid`
        nranks=`awk '/^ranks:/ {print $2}' $fid`
        if [ "$mempos" != "-1" ]
        then
            local rankmem=$(awk "/^meter-total/ {print \$$mempos}" $fid)
            local totalmem=`echo $rankmem*$nranks | bc -l`
            local cellmem=`echo $totalmem/$ncell | bc -l`
            printf "%12.3f%12.3f" $totalmem $cellmem
        else
            printf "%12s%12s" '-' '-'
        fi

        printf "\n"
    fi
}

table() {
    echo "  tag model config dryrun cells ranks cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)"
# over_cells
# over_nodes   
#    table_line $ofile $cells $ranks
}

eval-cmdline "$@"
build-sets
over-cells
