process QIIME2_EXPORT_TAXONOMY_RELATIVE {
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(asv)
    path(taxonomy)
    val(collapse_to_levels)

    output:
    path("*.tsv"), emit: relative_abundance_tsvs
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    IFS=',' read -r -a collapse_to_levels <<< \"${collapse_to_levels}\"

    for TAXONOMIC_LEVEL in "\${collapse_to_levels[@]}"
    do
        qiime taxa collapse \\
            --i-table ${asv} \\
            --i-taxonomy ${taxonomy} \\
            --p-level \${TAXONOMIC_LEVEL} \\
            --o-collapsed-table collapsed_table_\${TAXONOMIC_LEVEL}.qza

        qiime feature-table relative-frequency \\
            --i-table collapsed_table_\${TAXONOMIC_LEVEL}.qza \\
            --o-relative-frequency-table collapsed_relative_frequency_table_\${TAXONOMIC_LEVEL}.qza

        qiime tools export \\
            --input-path collapsed_relative_frequency_table_\${TAXONOMIC_LEVEL}.qza \\
            --output-path collapsed_relative_frequency_table_\${TAXONOMIC_LEVEL}

        biom convert \\
            -i collapsed_relative_frequency_table_\${TAXONOMIC_LEVEL}/feature-table.biom \\
            -o collapsed_relative_frequency_table_\${TAXONOMIC_LEVEL}.tsv \\
            --to-tsv
    done
    """
}
