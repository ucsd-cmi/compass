# COMPASS: COmprehensive Metagenomics Platform for Automated Sequence Solutions

## Introduction

COMPASS is an analysis pipeline to generate taxonomic classification and profiling output from shotgun metagenomic data. Currently, the pipeline is set up to process short-read data from Illumina sequencing platforms, but furture development plans include long-read data and other sequencing platforms. Additionally, a separate pathway for 16S data will be included in a future version of the pipeline.

## Pipeline Summary

COMPASS is intended to be highly modular, allowing users to use or skip steps as they desire. For example, a user can theoretically skip all tools beyond the startup FastQC step and the closing MultiQC report. However, we generally expect users to follow most or all steps of the pipeline, they're not required.

![](docs/images/pipeline_diagram.png)

The current toolset is fairly linear, but we anticipate adding alternative tools at each step of the pipeline.
- FastQC for read quality control (both before and after adapter trimming)
- fastp for adapter trimming
- Bowtie2 for host-read removal
- Samtools for generation of host-read removal statistics
- Cat/FASTQ as necessary for merging samples with multiple runs
- Kraken2 and Bracken for taxonomic classification and profiling
- taxpasta for the optional standardization of taxonomic profile output
- MultiQC for report generation

## Pipeline Usage

> If you have not used Nextflow or nf-core in the past, it would be helpful to review the [nf-core installation guide](https://nf-co.re/docs/usage/installation).

To run the pipeline, you must have:
- FASTQ files for one or more samples
- A samplesheet
- A reference database sheet
- Optionally, a JSON file containing parameters for the pipeline - this is only needed if you want to deviate from the pipeline's default settings, and you may also provide parameters using the command line

The samplesheet (samplesheet.csv) should be formatted as follows:
```
sample_id,run_id,fastq_1,fastq_2
SAMPLE1,RUN1,/path/to/SAMPLE1_RUN1_R1.fastq.gz,/path/to/SAMPLE1_RUN1_R2.fastq.gz
SAMPLE2,RUN1,/path/to/SAMPLE2_RUN1_R1.fastq.gz,/path/to/SAMPLE2_RUN1_R2.fastq.gz
SAMPLE1,RUN2,/path/to/SAMPLE1_RUN2_R1.fastq.gz,/path/to/SAMPLE1_RUN2_R2.fastq.gz
```

And the reference databasesheet should be formatted as follows:
```
tool,ref_db_name,ref_db_params,ref_db_path
bowtie2,CHM13v2,,/path/to/chm13v2/
bracken,PlusPF,,/path/to/pluspf/
kraken2,PlusPF,,/path/to/pluspf/
```

Note that the `ref_db_params` column can be used to pass extra parameters into a specific tool (excluding bowtie2, which ignores any value in that field). For example:
```
bracken,PlusPF,-r 150,/path/to/pluspf/
```

With those files created, you can run the pipeline (replace docker with your profile of choice):
```
nextflow run ucsd-cmi/compass \
    -profile docker \
    --input samplesheet.csv \
    --ref_databases ref_databases.csv \
    --outdir </path/to/store/output>
```

You may use other parameters with an optional `-params-file params.json` flag, or by adding them directly to the command, such as `--adapter_list /path/to/adapters.fna`.

If you're interested in using a hosted version of COMPASS to perform sample processing and analysis, or have any questions or comments about the pipeline, please contact us at [CMIInfo@ucsd.edu](mailto:cmiinfo@ucsd.edu).

## Pipeline Output

Please see the [output document](docs/output.md).

## Credits

COMPASS was originally written by Cassidy Symons with support and contributions from Se Jin Song and Tyler Myers, all with the Center for Microbiome Innovation at UC San Diego.

## Acknowledgments and Thanks

COMPASS was built with support from and in conjunction with SwipeBiome, for which we thank them.

COMPASS was built on the nf-core framework, and we thank the entire nf-core community and ecosystem for their work on the framework and constitutent modules.

## Citations

A full list of citations, included tools used within the pipeline, data used for automated testing, and reference data used within the hosted copy of the pipeline, is available in the [citations document](CITATIONS.md).
