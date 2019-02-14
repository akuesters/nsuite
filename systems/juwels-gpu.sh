### environment ###

# set up environment for building on the multicore part of daint

module load CMake/3.13.0

module load GCC/7.3.0 
module load CUDA/9.2.88 
module load MVAPICH2/2.3-GDR

module load Python/3.6.6
ns_python=$(which python3)

# mpi4py only needed for NEURON, CUDA only works with gcc7 (would require Intel compiler and Cuda-unaware MPI version)
#module load mpi4py/3.0.0-Python-3.6.6
### compilation options ###

ns_cc=$(which mpicc)
ns_cxx=$(which mpicxx)
ns_with_mpi=ON

ns_arb_with_gpu=ON
ns_arb_arch=skylake

ns_makej=20

### benchmark execution options ###

ns_threads_per_core=2
ns_cores_per_socket=20
ns_sockets=1
ns_threads_per_socket=40

# activate budget via jutil env activate -p <cproject> -A <budget> before running the benchmark
run_with_mpi() {
    echo ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket $*
    ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket $*
}
