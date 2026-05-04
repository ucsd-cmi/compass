# ucsd-cmi/compass: Usage

## Introduction

For an introduction to the COMPASS pipeline, please see the [project's README file](../README.md).

## Inputs

There are three required items or sets of items to run the pipeline:

- FASTQ files (currently, only Illumnia short-read sequencing data is support)
- A samplesheet
- A spreadsheet with the reference databases you'd like to use for various tools

The FASTQ files may be hosted anywhere that your Nextflow installation can access them (e.g. local drives, S3 buckets, etc.) and can all be in one directory or spread out. We recommend using absolute paths in your sample sheet - for example `/path/to/fastq_R1.fq.gz` rather than `fastq_R1.fq.gz` but the pipeline does not enforce that restriction.

The samplesheet (samplesheet.csv) should be formatted as follows:
```
sample_id,run_id,fastq_1,fastq_2
SAMPLE1,RUN1,/path/to/SAMPLE1_RUN1_R1.fastq.gz,/path/to/SAMPLE1_RUN1_R2.fastq.gz
SAMPLE2,RUN1,/path/to/SAMPLE2_RUN1_R1.fastq.gz,/path/to/SAMPLE2_RUN1_R2.fastq.gz
SAMPLE1,RUN2,/path/to/SAMPLE1_RUN2_R1.fastq.gz,/path/to/SAMPLE1_RUN2_R2.fastq.gz
```

If you're processing multiple runs of a given sample and intend to merge the reads, it's critical to ensure the sample_id is consistent for every instance of that sample.

The reference database spreadsheet should be formatted as follows:
```
tool,ref_db_name,ref_db_params,ref_db_path
bowtie2,CHM13v2,,/path/to/chm13v2/
bracken,PlusPF,,/path/to/pluspf/
kraken2,PlusPF,,/path/to/pluspf/
```

The `ref_db_name` column is strictly informational.

Note that the `ref_db_params` column can be used to pass extra parameters into a specific tool (excluding bowtie2, which ignores any value in that field). For example:
```
bracken,PlusPF,-r 150,/path/to/pluspf/
```

## Parameters

COMPASS is designed to be highly modular, meaning that every step except for FastQC at start and MultiQC at completion are optional. We've set a default path and set of parameters that we believe to be ideal for generating taxonomic and profiling output.

Parameters can be provided to the pipeline two ways:

- Directly on the command line:
```
nextflow run ucsd-cmi/compass \
    -profile docker \
    --input samplesheet.csv \
    --ref_databases ref_databases.csv \
    --outdir </path/to/store/output> \
    --do_preprocessing false \
    --do_host_removal false
```

- Or by creating a params.json file:
```
{
    "do_preprocessing": false,
    "do_host_removal": false
}
```

And using the `-params-file` flag:
```
nextflow run ucsd-cmi/compass \
    -profile docker \
    --input samplesheet.csv \
    --ref_databases ref_databases.csv \
    --outdir </path/to/store/output> \
    -params-file params.json
```

Below is a full list of parameters for the pipeline:

### Pre-processing

- do_preprocessing
```
Type: boolean
Default: true
Description: Determines whether to do sample pre-processing steps
Help Text: It's generally recommended to do pre-processing unless you know it has already been performed using external tools.
```

- preprocessing_min_read_length
```
Type: integer
Default: 15
Description: Minimum length of reads to preserve and process
Help Text: Changing the minimum read length will impact both profiling speed and accuracy.
```

- preprocessing_fastp_qualified_quality_phred
```
Type: integer
Default: 15
Description: Minimum phred quality score to consider a read qualified
Help Text: Increasing this value will enact stricter quality filtering.
```

- preprocessing_fastp_cut_tail
```
Type: Boolean
Default: false
Description: Determines whether to use fastp's --cut_tail parameter
Help Text: --cut_tail performs sliding window trimming from the 3' (tail) end of a read, removing low-quality bases based on mean quality.
```

### Host Removal

- do_host_removal
```
Type: boolean
Default: true
Description: Determines whether to do host removal steps
Help Text: It's generally recommended to perform host removal if you're interested in microbial composition.
```

- host_removal_bowtie2_very_sensitive
```
Type: boolean
Default: true
Description: Determines whether to use the --very-sensitive parameter for Bowtie2
Help Text: Setting this to true will help maximize host removal.
```

### Read Pairing

- do_read_pairing
```
Type: boolean
Default: true
Description: Determines whether to ensure all reads in paired-end files are correctly paired
Help Text: Setting this to true will drop singletons before proceeding with taxonomic profiling.
```

### Run Merging

- do_run_merging
```
Type: boolean
Default: false
Description: Determines whether to merge samples with the sample sample_id
Help Text: Optional step to merge samples prior to the profiling step.
```

### Profiling

- do_kraken2
```
Type: boolean
Default: true
Description: Determines whether to run Kraken2
Help Text: Given that Kraken2 is currently the only profiler available, this should not be changed to false.
```

- do_kraken2_filtering
```
Type: boolean
Default: false
Description: Determines whether to use KrakenTools/extract_kraken_reads to filter Kraken2 output
Help Text: This allows you to either include or exclude reads with specific taxonomic IDs from downstream output. Running this will also cause Kraken2 to be re-run on this tool's output.
```

- kraken2_filtering_taxids
```
Type: string
Default: null
Description: Space-delimited list of taxonomic IDs to filter
Help Text: IDs can be from any taxonomic rank
```

- kraken2_filtering_mode
```
Type: string
Valid Values: exclude, include
Defualt: exclude
Description: Determines whether the specified taxonomic IDs are included (kept) or excluded (discarded)
Help Text: Default behavior is to exclude for the purpose of ensuring host reads are fully removed.
```

- kraken2_filtering_include_parents
```
Type: boolean
Default: false
Description: Determines whether parent taxonomic IDs should be included in filter
Help Text: Determines whether parent taxonomic IDs should be included in filter
```

- kraken2_filtering_include_children
```
Type: boolean
Default: false
Description: Determines whether child taxonomic IDs should be included in filter
Help Text: Determines whether child taxonomic IDs should be included in filter
```

- do_bracken
```
Type: boolean
Default: true
Description: Determines whether to run Bracken
Help Text: Optional tool to estimate abundance of taxa within a sample. Requires Kraken2.
```

### Profiling Standardisation

- do_profiling_standardisation
```
Type: boolean
Default: false
Description: Determines whether to run Taxpasta
Help Text: Optional tool to standardise output from various taxonomic profiling tools.
```

- profiling_standardisation_format
```
Type: string
Default: "tsv"
Valid Values: "tsv", "csv", "ods", "xlsx", "arrow", "parquet", "biom"
Description: Output format from Taxpasta
Help Text: Output format from Taxpasta
```

- taxpasta_taconomy
```
Type: string
Default: null
Description: Path to directory containing taxdump files
Help Text: For current pipeline usage, this should be the same path as the Kraken2 reference database.
```

- taxpasta_add_name
```
Type: boolean
Default: false
Description: Add taxon name to Taxpasta output
Help Text: Add taxon name to Taxpasta output
```

- taxpasta_add_rank
```
Type: boolean
Default: false
Description: Add taxon rank to Taxpasta output
Help Text: Add taxon rank to Taxpasta output
```

- taxpasta_add_lineage
```
Type: boolean
Default: false
Description: Add full taxon lineage to Taxpasta output - names
Help Text: Taxon names separated by semicolons
```

- taxpasta_add_id_lineage
```
Type: boolean
Default: false
Description: Add full taxon lineage to Taxpasta output - IDs
Help Text: Taxon identifiers separated by semicolons
```

- taxpasta_add_rank_lineage
```
Type: boolean
Default: false
Description: Add full taxon rank lineage to Taxpasta output
Help Text: Taxon ranks separated by semicolons
```
