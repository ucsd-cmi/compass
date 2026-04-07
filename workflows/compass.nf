/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                   } from '../modules/nf-core/fastqc/main'
include { MULTIQC                  } from '../modules/nf-core/multiqc/main'
include { SEQKIT_PAIR              } from '../modules/nf-core/seqkit/pair/main'   
include { CAT_FASTQ                } from '../modules/nf-core/cat/fastq/main'
include { TAXPASTA_STANDARDISE     } from '../modules/nf-core/taxpasta/standardise/main'
include { paramsSummaryMap         } from 'plugin/nf-schema'
include { paramsSummaryMultiqc     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText   } from '../subworkflows/local/utils_nfcore_compass_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREPROCESSING } from '../subworkflows/local/preprocessing'
include { PROFILING     } from '../subworkflows/local/profiling'
include { HOSTREMOVAL   } from '../subworkflows/local/hostremoval'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COMPASS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_ref_databases // channel: reference databases read in from --ref_databases

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    //
    // MODULE: Run FastQC
    //
    
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    
    /*
        SUBWORKFLOW: Preprocessing
    */
    if (params.do_preprocessing) {
        adapter_list = params.adapter_list ? file(params.adapter_list) : []

        PREPROCESSING (
            ch_samplesheet,
            adapter_list
        )

        ch_trimmed_reads = PREPROCESSING.out.reads
        ch_multiqc_files = ch_multiqc_files.mix(PREPROCESSING.out.multiqc_output.collect{it[1]})
        ch_versions = ch_versions.mix(PREPROCESSING.out.versions)
    } else {
        ch_trimmed_reads = ch_samplesheet
    }

    if (params.do_host_removal) {
        HOSTREMOVAL (
            ch_trimmed_reads,
            ch_ref_databases
        )
        ch_multiqc_files = ch_multiqc_files.mix(HOSTREMOVAL.out.multiqc_output.collect{it[1]})
        ch_host_filtered_reads = HOSTREMOVAL.out.reads
    } else {
        ch_host_filtered_reads = ch_trimmed_reads
    }

    if (params.do_read_pairing) {
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

    if (params.do_run_merging) {
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

    PROFILING (
        ch_merged_reads,
        ch_ref_databases
    )
    ch_multiqc_files = ch_multiqc_files.mix(PROFILING.out.multiqc_output.collect{it[1]})

    if (params.do_profiling_standardisation) {
        ch_standardise = PROFILING.out.profiles.multiMap { meta, profile ->
            profiles: [meta, profile]
            tool: meta.tool
        }

        ch_taxonomy = params.taxpasta_taxonomy ? channel.fromPath(params.taxpasta_taxonomy).collect() : []

        TAXPASTA_STANDARDISE (
            ch_standardise.profiles,
            ch_standardise.tool,
            params.profiling_standardisation_format,
            ch_taxonomy
        )
    }

    //
    // Collate and save software versions
    //
    def topic_versions = Channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'compass_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        channel.fromPath(params.multiqc_config, checkIfExists: true) :
        channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/