process CALCULATE_TRUNCLEN {
    tag "$meta"
    label 'process_medium'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(reads)
    val quality_threshold

    output:
    tuple val(meta), stdout, emit: truncate_values
    path "versions.yml", emit: versions, topic: versions

    script:
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(ShortRead))

    read_files <- sort(list.files(".", pattern = ".fastq.gz", full.names = TRUE))

    quality_stats <- qa(read_files, n=500000)
    df <- quality_stats[["perCycle"]]\$quality

    avg_qualities <- rowsum(df\$Score * df\$Count, df\$Cycle) / rowsum(df\$Count, df\$Cycle)

    truncation_point <- min(which(avg_qualities < $quality_threshold)) - 1

    if (is.infinite(truncation_point)) {
        truncation_point = length(avg_qualities) - 1
    }

    cat(truncation_point)

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    ShortRead:", as.character(packageVersion("ShortRead")), "\\n")
    sink(file = NULL)
    """
}
