process QIIME2_SEPP {
    tag "${sequences},${reference}"
    label "process_high"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(sequences)
    tuple val(meta), path(reference)
    path(feature_table)

    output:
    path("tree.qza"), emit: tree
    path("placements.qza"), emit: placements
    path("filtered_table.qza"), emit: feature_table
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime fragment-insertion sepp \\
        --i-representative-sequences ${sequences} \\
        --i-reference-database ${reference} \\
        --o-tree tree.qza \\
        --o-placements placements.qza \\
        --p-threads ${task.cpus}

    qiime fragment-insertion filter-features \\
        --i-table ${feature_table} \\
        --i-tree tree.qza \\
        --o-filtered-table filtered_table.qza \\
        --o-removed-table filtered_fragments.qza
    """
}
