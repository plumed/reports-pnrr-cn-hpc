import plumed_bench_pp.constants as plmdbppconst
from plumed_bench_pp.plot import plot_lines
from plumed_bench_pp.tabulate import convert_to_table
from plumed_bench_pp.parser import parse_full_benchmark_output
import matplotlib.pyplot as plt
import re
import warnings

from matplotlib.axes import Axes


def plotAnalysis(
    benches: dict,
    *,
    numthreads: list,
    ax: Axes,
    plotSettings: "dict",
    inputlist: "str|re.Pattern",
):
    row_to_extract: "str" = plmdbppconst.TOTALTIME
    t = []
    for threads in numthreads:
        benchmarks = benches[threads]
        if len(benchmarks) == 0:
            warnings.warn(f'Problems with "{threads}"')
            continue
        for ker in benchmarks[0].settings.kernels:
            t.append(
                convert_to_table(
                    benchmarks,
                    kernel=ker,
                    rows_to_extract=[row_to_extract],
                    inputlist=inputlist,
                )
            )

    plot_lines(
        ax,
        t,
        row_to_extract,
        normalize_to_cycles=True,
        relative_to=None,
        **plotSettings,
    )


def loadMultiple_dcuda(
    mydir: str,
    *,
    nats: "list[int]|tuple[int]",
    numthreads,
):
    from os.path import isfile

    benches = {}
    for kind in ["line", "sc"]:
        cvkbench = {}
        for threads in numthreads:
            cvkbench[threads] = []

            for atoms in nats:
                myfile = f"{mydir}/threads{threads}/{kind}_{atoms}_{threads}.out"
                if not isfile(myfile):
                    # silently skipping
                    continue
                with open(myfile, "r") as f:
                    tmp = parse_full_benchmark_output(f.readlines())
                    cvkbench[threads].append(tmp)
        benches[kind] = cvkbench
    return benches


kinds = ["sc"]

nats = (
    100,
    1000,
    2000,
    4000,
    6000,
    8000,
    12000,
    16000,
    24000,
    32000,
    48000,
    64000,
    96000,
    128000,
)

fig, axes = plt.subplots(figsize=(10, 5))

dir_cpu = "./Aug08_13-11_cuda/cudacoord_cpu/"
myntrheads_cpu = [32, 16]
# myntrheads = mpi + mpi_omp + mpi_omps
benches_cpu = loadMultiple_dcuda(
    dir_cpu,
    nats=nats,
    numthreads=myntrheads_cpu,
)
for mytype, pkw in [
    (r"CPU", {"ls": "-"}),
]:
    inputlist = re.compile(mytype)
    plotAnalysis(
        benches_cpu[kinds[0]],
        numthreads=myntrheads_cpu,
        ax=axes,
        plotSettings={
            "equidistant_points": False,
            "plotkwargs": pkw,
            "titles": [f"CPU({omp} omp threads)" for omp in myntrheads_cpu],
        },
        inputlist=inputlist,
    )

dir = "./Aug08_13-11_cuda/cudacoord"
myntrheads = [32]
benches = loadMultiple_dcuda(
    dir,
    nats=nats,
    numthreads=myntrheads,
)
for mytype, legend, pkw in [
    (r"Cuda[0-9]", "Cuda, with double precision", {"ls": "-"}),
    (r"CudaFloat", "Cuda, with simple precision", {"ls": "-"}),
]:
    inputlist = re.compile(mytype)
    plotAnalysis(
        benches[kinds[0]],
        numthreads=myntrheads,
        ax=axes,
        plotSettings={
            "equidistant_points": False,
            "plotkwargs": pkw,
            "titles": [legend],
        },
        inputlist=inputlist,
    )

axes.set_ylabel("Total plumed time for 500 steps [s]")
axes.set_ylim(top=100)
axes.legend(ncols=2)
axes.set_title("Coordination among [x] atoms")
fig.savefig("cudaPNRR.png")
axes.set_ylim(auto=True)
axes.set_yscale("log")
axes.set_xscale("log")
fig.savefig("cudaPNRR_loglog.png")
