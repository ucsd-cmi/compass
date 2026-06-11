process QIIME2_EXPORT_SEQUENCES_ABSOLUTE {
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(feature_table)
    path(sequences)

    output:
    path("feature_table.tsv"), emit: feature_table_tsv
    path("feature_table.biom"), emit: feature_table_biom
    path("representative_sequences.fasta"), emit: representative_sequences
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime tools export \\
        --input-path ${feature_table} \\
        --output-path table
    cp table/feature-table.biom ./feature_table.biom

    biom convert \\
        -i feature_table.biom \\
        -o feature_table.tsv \\
        --to-tsv

    qiime feature-table tabulate-seqs \\
        --i-data ${sequences} \\
        --o-visualization representative_sequences.qzv

    qiime tools export \\
        --input-path representative_sequences.qzv \\
        --output-path representative_sequences

    cp representative_sequences/sequences.fasta representative_sequences.fasta
    cp representative_sequences/*.tsv .
    """
}
