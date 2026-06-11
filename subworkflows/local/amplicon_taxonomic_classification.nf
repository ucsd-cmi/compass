/*
    Perform taxonomic classification for amplicon samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { DADA2_CLASSIFY_TAXONOMY  } from '../../modules/local/dada2_classify_taxonomy'
include { DADA2_ADD_SPECIES        } from '../../modules/local/dada2_add_species'
include { QIIME2_IMPORT_SEQUENCES  } from '../../modules/local/qiime2_import_sequences'
include { QIIME2_CLASSIFY_TAXONOMY } from '../../modules/local/qiime2_classify_taxonomy'

workflow AMPLICON_TAXONOMIC_CLASSIFICATION {
    take:
    asv_fasta
    ch_ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    if (params.amplicon_do_taxonomic_classification_dada2) {
        ch_dada2_classifier = ch_ref_databases
            .filter { meta, _path -> meta.tool == 'dada2' }
            .first()

        /*
            MODULE: DADA2 classify taxonomy
        */
        DADA2_CLASSIFY_TAXONOMY (
            asv_fasta,
            ch_dada2_classifier
        )

        if(params.amplicon_do_taxonomic_classification_dada2_species) {
            ch_dada2_species_classifier = ch_ref_databases
                .filter { meta, _path -> meta.tool == 'dada2_species' }
                .first()

            /*
                MODULE: DADA2 add species
            */
            DADA2_ADD_SPECIES (
                DADA2_CLASSIFY_TAXONOMY.out.rds,
                ch_dada2_species_classifier
            )
            ch_dada2_taxonomy_tsv = DADA2_ADD_SPECIES.out.tsv
        } else {
            ch_dada2_taxonomy_tsv = DADA2_CLASSIFY_TAXONOMY.out.tsv
        }
    } else {
        ch_dada2_taxonomy_tsv = channel.empty()
    }

    if (params.amplicon_do_taxonomic_classification_qiime2) {
        ch_qiime2_classifier = ch_ref_databases
            .filter { meta, _path -> meta.tool == 'qiime2' }
            .first()

        /*
            MODULE: Import sequences to .qza file for QIIME 2
        */
        QIIME2_IMPORT_SEQUENCES (
            asv_fasta
        )

        /*
            MODULE: QIIME 2 classify taxonomy
        */
        QIIME2_CLASSIFY_TAXONOMY (
            QIIME2_IMPORT_SEQUENCES.out.qza,
            ch_qiime2_classifier
        )
        ch_qiime2_taxonomy_qza = QIIME2_CLASSIFY_TAXONOMY.out.qza
    } else {
        ch_qiime2_taxonomy_qza = channel.empty()
    }

    emit:
    dada2_taxonomy_tsv  = ch_dada2_taxonomy_tsv
    qiime2_taxonomy_qza = ch_qiime2_taxonomy_qza
    versions            = ch_versions
    multiqc_output      = ch_multiqc_files

}