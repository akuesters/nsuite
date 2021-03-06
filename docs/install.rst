.. _install:

Installing NSuite
================================

The first stage of the NSuite workflow is to install the simulation engine(s) to benchmark or validate.
This page describes how to obtain NSuite, then perform this step so that benchmarks and validation tests can be run.

Obtaining NSuite
--------------------------------

Before installing, first get a copy of NSuite.
The simplest way to do this is to clone the repository using git:

.. container:: example-code

    .. code-block:: bash

        git clone https://github.com/arbor-sim/nsuite.git
        cd nsuite
        git checkout v1.0

Above ``git checkout`` is used to pick a tagged version of NSuite. If not called
the latest development version in the master branch will be used.

**TODO** guide on how to download zipped/tarred version from tags.

Installing Simulation Engines
--------------------------------

NSuite provides a script ``install-local.sh`` that performs the role of

* Obtaining the source code for simulation engines.
* Compiling and installing simulation engines.
* Compiling and installing benchmark and validation test drivers.
* Generating input data sets for validation tests.

Basic usage of ``install-local.sh`` is best illustrated with some examples:

.. container:: example-code

    .. code-block:: bash

        # download and install Arbor
        ./install-local.sh arbor

        # download and install NEURON and CoreNEURON
        ./install-local.sh neuron coreneuron

        # download install all three of Arbor, NEURON and CoreNEURON
        ./install-local.sh all

        # download install NEURON in relative path install
        ./install-local.sh neuron --prefix=install

        # download install NEURON in relative path that includes time stamp
        # e.g. install-2019-03-22
        ./install-local.sh neuron --prefix=install-$(date +%F)

        # download install NEURON in absolute path
        ./install-local.sh neuron --prefix=/home/uname/install

The simulation engines to install are provided as arguments.
Further options for installing the simulation engines in a user-specified path and customising
the build environment can be provided:

====================  =================     ======================================================
Flag                  Default value         Explanation
====================  =================     ======================================================
simulator             none                  Which simulation engines to download and install.
                                            Any number of the following: {``arbor``, ``neuron``, ``coreneuron``, ``all``}.
``--prefix``          current path          Path for downloading, compiling, installing simulation engines.
                                            Also used to store inputs and outputs from benchmarks and validation tests.
                                            Can be either a relative or absolute path.
``--env``             none                  Optional script for configuring the environment and build steps.
                                            See :ref:`customenv`.
====================  =================     ======================================================

.. _customenv:

Directory Structure
""""""""""""""""""""""""""""""""

The following directory structure will be generated when ``install-local.sh`` is run:

.. code-block:: none

    prefix
    ├── build
    │   ├── arbor
    │   ├── coreneuron
    │   ├── neuron
    │   └── ...
    ├── install
    │   ├── bin
    │   ├── include
    │   ├── lib
    │   └── share
    ├── config
    ├── input
    │   └── benchmarks
    ├── output
    │   ├── benchmarks
    │   └── validation
    └── cache

If no prefix is provided, the directory structure is created in the nsuite path.
The contents of each sub-directory are summarised:

====================  ======================================================
``build```            Source code for simulation engines is checked out, and compiled here.
``install```          Installation target for the simulation engine libraries, executables, headers, etc.
``config```           The environment used to build each simulation engine is stored here, to load per-simulator when running benchmarks and validation tests.
``cache```            Validation data sets are stored here when generated during the installation phase.
``input```            **generated by running benchmarks** Input files for benchmark runs in sub-directories for each benchmark configuration.
``output```           **generated by running benchmarks/validation** Benchmark and validation outputs in sub-directories for each benchmark/validation configuration.
====================  ======================================================

Customizing the environment
""""""""""""""""""""""""""""""""

NSuite attempts to detect features of the environment that will influence how simulation engines are
compiled and run, including compilers, MPI support and CPU core counts.
HPC systems have multiple compilers, MPI implementations and hardware resources available, which
are typically configured using modules.
It isn't possible for NSuite to detect which options to choose on such systems, so
user can customise the compilation and execution of simulation engines.
To do this, a user provides an *environment configuration script* that will sourced
after NSuite has performed automatic environment detection and configuration.

The script is specified  with the ``--env`` flag:

.. container:: example-code

    .. code-block:: bash

        ./install-local arbor  --env=arbor-config.sh
        ./install-local neuron --env=neuron-config.sh

In the example above, different configurations are used for Arbor and NEURON.
This can be used, for example, to choose compilers that produce optimal
results on each respective simulator, or when different simulators require
different versions of a library.

Examples of scripts for two HPC systems,
`Piz Daint <https://www.cscs.ch/computers/dismissed/piz-daint-piz-dora/>`_ and `JUWELS <http://www.fz-juelich.de/ias/jsc/EN/Expertise/Supercomputers/JUWELS/JUWELS_news.html>`_,
can be found in the ``scripts`` sub-directory in NSuite.

General Variables
````````````````````````````````

The following variables are universal to all of the simulation engines.

========================  ==================================    ======================================================
Variable                  Default value                         Explanation
========================  ==================================    ======================================================
``ns_cc``                 ``mpicc`` if available, else          The C compiler for compiling simulation engines.
                          ``gcc``/``clang`` on Linux/OS X
``ns_cxx``                ``mpicxx`` if available, else         The C++ compiler for compiling simulation engines.
                          ``g++``/``clang++`` on Linux/OS X
