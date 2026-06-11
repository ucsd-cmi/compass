/*
    Perform ASV inference for amplicon samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { DADA2_ERROR_MODEL     } from '../../modules/local/dada2_error_model'
include { DADA2_DENOISE         } from '../../modules/local/dada2_denoise'
include { DADA2_REMOVE_CHIMERAS } from '../../modules/local/dada2_remove_chimeras'
include { DADA2_COMBINE         } from '../../modules/local/dada2_combine'

workflow AMPLICON_ASV_INFERENCE {
    take:
    ch_reads

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    // Group reads by run_id
    ch_reads_grouped_by_run = ch_reads
        .map { meta_info, reads ->
            def meta = meta_info.subMap(meta_info.keySet() - 'id')
            [ meta, reads, meta_info.id ]
        }.groupTuple(by: 0)
        .map { meta_info, reads, ids ->
            def meta = meta_info + [id: ids.flatten().sort()]
            [ meta, reads.flatten().sort() ]
        }

    /*
        MODULE: DADA2 error model construction
    */
    DADA2_ERROR_MODEL (
        ch_reads_grouped_by_run
    )
    ch_reads_with_error_models = ch_reads_grouped_by_run
        .join(DADA2_ERROR_MODEL.out.error_model)

    /*
        MODULE: DADA2 denoising
    */
    DADA2_DENOISE (
        ch_reads_with_error_models
    )

    /*
        MODULE: DADA2 remove chimeric reads
    */
    if (params.amplicon_do_remove_chimeras) {
        DADA2_REMOVE_CHIMERAS (
            DADA2_DENOISE.out.sequence_table
        )

        table_list = DADA2_REMOVE_CHIMERAS.out.asv_table
            .map { _meta, asv_rds -> asv_rds }
            .collect()
    } else {
        table_list = DADA2_DENOISE.out.sequence_table
            .map { _meta, asv_rds -> asv_rds }
            .collect()
    }

    /*
        MODULE: Combine all runs into one table
    */
    DADA2_COMBINE (
        table_list
    )

    emit:
    ch_asv_tsv     = DADA2_COMBINE.out.dada2_asv_tsv
    ch_asv_fasta   = DADA2_COMBINE.out.asv_fasta
    versions       = ch_versions
    multiqc_output = ch_multiqc_files
}
