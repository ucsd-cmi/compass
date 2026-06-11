/*
    The side of COMPASS to process shotgun metagenomic samples
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { UNZIP                } from '../../modules/nf-core/unzip/main'
include { FASTQC               } from '../../modules/nf-core/fastqc/main'
include { SEQKIT_PAIR          } from '../../modules/nf-core/seqkit/pair/main'
include { CAT_FASTQ            } from '../../modules/nf-core/cat/fastq/main'
include { TAXPASTA_STANDARDISE } from '../../modules/nf-core/taxpasta/standardise/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SHOTGUN_PREPROCESSING } from './shotgun_preprocessing'
include { SHOTGUN_PROFILING     } from './shotgun_profiling'
include { SHOTGUN_HOSTREMOVAL   } from './shotgun_hostremoval'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SHOTGUN_WORKFLOW {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_ref_databases // channel: reference databases read in from --ref_databases

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    /*
        MODULE: Unzip reference databases
        NB: This is essentially only for the test profile, but could be useful later
    */

    ch_ref_databases_to_unzip = ch_ref_databases.branch { db_meta, db_path ->
        unzip: db_path.name.endsWith(".zip")
        skip: true
    }

    UNZIP (
        ch_ref_databases_to_unzip.unzip
    )

    ch_ref_databases_final = UNZIP.out.unzipped_archive
        .mix(ch_ref_databases_to_unzip.skip)

    /*
        MODULE: Run FastQC
    */

    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    /*
        SUBWORKFLOW: Preprocessing
    */
    if (params.shotgun_do_preprocessing) {
        shotgun_adapter_list = params.shotgun_adapter_list ? file(params.shotgun_adapter_list) : []

        SHOTGUN_PREPROCESSING (
            ch_samplesheet,
            shotgun_adapter_list
        )

        ch_trimmed_reads = SHOTGUN_PREPROCESSING.out.reads
        ch_multiqc_files = ch_multiqc_files.mix(SHOTGUN_PREPROCESSING.out.multiqc_output.collect{it[1]})
        ch_versions = ch_versions.mix(SHOTGUN_PREPROCESSING.out.versions)
    } else {
        ch_trimmed_reads = ch_samplesheet
    }

    /*
        SUBWORKFLOW: Host removal
    */
    if (params.shotgun_do_host_removal) {
        SHOTGUN_HOSTREMOVAL (
            ch_trimmed_reads,
            ch_ref_databases_final
        )
        ch_multiqc_files = ch_multiqc_files.mix(SHOTGUN_HOSTREMOVAL.out.multiqc_output.collect{it[1]})
        ch_host_filtered_reads = SHOTGUN_HOSTREMOVAL.out.reads
    } else {
        ch_host_filtered_reads = ch_trimmed_reads
    }

    /*
        MODULE: SEQKIT_PAIR
    */
    if (params.shotgun_do_read_pairing) {
            ch_reads_to_pair = ch_host_filtered_reads
                .branch { meta, reads ->
                    pair: !meta.single_end
                    no_pair: meta.single_end
                }

            SEQKIT_PAIR (
                ch_reads_to_pair.pair
            )
            ch_paired_reads = SEQKIT_PAIR.out.reads
                .mix(ch_reads_to_pair.no_pair)
    } else {
        ch_paired_reads = ch_host_filtered_reads
    }

    /*
        MODULE: CAT_FASTQ for run merging
    */
    if (params.shotgun_do_run_merging) {
        ch_reads_to_merge = ch_paired_reads
            .map{ meta, reads ->
                def meta_tmp = meta - meta.subMap('run_id')
                [meta_tmp, reads]
            }
            .groupTuple()
            .map{ meta, reads ->
                [meta, reads.flatten()]
            }
            .branch{ meta, reads ->
                merge: (meta.single_end && reads.size > 1) || (!meta.single_end && reads.size > 2)
                no_merge: true
            }

        CAT_FASTQ (
            ch_reads_to_merge.merge
        )
        ch_merged_reads = CAT_FASTQ.out.reads
            .mix(ch_reads_to_merge.no_merge)
            .map { meta, reads ->
                [meta, [reads].flatten()]
            }
    } else {
        ch_merged_reads = ch_paired_reads
    }

    /*
        SUBWORKFLOW: Taxonomic profiling
    */
    SHOTGUN_PROFILING (
        ch_merged_reads,
        ch_ref_databases_final
    )
    ch_multiqc_files = ch_multiqc_files.mix(SHOTGUN_PROFILING.out.multiqc_output.collect{it[1]})

    /*
        MODULE: Taxpasta
    */
    if (params.shotgun_do_profiling_standardisation) {
        ch_standardise = SHOTGUN_PROFILING.out.profiles.multiMap { meta, profile ->
            profiles: [meta, profile]
            tool: meta.tool
        }

        ch_taxonomy = params.shotgun_taxpasta_taxonomy ? channel.fromPath(params.shotgun_taxpasta_taxonomy).collect() : []

        TAXPASTA_STANDARDISE (
            ch_standardise.profiles,
            ch_standardise.tool,
            params.shotgun_profiling_standardisation_format,
            ch_taxonomy
        )
    }
    
    emit:
    versions        = ch_versions
    multiqc_output  = ch_multiqc_files
}