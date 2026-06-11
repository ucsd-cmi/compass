process QIIME2_BARPLOT_TAXONOMY {
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(asv)
    path(taxonomy)

    output:
    path("barplot/*"), emit: barplot_folder
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime taxa barplot \\
        --i-table ${asv} \\
        --i-taxonomy ${taxonomy} \\
        --o-visualization taxonomy_barplot.qzv \\
        --verbose

    qiime tools export \\
        --input-path taxonomy_barplot.qzv \\
        --output-path barplot
    """
}
