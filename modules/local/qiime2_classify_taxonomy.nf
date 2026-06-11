process QIIME2_CLASSIFY_TAXONOMY {
    tag "${classifier}"
    label "process_high"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(sequences)
    tuple val(meta), path(classifier)

    output:
    path("taxonomy.qza"), emit: qza
    path("taxonomy.tsv"), emit: tsv
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime feature-classifier classify-sklearn \\
        --i-classifier ${classifier} \\
        --i-reads ${sequences} \\
        --o-classification taxonomy.qza \\
        --p-n-jobs ${task.cpus} \\
        --verbose

    qiime metadata tabulate \\
        --m-input-file taxonomy.qza \\
        --o-visualization taxonomy.qzv \\
        --verbose

    qiime tools export \\
        --input-path taxonomy.qza \\
        --output-path taxonomy
    
    qiime tools export \\
        --input-path taxonomy.qzv \\
        --output-path taxonomy
    
    cp taxonomy/taxonomy.tsv ./taxonomy.tsv
    """
}
