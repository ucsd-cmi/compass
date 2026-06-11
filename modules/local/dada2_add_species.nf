process DADA2_ADD_SPECIES {
    tag "${classifier}"
    label 'process_high'

    conda "bioconda::bioconductor-dada2=1.38.0 conda-forge::r-base=4.5.2 conda-forge::r-digest=0.6.39"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community.wave.seqera.io/library/bioconductor-dada2_r-base_r-digest_tbb:38acac09bac46f36' :
        'quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0' }"

    input:
    path(asv_taxonomy)
    tuple val(meta), path(classifier)
    
    output:
    path("*${asv_taxonomy.baseName}.with_species.tsv"), emit: tsv
    path "versions.yml", emit: versions, topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages(library(dada2))

    set.seed($params.amplicon_random_seed)

    taxa_table <- readRDS(\"${asv_taxonomy}\")

    taxa_table_without_species <- taxa_table[,!colnames(taxa_table) %in% 'Species']

    taxa_species <- addSpecies(taxa_table_without_species, \"${classifier}\", $args)

    tmp_table <- data.frame(row.names(taxa_species))
    new_order <- c("asv_id", c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"))
    taxa_table_w_species <- as.data.frame(subset(taxa_species, select = new_order))
    taxa_table_w_species\$sequence <- tmp_table[,1]
    row.names(taxa_table_w_species) <- row.names(tmp_table)

    if("Species" %in% colnames(taxa_table)) {
        taxa_table <- data.frame(taxa_table)
        taxa_write <- data.frame(append(taxa_table_w_species, list(Species=taxa_table\$Species), after=match("Genus", names(taxa_table_w_species))))
    } else {
        taxa_write <- taxa_table_w_species
    }

    write.table(taxa_write, file = \"${asv_taxonomy.baseName}.with_species.tsv\", sep = "\\t", row.names = FALSE, col.names = TRUE, quote = FALSE, na = "")

    sink(file = "versions.yml")
    cat("\\"${task.process}\\":", "\\n")
    cat("    R:", as.character(getRversion()), "\\n")
    cat("    DADA2:", as.character(packageVersion("dada2")), "\\n")
    sink(file = NULL)
    """
}