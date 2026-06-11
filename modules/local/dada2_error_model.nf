process DADA2_ERROR_MODEL {
    tag "$meta.run_id"
    label 'process_medium'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.error_model.rds"), emit: error_model
    tuple val(meta), path("*.error_model.log"), emit: log
    tuple val(meta), path("*.error_model_mqc.png"), emit: multiqc_png
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.run_id}"
    if (!meta.single_end) {
        """
        #!/usr/bin/env Rscript

        suppressPackageStartupMessages(library(dada2))

        set.seed($params.amplicon_random_seed)

        filtered_forward_files <- list.files(".", pattern = "_1.filtered.fastq.gz", full.names = TRUE)
        filtered_reverse_files <- list.files(".", pattern = "_2.filtered.fastq.gz", full.names = TRUE)

        sink(file = "${prefix}.error_model.log")

        error_model_forward <- learnErrors(filtered_forward_files, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(error_model_forward, "${prefix}_1.error_model.rds")

        error_model_reverse <- learnErrors(filtered_reverse_files, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(error_model_reverse, "${prefix}_2.error_model.rds")

        sink(file = NULL)

        png("${prefix}_1.error_model_mqc.png")
        plotErrors(error_model_forward, nominalQ = TRUE)
        dev.off()

        png("${prefix}_2.error_model_mqc.png")
        plotErrors(error_model_reverse, nominalQ = TRUE)
        dev.off()

        sink(file = "versions.yml")
        cat("\\"${task.process}\\":", "\\n")
        cat("    R:", as.character(getRversion()), "\\n")
        cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
        sink(file = NULL)
        """
    } else {
        """
        #!/usr/bin/env Rscript

        suppressPackageStartupMessages(library(dada2))

        set.seed($params.amplicon_random_seed)

        filtered_forward_files <- list.files(".", pattern = ".filtered.fastq.gz", full.names = TRUE)

        sink(file = "${prefix}.error_model.log")

        error_model_forward <- learnErrors(filtered_forward_files, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(error_model_forward, "${prefix}.error_model.rds")

        sink(file = NULL)

        png("${prefix}.error_model_mqc.png")
        plotErrors(error_model_forward, nominalQ = TRUE)
        dev.off()

        sink(file = "versions.yml")
        cat("\\"${task.process}\\":", "\\n")
        cat("    R:", as.character(getRversion()), "\\n")
        cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
        sink(file = NULL)
        """
    }
}
