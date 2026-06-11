process QIIME2_FILTER_TAXA {
    tag "filter_taxa"
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(feature_table)
    path(taxonomy)

    output:
    path("filtered_feature_table.qza"), emit: asv_qza
    path("filtered_feature_table.tsv"), emit: tax_tsv
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    if ! [ \"${params.amplicon_taxa_to_exclude}\" = \"\" ]; then
        qiime taxa filter-table \\
            --i-table ${feature_table} \\
            --i-taxonomy ${taxonomy} \\
            --o-filtered-table "feature_table_taxa_filtered.qza" \\
            --p-mode contains \\
            --p-exclude "${params.amplicon_taxa_to_exclude}"
        
        taxa_filtered_table = "feature_table_taxa_filtered.qza"
    else
        taxa_filtered_table=${feature_table}
    fi

    qiime feature-table filter-features \\
        --i-table \$taxa_filtered_table \\
        --o-filtered-table filtered_feature_table.qza \\
        --p-min-frequency ${params.amplicon_minimum_abundance} \\
        --p-min-samples ${params.amplicon_minimum_prevalence}

    qiime tools export \\
        --input-path filtered_feature_table.qza \\
        --output-path feature_table

    biom convert \\
        -i feature_table/feature-table.biom \\
        -o feature_table/filtered_feature_table.tsv \\
        --to-tsv

    cp feature_table/filtered_feature_table.tsv ./filtered_feature_table.tsv
    """
}
