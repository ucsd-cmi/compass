process DADA2_COMBINE {
    label 'process_low'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    path(rds_objects)

    output:
    path("full_asv_table.rds"), emit: dada2_asv_rds
    path("full_asv_table.tsv"), emit: dada2_asv_tsv
    path("full_asv_table_with_sequences.tsv"), emit: dada2_asv_tsv_with_sequences
    path("asv_sequences.fasta"), emit: asv_fasta
    path "versions.yml", emit: versions, topic: versions

    script:
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))
    suppressPackageStartupMessages(library(cli))

    asv_files <- sort(list.files(".", pattern = ".rds", full.names = TRUE))
    if(length(asv_files) == 1) {
        asv_table <- readRDS(asv_files[1])
    } else {
        asv_table <- mergeSequenceTables(tables = asv_files, repeats = "error", orderBy = "abundance", tryRC = FALSE)
    }
    saveRDS(asv_table, "full_asv_table.rds")

    df <- t(asv_table)
    colnames(df) <- gsub('_1.filtered.fastq.gz', '', colnames(df))
    colnames(df) <- gsub('.filtered.fastq.gz', '', colnames(df))
    df <- data.frame(sequence = rownames(df), df, check.names = FALSE)
    df\$asv_id <- hash_md5(df\$sequence)
    df <- df[,c(ncol(df),3:ncol(df)-1,1)]

    df <- df[order(df\$asv_id),]

    write.table(df, file = "full_asv_table_with_sequences.tsv", sep = "\\t", row.names = FALSE, na = "")
    write.table(data.frame(s = sprintf(">%s\n%s", df\$asv_id, df\$sequence)), "asv_sequences.fasta", col.names = FALSE, row.names = FALSE, quote = FALSE, na = "")

    df\$sequence <- NULL
    write.table(df, file = "full_asv_table.tsv", sep="\\t", row.names = FALSE, quote = FALSE, na = "")

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    cli:", as.character(packageVersion("cli")), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}
