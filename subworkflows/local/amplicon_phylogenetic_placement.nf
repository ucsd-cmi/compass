/*
    Perform taxonomic classification for amplicon samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { QIIME2_IMPORT_SEQUENCES } from '../../modules/local/qiime2_import_sequences'
include { QIIME2_IMPORT_ASV       } from '../../modules/local/qiime2_import_asv'
include { QIIME2_SEPP             } from '../../modules/local/qiime2_sepp'

workflow AMPLICON_PHYLOGENETIC_PLACEMENT {
    take:
    asv_tsv
    asv_fasta
    ch_ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Import sequences to .qza file for QIIME 2
    */
    QIIME2_IMPORT_SEQUENCES (
        asv_fasta
    )

    /*
        MODULE: Import asv table to .qza file for QIIME 2
    */
    QIIME2_IMPORT_ASV (
        asv_tsv
    )

    ch_sepp_reference = ch_ref_databases
        .filter { meta, _path -> meta.tool == 'sepp' }
        .first()

    /*
        MODULE: Perform phylogenetic placement with SEPP via QIIME 2
    */
    QIIME2_SEPP (
        QIIME2_IMPORT_SEQUENCES.out.qza,
        ch_sepp_reference,
        QIIME2_IMPORT_ASV.out.qza
    )

    emit:
    tree                    = QIIME2_SEPP.out.tree
    versions                = ch_versions
    multiqc_output          = ch_multiqc_files

}