``ns_with_mpi``           ``ON`` iff MPI is detectedl           ``ON``/``OFF`` to compile simulation engines with MPI enabled.
                                                                Also controls whether mpirun is used to launch benchmarks.
``ns_makej``              4                                     Number of parallel jobs to use when compiling.
``ns_python``             ``which python3``                     The Python interpreter to use. Must be Python 3.
``ns_threads_per_core``   automatic                             The number of threads per core for parallel benchmarks.
``ns_cores_per_socket``   automatic                             The number of cores per socket for parallel benchmarks.
``ns_sockets``            1                                     The number of sockets for parallel benchmarks. One MPI rank is used per socket if MPI support is enabled.
``run_with_mpi``          Bash function for OpenMPI             A bash function for launching an executable and flags with multithreading and optionally MPI,
                                                                based on the ``ns_threads_per_core``, ``ns_cores_per_socket``, ``ns_sockets`` variables.
========================  ==================================    ======================================================

Simulator-Specific Variables
````````````````````````````````

There are Arbor-specific options for checking out Arbor from a Git repository, and for configuring target-specific optimizations.

========================  ===========================================   ======================================================
Variable                  Default value                                 Explanation
========================  ===========================================   ======================================================
``ns_arb_git_repo``       ``https://github.com/arbor-sim/arbor.git``    URL or directory for the Git repository to check out Arbor source from.
``ns_arb_branch``         ``v0.2``                                      The branch/tag/SHA to check out. Master will be used if empty.
``ns_arb_arch``           ``native``                                    `The CPU architecture target <https://arbor.readthedocs.io/en/latest/install.html#architecture>`_
                                                                        for Arbor. Must be set when cross compiling.
                                                                        Default ``native`` targets the architecture used to configure NSuite.
``ns_arb_with_gpu``       ``OFF``                                       Whether to build Arbor with NVIDIA GPU support.
``ns_arb_vectorize``      ``ON``                                        Whether to use explicit vectorization for Arbor.
========================  ===========================================   ======================================================

The NEURON-specific options are for configuring where to get NEURON's source from.
NEURON can be dowloaded from a tar ball for a specific version, or cloned from a Git repository.

The official versions of NEURON's source code available to download are inconsistently packaged, so it
is not possible to automatically determine how to download and install from a version string alone, e.g. "7.6.2".
This is why three variables must be set if downloading a NEURON tarball.

========================  ===========================================   ======================================================
Variable                  Default value                                 Explanation
========================  ===========================================   ======================================================
``ns_nrn_tarball``        ``nrn-7.6.5.tar.gz``                          The name of the tar ball file (caution: not named consistently between versions).
``ns_nrn_url``            ``https://neuron.yale.edu/ftp/neuron/``       The URL of the tar ball (caution: not name consistently between versions).
                          ``versions/v7.6/7.6.5/${ns_nrn_tarball}``
``ns_nrn_path``           ``nrn-7.6``                                   The name of the path after expanding the tar ball (caution: not name consistently between versions).
``ns_nrn_git_repo``       empty                                         URL or path of Git repository. If set it will be used instead of downloading a tarball.
``ns_nrn_branch``         ``master``                                    Branch or commit SHA to use if sourcing from Git.
========================  ===========================================   ======================================================

CoreNEURON has more support than NEURON for targeting different hardware, either via automatic vectorization, or using OpenACC for GPUs.
However, it is quite difficult to build, particularly as part of an automated pipeline: users have to directly provide architecture- and compiler-specific flags to CMake.
As soon as we are able to build CoreNEURON this way ourselves, we will add more flags for targeting different architectures.

========================  ===============================================   ======================================================
Variable                  Default value                                     Explanation
========================  ===============================================   ======================================================
``ns_cnrn_git_repo``      ``https://github.com/BlueBrain/CoreNeuron.git``   URL or path of Git repository.
``ns_cnrn_sha``           ``0.14``                                          Branch, tag or commit SHA of Git repository.
========================  ===============================================   ======================================================

Example custom environment
````````````````````````````````

Below is a custom configuration script for a Cray cluster with Intel KNL processors.
It configures all platform-specific details that can't be automatically detected by

* loading and swaping required modules;
* setting a platform-specific magic variable ``CRAYPE_LINK_TYPE`` required to make CMake play nice;
* configuring MPI with the Cray MPI wrapper;
* configuring Arbor to compile with KNL support;
* configuring the number of threads and MPI ranks with which to run benchmarks.


.. container:: example-code

    .. code-block:: bash

        # set up Cray Programming environmnet to use GNU toolchain
        [ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu

        # load python, gcc version and CMake
        module load cray-python/3.6.5.1
        module swap gcc/7.3.0   # load after cray-python
        module load CMake

        # set for CMake to correctly configure Arbor and CoreNEURON
        export CRAYPE_LINK_TYPE=dynamic

        # Python, MPI and build options for this system
        ns_python=$(which python3)
        ns_cc=$(which cc)
        ns_cxx=$(which CC)
        ns_with_mpi=ON
        ns_makej=20

        # simulator-specific options
        ns_arb_arch=knl

        # cluster-specific options
        ns_threads_per_core=1
        ns_cores_per_socket=64
        ns_sockets=1
        ns_threads_per_socket=64

        run_with_mpi() {
            # this system uses Slurm's srun to launch MPI jobs on compute nodes
            srun -n $ns_sockets -c $ns_threads_per_socket $*
        }

