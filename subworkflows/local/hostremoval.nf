/*
    Perform host removal and generate corresponding stats
*/

include { BOWTIE2_ALIGN  } from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_VIEW  } from '../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_FASTQ } from '../../modules/nf-core/samtools/fastq/main'
include { SAMTOOLS_INDEX } from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_STATS } from '../../modules/nf-core/samtools/stats/main'

workflow HOSTREMOVAL {
    take:
    reads
    ch_ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Bowtie2
    */
    ch_bowtie2_ref = ch_ref_databases
        .filter { meta, path -> meta.tool == 'bowtie2' }
        .first()

    BOWTIE2_ALIGN(
        reads, ch_bowtie2_ref, [[], []], true, true
    )
    ch_multiqc_files = ch_multiqc_files.mix(BOWTIE2_ALIGN.out.log)
    ch_bowtie2_aligned = BOWTIE2_ALIGN.out.bam.map { meta, out_reads ->
        [meta, out_reads, []]
    }

    /*
        MODULES: Samtools view and fastq to further filter reads
    */
    SAMTOOLS_VIEW(
        ch_bowtie2_aligned, [[], []], [], ''
    )
    SAMTOOLS_FASTQ(
        SAMTOOLS_VIEW.out.bam, false
    )

    /*
        MODULES: Samtools index and stats
    */
    SAMTOOLS_INDEX (
        BOWTIE2_ALIGN.out.bam
    )
    bam_bai = BOWTIE2_ALIGN.out.bam.join(SAMTOOLS_INDEX.out.bai, remainder: true)

    SAMTOOLS_STATS (
        bam_bai, [[], []]
    )

    ch_multiqc_files = ch_multiqc_files.mix(SAMTOOLS_STATS.out.stats)

    emit:
    reads          = SAMTOOLS_FASTQ.out.fastq
    versions       = ch_versions
    multiqc_output = ch_multiqc_files
}
