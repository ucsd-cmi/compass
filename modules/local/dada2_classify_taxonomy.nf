process DADA2_CLASSIFY_TAXONOMY {
    tag "${classifier}"
    label 'process_high'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    path(fasta)
    tuple val(meta), path(classifier)

    output:
    path("${fasta.baseName}.taxonomic_output.tsv"), emit: tsv
    path("${fasta.baseName}.taxonomic_output.rds"), emit: rds
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))

    set.seed($params.amplicon_random_seed)

    sequences <- getSequences(\"${fasta}\", collapse = TRUE, silence = FALSE)
    taxa <- assignTaxonomy(sequences, \"${classifier}\", taxLevels = c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), $args, multithread = $task.cpus)

    taxa_df <- data.frame(asv_id = names(sequences), taxa, sequence = row.names(taxa), row.names = names(sequences))
    write.table(taxa_df, file = \"${fasta.baseName}.taxonomic_output.tsv\", sep = "\\t", row.names = FALSE, col.names = TRUE, quote = FALSE, na = "")

    taxa_write <- cbind(asv_id = taxa_df\$asv_id, taxa)
    saveRDS(taxa_write, "${fasta.baseName}.taxonomic_output.rds")

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}
