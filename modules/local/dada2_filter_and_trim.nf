process DADA2_FILTER_AND_TRIM {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(reads), val(truncate_value_forward), val(truncate_value_reverse)

    output:
    tuple val(meta), path("*.filtered.fastq.gz"), emit: filtered_reads
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_and_output = meta.single_end ? "\"${reads}\", \"${prefix}.filtered.fastq.gz\"" : "\"${reads[0]}\", \"${prefix}_1.filtered.fastq.gz\", \"${reads[1]}\", \"${prefix}_2.filtered.fastq.gz\""
    def output = meta.single_end ? "\"${prefix}.filtered.fastq.gz\"" : "\"${prefix}_1.filtered.fastq.gz\", \"${prefix}_2.filtered.fastq.gz\""
    def truncate_forward = truncate_value_forward[1].toInteger()
    def truncate_reverse = truncate_value_reverse[1].toInteger()
    def truncate_arguments = meta.single_end ? "truncLen = ${truncate_forward}" : "truncLen = c(${truncate_forward}, ${truncate_reverse})"
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))

    filtered_output <- filterAndTrim($input_and_output, $truncate_arguments, $args, multithread = $task.cpus)

    filtered_output <- cbind(filtered_output, ID = row.names(filtered_output))

    # If no reads remain after filtering and trimming, create empty FASTQ file(s)
    if(filtered_output[2] == '0') {
        for(file_name in c($output)) {
            file_handle <- gzfile(file_name, "w")
            write("", file_handle)
            close(file_handle)
        }
    }

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}
