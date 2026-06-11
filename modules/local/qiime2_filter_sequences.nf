process QIIME2_FILTER_SEQUENCES {
    tag "filter_sequences"
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(representative_sequences)
    path(feature_table)

    output:
    path("filtered_sequences.qza"), emit: sequences_qza
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime feature-table filter-seqs \\
        --i-data ${representative_sequences} \\
        --i-table ${feature_table} \\
        --o-filtered-data filtered_sequences.qza
    """
}
