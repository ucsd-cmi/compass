/*
    Perform taxonomic classification and profiling
*/

include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main'
include { BRACKEN_BRACKEN } from '../../modules/nf-core/bracken/bracken/main'

workflow PROFILING {
    take:
    reads
    ch_ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    // Set up channel to use for optional standardisation
    ch_profiles = channel.empty()

    /*
        MODULE: Kraken2
    */
    if (params.do_kraken2) {
        ch_kraken2_ref = ch_ref_databases
            .filter { meta, path -> meta.tool == 'kraken2' }
            .map { meta, path ->
                def cur_db_params = meta['ref_db_params']
                def meta_new = [:]
                if (cur_db_params.size == 0) {
                    meta_new = meta + [ref_db_params: ""]
                } else {
                    meta_new = meta + [ref_db_params: cur_db_params[0]]
                }

                [meta_new, path]
            }

        ch_kraken2_input = reads
            .combine(ch_kraken2_ref)
            .multiMap { it ->
                reads: [it[0] + it[2], it[1]]
                db: it[3]
            }

        KRAKEN2_KRAKEN2 (
            ch_kraken2_input.reads,
            ch_kraken2_input.db,
            true,
            true
        )
        ch_profiles = ch_profiles.mix(KRAKEN2_KRAKEN2.out.report)
        ch_multiqc_files = ch_multiqc_files.mix(KRAKEN2_KRAKEN2.out.report)
    }

    /*
        MODULE: Bracken
    */
    if (params.do_kraken2 && params.do_bracken ) {
        ch_bracken_ref = ch_ref_databases
            .filter { meta, path -> meta.tool == 'bracken'}
            .map { meta, path ->
                def cur_db_params = meta['ref_db_params']
                def meta_new = [:]
                if (cur_db_params.size == 0) {
                    meta_new = meta + [ref_db_params: ""]
                } else {
                    meta_new = meta + [ref_db_params: cur_db_params[0]]
                }

                [meta_new, path]
            }

        ch_bracken_input = KRAKEN2_KRAKEN2.out.report
            .combine(ch_bracken_ref)
            .multiMap { it ->
                report: [it[0] + it[2], it[1]]
                db: it[3]
            }

        BRACKEN_BRACKEN (
            ch_bracken_input.report,
            ch_bracken_input.db
        )
        ch_profiles = ch_profiles.mix(BRACKEN_BRACKEN.out.reports)
        ch_multiqc_files = ch_multiqc_files.mix(BRACKEN_BRACKEN.out.reports)
    }

    emit:
    profiles        = ch_profiles
    versions        = ch_versions
    multiqc_output  = ch_multiqc_files
}
