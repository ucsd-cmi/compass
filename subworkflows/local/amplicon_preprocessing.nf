/*
    Perform preprocessing steps for 16S
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CUTADAPT                                            } from '../../modules/nf-core/cutadapt/main'
include { FASTQC as FASTQC_TRIMMED                            } from '../../modules/nf-core/fastqc/main'
include { DADA2_QUALITY_PROFILE as DADA2_QUALITY_PROFILE_PRE  } from '../../modules/local/dada2_quality_profile'
include { DADA2_QUALITY_PROFILE as DADA2_QUALITY_PROFILE_POST } from '../../modules/local/dada2_quality_profile'
include { CALCULATE_TRUNCLEN                                  } from '../../modules/local/calculate_trunclen'
include { DADA2_FILTER_AND_TRIM                               } from '../../modules/local/dada2_filter_and_trim'

workflow AMPLICON_PREPROCESSING {
    take:
    ch_reads

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()


    if (params.amplicon_do_cutadapt) {
        /*
            MODULE: Run cutadapt
        */
        CUTADAPT (
            ch_reads
        )
        ch_trimmed_reads = CUTADAPT.out.reads
        ch_multiqc_files = ch_multiqc_files.mix(CUTADAPT.out.log)

        /*
            MODULE: Run FastQC on trimmed reads
        */
        FASTQC_TRIMMED (
            ch_trimmed_reads
        )
        ch_versions = ch_versions.mix(FASTQC_TRIMMED.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip)
    } else {
        if (params.amplicon_paired_end_data) {
            ch_trimmed_reads = ch_reads
        } else {
            ch_trimmed_reads = ch_reads
                .map { meta, reads -> [ meta, reads[0]]}
        }
    }

    /*
        Group reads by direction, or just re-map single_end reads
    */
    if (params.amplicon_paired_end_data) {
        ch_trimmed_reads_forward = ch_trimmed_reads
            .map { _meta, reads -> [ reads[0] ] }
            .collect()
            .map { reads -> [ "forward", reads ]}
        ch_trimmed_reads_reverse = ch_trimmed_reads
            .map { _meta, reads -> [ reads[1] ] }
            .collect()
            .map { reads -> [ "reverse", reads ]}
        ch_trimmed_reads_merged = ch_trimmed_reads_forward
            .mix(ch_trimmed_reads_reverse)
    } else {
        ch_trimmed_reads_merged = ch_trimmed_reads
            .map { _meta, reads -> [ reads ] }
            .collect()
            .map { reads -> [ "single_end", reads ] }
    }

    /*
        MODULE: DADA2 quality profiling before filtering and trimming
    */
    DADA2_QUALITY_PROFILE_PRE (
        ch_trimmed_reads_merged
    )
    ch_multiqc_files = ch_multiqc_files.mix(DADA2_QUALITY_PROFILE_PRE.out.multiqc_png)

    /*
        MODULE: Calculate truncation length based on provided parameters
    */
    if (params.amplicon_calculate_trunclen) {
        CALCULATE_TRUNCLEN(
            ch_trimmed_reads_merged,
            params.amplicon_calculate_trunclen_quality_threshold
        )
        if (params.amplicon_paired_end_data) {
            ch_truncate_values = CALCULATE_TRUNCLEN.out.truncate_values
                .toSortedList({ direction, value -> direction[0] <=> value[0] })
        } else {
            ch_truncate_values = CALCULATE_TRUNCLEN.out.truncate_values
                .map { _direction, value -> ["forward", value] }
                .mix(channel.of(["reverse", 0]))
                .toSortedList({ direction, value -> direction[0] <=> value[0]})
        }
    } else {
        ch_truncate_values = channel.fromList([["forward", params.amplicon_trunclen_forward], ["reverse", params.amplicon_trunclen_reverse]])
            .toSortedList()
    }
    ch_trimmed_reads = ch_trimmed_reads.combine(
        ch_truncate_values
    )

    /*
        MODULE: DADA2 filtering and trimming
    */
    DADA2_FILTER_AND_TRIM (
        ch_trimmed_reads
    )

    ch_dada2_filtering_output = DADA2_FILTER_AND_TRIM.out.filtered_reads
        .branch { it ->
            failed: it[0].single_end ? it[1].countFastq() < params.amplicon_minimum_read_count : it[1][0].countFastq() < params.amplicon_minimum_read_count || it[1][1].countFastq() < params.amplicon_minimum_read_count
            passed: true
        }

    ch_dada2_reads_passed = ch_dada2_filtering_output.passed

    // Either log or abort due to samples that failed preprocessing
    ch_dada2_filtering_output.failed
        .map { meta, _reads -> ["${meta.id}_${meta.run_id}"] }
        .collect()
        .subscribe { it ->
            def failed_sample_list = it.join(", ")
            if(params.amplicon_abort_failed_preprocessing) {
                error("After preprocessing, the following samples' read counts fell below the threshold set by the amplicon_minimum_read_count parameter:\n${failed_sample_list}\nPer the amplicon_abort_failed_preprocessing parameter, the pipeline has aborted. Please review your configuration options before attempting to process these samples again.")
            } else {
                log.warn("After preprocessing, the following samples' read counts fell below the threshold set by the amplicon_minimum_read_count parameter:\n${failed_sample_list}\nThese samples will not be included in any further output from the pipeline.")
            }
        }

    if (params.amplicon_paired_end_data) {
        ch_filtered_reads_forward = ch_dada2_reads_passed
            .map { _meta, reads -> [ reads[0] ] }
            .collect()
            .map { reads -> [ "forward", reads ]}
        ch_filtered_reads_reverse = ch_dada2_reads_passed
            .map { _meta, reads -> [ reads[1] ] }
            .collect()
            .map { reads -> [ "reverse", reads ]}
        ch_filtered_reads_merged = ch_filtered_reads_forward
            .mix(ch_filtered_reads_reverse)
    } else {
        ch_filtered_reads_merged = ch_dada2_reads_passed
            .map { _meta, reads -> [ reads ] }
            .collect()
            .map { reads -> [ "single_end", reads ]}
    }

    /*
        MODULE: DADA2 quality profiling after filtering and trimming
    */
    DADA2_QUALITY_PROFILE_POST (
        ch_filtered_reads_merged
    )
    ch_multiqc_files = ch_multiqc_files.mix(DADA2_QUALITY_PROFILE_POST.out.multiqc_png)

    emit:
    reads          = ch_dada2_reads_passed
    versions       = ch_versions
    multiqc_output = ch_multiqc_files
}