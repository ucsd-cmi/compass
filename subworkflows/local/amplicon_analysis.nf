/*
    Perform analysis for amplicon samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { QIIME2_IMPORT_ASV                                             } from '../../modules/local/qiime2_import_asv'
include { QIIME2_IMPORT_SEQUENCES                                       } from '../../modules/local/qiime2_import_sequences'
include { DADA2_REFORMAT_TAXONOMY                                       } from '../../modules/local/dada2_reformat_taxonomy'
include { QIIME2_IMPORT_TAXONOMY                                        } from '../../modules/local/qiime2_import_taxonomy'
include { QIIME2_FILTER_TAXA                                            } from '../../modules/local/qiime2_filter_taxa'
include { QIIME2_FILTER_SEQUENCES                                       } from '../../modules/local/qiime2_filter_sequences'
include { QIIME2_EXPORT_TAXONOMY_ABSOLUTE                               } from '../../modules/local/qiime2_export_taxonomy_absolute'
include { QIIME2_EXPORT_SEQUENCES_ABSOLUTE                              } from '../../modules/local/qiime2_export_sequences_absolute'
include { QIIME2_EXPORT_SEQUENCES_RELATIVE                              } from '../../modules/local/qiime2_export_sequences_relative'
include { QIIME2_EXPORT_TAXONOMY_RELATIVE                               } from '../../modules/local/qiime2_export_taxonomy_relative'
include { QIIME2_BARPLOT_TAXONOMY                                       } from '../../modules/local/qiime2_barplot_taxonomy'
include { QIIME2_RAREFY                                                 } from '../../modules/local/qiime2_rarefy'
include { QIIME2_ALPHA_DIVERSITY                                        } from '../../modules/local/qiime2_alpha_diversity'
include { QIIME2_ALPHA_DIVERSITY as QIIME2_ALPHA_DIVERSITY_PHYLOGENETIC } from '../../modules/local/qiime2_alpha_diversity'
include { QIIME2_BETA_DIVERSITY                                         } from '../../modules/local/qiime2_beta_diversity'
include { QIIME2_BETA_DIVERSITY as QIIME2_BETA_DIVERSITY_PHYLOGENETIC   } from '../../modules/local/qiime2_beta_diversity'

workflow AMPLICON_ANALYSIS {
    take:
    ch_asv_tsv
    ch_asv_fasta
    ch_dada2_taxonomy_tsv
    ch_qiime2_taxonomy_qza
    ch_phylogenetic_tree

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Import asv table to .qza file for QIIME 2
    */
    QIIME2_IMPORT_ASV (
        ch_asv_tsv
    )
    ch_qiime2_asv = QIIME2_IMPORT_ASV.out.qza

    /*
        MODULE: Import sequences to .qza file for QIIME 2
    */
    QIIME2_IMPORT_SEQUENCES (
        ch_asv_fasta
    )
    ch_sequences_qza = QIIME2_IMPORT_SEQUENCES.out.qza

    if (params.amplicon_do_taxonomic_classification_dada2) {
        /*
            MODULE: Reformat DADA2's taxonomic output for import into QIIME 2
        */
        DADA2_REFORMAT_TAXONOMY (
            ch_dada2_taxonomy_tsv
        )

        /*
            MODULE: Import DADA2's taxonomic into a .qza file for QIIME 2
        */
        QIIME2_IMPORT_TAXONOMY (
            DADA2_REFORMAT_TAXONOMY.out.tsv
        )
        ch_dada2_taxonomy_qza = QIIME2_IMPORT_TAXONOMY.out.qza
    } else {
        ch_dada2_taxonomy_qza = channel.empty()
    }

    if (params.amplicon_taxonomy_for_analysis == "qiime2") {
        ch_analysis_taxonomy_qza = ch_qiime2_taxonomy_qza
    } else {
        ch_analysis_taxonomy_qza = ch_dada2_taxonomy_qza
    }

    if (params.amplicon_taxa_to_exclude || params.amplicon_minimum_abundance > 1 || params.amplicon_minimum_prevalence > 1) {
        /*
            MODULE: Filter taxa via QIIME2
        */
        QIIME2_FILTER_TAXA (
            ch_qiime2_asv,
            ch_analysis_taxonomy_qza
        )

        /*
            MODULE: Filter sequences based on the output of filtering taxa
        */
        QIIME2_FILTER_SEQUENCES (
            ch_sequences_qza,
            QIIME2_FILTER_TAXA.out.asv_qza,
        )
        ch_feature_table_filtered = QIIME2_FILTER_TAXA.out.asv_qza
        ch_sequences_filtered = QIIME2_FILTER_SEQUENCES.out.sequences_qza
    } else {
        ch_feature_table_filtered = ch_qiime2_asv
        ch_sequences_filtered = ch_sequences_qza
    }

    /*
        MODULE: Export absolute abundance table of sequences
    */
    if (params.amplicon_do_export_sequences_absolute) {
        QIIME2_EXPORT_SEQUENCES_ABSOLUTE (
            ch_feature_table_filtered,
            ch_sequences_filtered
        )
    }

    /*
        MODULE: Export relative abundance table of sequences
    */
    if (params.amplicon_do_export_sequences_relative) {
        QIIME2_EXPORT_SEQUENCES_RELATIVE (
            ch_feature_table_filtered
        )
    }

    /*
        MODULE: Export absolute abundance table of taxonomy
    */
    if (params.amplicon_do_export_taxonomy_absolute) {
        QIIME2_EXPORT_TAXONOMY_ABSOLUTE (
            ch_feature_table_filtered,
            ch_analysis_taxonomy_qza,
            params.amplicon_export_taxonomy_absolute_collapse_levels
        )
    }

    /*
        MODULE: Export relative abundance table of taxonomy
    */
    if (params.amplicon_do_export_taxonomy_relative) {
        QIIME2_EXPORT_TAXONOMY_RELATIVE (
            ch_feature_table_filtered,
            ch_analysis_taxonomy_qza,
            params.amplicon_export_taxonomy_relative_collapse_levels
        )
    }

    /*
        MODULE: Render a taxonomy barplot using QIIME 2's built-in functionality
    */
    if (params.amplicon_do_export_taxonomy_barplot) {
        QIIME2_BARPLOT_TAXONOMY (
            ch_feature_table_filtered,
            ch_analysis_taxonomy_qza
        )
    }

    /*
        MODULE: Perform rarefaction
    */
    if (params.amplicon_do_rarefaction) {
        QIIME2_RAREFY (
            ch_feature_table_filtered
        )
        ch_feature_table_rarefied = QIIME2_RAREFY.out.feature_table
    } else {
        ch_feature_table_rarefied = ch_feature_table_filtered
    }

    /*
        MODULE: Calculate alpha diversity
    */
    if (params.amplicon_do_alpha_diversity) {
        QIIME2_ALPHA_DIVERSITY (
            ch_feature_table_rarefied,
            [],
            params.amplicon_alpha_diversity_metrics,
            ""
        )
    }

    /*
        MODULE: Calculate phylogenetic alpha diversity
    */
    if (params.amplicon_do_alpha_diversity_phylogenetic && params.amplicon_do_phylogenetic_placement) {
        QIIME2_ALPHA_DIVERSITY_PHYLOGENETIC (
            ch_feature_table_rarefied,
            ch_phylogenetic_tree,
            params.amplicon_alpha_diversity_phylogenetic_metrics,
            "phylogenetic"
        )
    }

    /*
        MODULE: Calculate beta diversity
    */
    if (params.amplicon_do_beta_diversity) {
        QIIME2_BETA_DIVERSITY (
            ch_feature_table_rarefied,
            [],
            params.amplicon_beta_diversity_metrics,
            ""
        )
    }

    /*
        MODULE: Calculate phylogenetic beta diversity
    */
    if (params.amplicon_do_beta_diversity_phylogenetic && params.amplicon_do_phylogenetic_placement) {
        QIIME2_BETA_DIVERSITY_PHYLOGENETIC (
            ch_feature_table_rarefied,
            ch_phylogenetic_tree,
            params.amplicon_beta_diversity_phylogenetic_metrics,
            "phylogenetic"
        )
    }

    emit:
    versions         = ch_versions
    multiqc_output   = ch_multiqc_files
}
