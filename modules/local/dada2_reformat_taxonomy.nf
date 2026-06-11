process DADA2_REFORMAT_TAXONOMY {
    tag "${tsv}"
    label 'process_single'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    path(tsv)

    output:
    path("taxonomy.tsv"), emit: tsv
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env Rscript

    taxa <- read.table(file = '$tsv', header = TRUE, sep = "\\t", stringsAsFactors = FALSE, comment.char = "", quote = "")
    ranks <- colnames(taxa)[!colnames(taxa) %in% c('asv_id', 'sequence')]
    taxa\$taxonomy <- do.call(paste, c(taxa[ranks], sep = ';'))
    write.table(taxa[,c('asv_id', 'taxonomy')], file = 'taxonomy.tsv', quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\\t")

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    sink(file = NULL)
    """
}
