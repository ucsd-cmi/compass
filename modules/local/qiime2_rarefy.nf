process QIIME2_RAREFY {
    label "process_low"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(feature_table)

    output:
    path("feature_table_rarefied.qza"), emit: feature_table
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime feature-table rarefy \\
        --i-table ${feature_table} \\
        --p-sampling-depth ${params.amplicon_rarefaction_minimum_sample_depth} \\
        --o-rarefied-table feature_table_rarefied.qza \\
        --p-no-with-replacement
    """
}
