/*
    Perform read filtering and trimming and post-preprocessing QC
*/

include { FASTP                    } from '../../modules/nf-core/fastp/main'
include { FASTQC as FASTQC_TRIMMED } from '../../modules/nf-core/fastqc/main'

workflow PREPROCESSING {
    take:
    reads
    adapterList

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Run fastp
    */

    FASTP (
        reads,
        adapterList,
        false,
        false,
        true
    )

    ch_trimmed_reads = FASTP.out.reads
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json)

    /*
        MODULE: Run FastQC on trimmed reads
    */

    FASTQC_TRIMMED (
        ch_trimmed_reads
    )

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip)
    ch_versions = ch_versions.mix(FASTQC_TRIMMED.out.versions.first())

    emit:
    reads          = ch_trimmed_reads
    versions       = ch_versions
    multiqc_output = ch_multiqc_files
}
