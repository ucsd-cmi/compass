process QIIME2_IMPORT_TAXONOMY {
    tag "${taxonomy}"
    label "process_single"

    conda "https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.1/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml"
    container "quay.io/qiime2/amplicon:2026.1"

    input:
    path(taxonomy)

    output:
    path("taxonomy.qza"), emit: qza
    tuple val("${task.process}"), val('QIIME 2'), eval("qiime --version | sed '1!d;s/.* //'"), emit: versions_qiime2, topic: versions

    script:
    """
    # qiime2 script boilerplate
    export MPLCONFIGDIR="./local_scratch/mplconfigdir"
    export NUMBA_CACHE_DIR="./local_scratch/numbacachedir"
    export XDG_CONFIG_HOME="./local_scratch/xdgconfighome"

    qiime tools import \\
        --input-path "$taxonomy" \\
        --type 'FeatureData[Taxonomy]' \\
        --input-format HeaderlessTSVTaxonomyFormat \\
        --output-path taxonomy.qza
    """
}
