process QIIME2_EXPORT_SEQUENCES_RELATIVE {
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(asv_table)

    output:
    path("asv_relative_abundance.tsv"), emit: asv_relative_abundance
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime feature-table relative-frequency \\
        --i-table ${asv_table} \\
        --o-relative-frequency-table relative_frequency_table.qza

    qiime tools export \\
        --input-path relative_frequency_table.qza \\
        --output-path relative_frequency_table

    biom convert \\
        -i relative_frequency_table/feature-table.biom \\
        -o asv_relative_abundance.tsv \\
        --to-tsv
    """
}
