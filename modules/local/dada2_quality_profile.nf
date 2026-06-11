process DADA2_QUALITY_PROFILE {
    tag "${meta}"
    label 'process_low'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.quality_stats_mqc.png"), emit: multiqc_png
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))

    read_files <- sort(list.files(".", pattern = ".fastq.gz", full.names = TRUE))

    quality_plot <- plotQualityProfile(read_files, $args)
    
    png("${prefix}.quality_stats_mqc.png")
    quality_plot
    dev.off()

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}