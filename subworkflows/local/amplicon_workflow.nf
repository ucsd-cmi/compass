/*
    The side of COMPASS to process amplicon samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC } from '../../modules/nf-core/fastqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { AMPLICON_PREPROCESSING            } from './amplicon_preprocessing'
include { AMPLICON_ASV_INFERENCE            } from './amplicon_asv_inference'
include { AMPLICON_TAXONOMIC_CLASSIFICATION } from './amplicon_taxonomic_classification'
include { AMPLICON_PHYLOGENETIC_PLACEMENT   } from './amplicon_phylogenetic_placement'
include { AMPLICON_ANALYSIS                 } from './amplicon_analysis'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow AMPLICON_WORKFLOW {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_ref_databases // channel: reference databases read in from --ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Run FastQC
    */
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    /*
        SUBWORKFLOW: Preprocessing
    */
    AMPLICON_PREPROCESSING (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(AMPLICON_PREPROCESSING.out.multiqc_output.collect{it[1]})
    ch_versions = ch_versions.mix(AMPLICON_PREPROCESSING.out.versions)

    /*
        SUBWORKFLOW: ASV inference
    */
    AMPLICON_ASV_INFERENCE (
        AMPLICON_PREPROCESSING.out.reads
    )
    ch_asv_tsv = AMPLICON_ASV_INFERENCE.out.ch_asv_tsv
    ch_asv_fasta = AMPLICON_ASV_INFERENCE.out.ch_asv_fasta

    /*
        SUBWORKFLOW: Taxonomic classification
    */
    AMPLICON_TAXONOMIC_CLASSIFICATION (
        ch_asv_fasta,
        ch_ref_databases
    )
    ch_dada2_taxonomy_tsv = AMPLICON_TAXONOMIC_CLASSIFICATION.out.dada2_taxonomy_tsv
    ch_qiime2_taxonomy_qza = AMPLICON_TAXONOMIC_CLASSIFICATION.out.qiime2_taxonomy_qza

    /*
        SUBWORKFLOW: Phylogenetic placement
    */
    if (params.amplicon_do_phylogenetic_placement) {
        AMPLICON_PHYLOGENETIC_PLACEMENT (
            ch_asv_tsv,
            ch_asv_fasta,
            ch_ref_databases
        )
        ch_sepp_phylogenetic_tree = AMPLICON_PHYLOGENETIC_PLACEMENT.out.tree
    } else {
        ch_sepp_phylogenetic_tree = channel.empty()
    }

    /*
        SUBWORKFLOW: Downstream analysis
    */
    if (params.amplicon_taxonomy_for_analysis != "") {
        AMPLICON_ANALYSIS (
            ch_asv_tsv,
            ch_asv_fasta,
            ch_dada2_taxonomy_tsv,
            ch_qiime2_taxonomy_qza,
            ch_sepp_phylogenetic_tree
        )
    }

    emit:
    versions        = ch_versions
    multiqc_output  = ch_multiqc_files
}
