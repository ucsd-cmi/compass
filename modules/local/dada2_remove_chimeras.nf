process DADA2_REMOVE_CHIMERAS {
    tag "$meta.run_id"
    label 'process_medium'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(sequence_table)

    output:
    tuple val(meta), path("*.asv_table.rds"), emit: asv_table
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.run_id}"
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))

    sequence_table = readRDS("${sequence_table}")

    sequence_table.no_chimeras <- removeBimeraDenovo(sequence_table, $args, multithread=$task.cpus)
    saveRDS(sequence_table.no_chimeras, "${prefix}.asv_table.rds")

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}
