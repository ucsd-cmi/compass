process QIIME2_BETA_DIVERSITY {
    tag "${metric_list}"
    label "process_high"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(feature_table)
    path(tree)
    val(metric_list)
    val(beta_type)

    output:
    path("*"), emit: output_files
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    IFS=',' read -r -a metric_list <<< \"${metric_list}\"

    for METRIC in "\${metric_list[@]}"
    do
        if [ \"${beta_type}\" == \"phylogenetic\" ]; then
            qiime diversity beta-phylogenetic \\
                --i-table ${feature_table} \\
                --i-phylogeny ${tree} \\
                --p-threads ${task.cpus} \\
                --p-metric \${METRIC} \\
                --p-bypass-tips \\
                --o-distance-matrix \${METRIC}.qza
        else
            qiime diversity beta \\
                --i-table ${feature_table} \\
                --p-metric \${METRIC} \\
                --o-distance-matrix \${METRIC}.qza
        fi

        qiime tools export \\
            --input-path \${METRIC}.qza \\
            --output-path \${METRIC}_export

        cp \${METRIC}_export/distance-matrix.tsv ./\${METRIC}.tsv
    done
    """
}
