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

The fastq_2 column is optional and should be omitted for single-end data. In the case of amplicon workflow usage, a samplesheet must be entirely paired-end or single-end; mixing the two in a single run is not permitted.

If you're processing multiple runs of a given sample and intend to merge the reads, it's critical to ensure the sample_id is consistent for every instance of that sample.

The reference database spreadsheet should be formatted as follows:
```
tool,ref_db_name,ref_db_params,ref_db_path
bowtie2,CHM13v2,,/path/to/chm13v2/
bracken,PlusPF,,/path/to/pluspf/
kraken2,PlusPF,,/path/to/pluspf/
```

The `ref_db_name` column is strictly informational.

Note that the `ref_db_params` column can be used to pass extra parameters into a specific tool in the shotgun pipeline (excluding bowtie2, which ignores any value in that field). For example:
```
bracken,PlusPF,-r 150,/path/to/pluspf/
```

## Parameters

COMPASS is designed to be highly modular, meaning that most steps except for FastQC at start and MultiQC at completion are optional. We've set a default path and set of parameters that we believe to be ideal.

Parameters can be provided to the pipeline two ways:

- Directly on the command line:
```
nextflow run ucsd-cmi/compass \
    -profile docker \
    --input samplesheet.csv \
    --ref_databases ref_databases.csv \
    --outdir </path/to/store/output> \
    --shotgun_do_preprocessing false \
    --shotgun_do_host_removal false
```

- Or by creating a params.json file:
```
{
    "shotgun_do_preprocessing": false,
    "shotgun_do_host_removal": false
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

### General

- workflow_mode
```
Type: string
Valid Values: "amplicon", "shotgun"
Description: Workflow mode for the pipeline
Help Text: Determines whether the pipeline is in shotgun metagenomics mode or 16S mode.
```

### Shotgun Pre-processing

- shotgun_adapter_list
```
Type: string
Description: Path to a list of adapters to use in shotgun sample pre-processing
```

- shotgun_do_preprocessing
```
Type: boolean
Default: true
Description: Determines whether to do shotgun metagenomic sample pre-processing steps
Help Text: It's generally recommended to do pre-processing unless you know it has already been performed using external tools.
```

- shotgun_preprocessing_min_read_length
```
Type: integer
Default: 15
Description: Minimum length of reads to preserve and process for shotgun metagenomic samples
Help Text: Changing the minimum read length will impact both profiling speed and accuracy.
```

- shotgun_preprocessing_fastp_qualified_quality_phred
```
Type: integer
Default: 15
Description: Minimum phred quality score to consider a read qualified for shotgun metagenomic samples
Help Text: Increasing this value will enact stricter quality filtering.
```

- shotgun_preprocessing_fastp_cut_tail
```
Type: Boolean
Default: false
Description: Determines whether to use fastp's --cut_tail parameter for shotgun metagenomic samples
Help Text: --cut_tail performs sliding window trimming from the 3' (tail) end of a read, removing low-quality bases based on mean quality.
```

### Shotgun Host Removal

- shotgun_do_host_removal
```
Type: boolean
Default: true
Description: Determines whether to do host removal steps for shotgun metagenomic samples
Help Text: It's generally recommended to perform host removal if you're interested in microbial composition.
```

- shotgun_host_removal_bowtie2_very_sensitive
```
Type: boolean
Default: true
Description: Determines whether to use the --very-sensitive parameter for Bowtie2
Help Text: Setting this to true will help maximize host removal.
```

### Shotgun Read Pairing

- shotgun_do_read_pairing
```
Type: boolean
Default: true
Description: Determines whether to ensure all reads in paired-end files are correctly paired for shotgun metagenomic samples
Help Text: Setting this to true will drop singletons before proceeding with taxonomic profiling.
```

### Shotgun Run Merging

- shotgun_do_run_merging
```
Type: boolean
Default: false
Description: Determines whether to merge shotgun metagenomic samples with the same sample_id
Help Text: Optional step to merge samples prior to the profiling step.
```

### Shotgun Profiling

- shotgun_do_kraken2
```
Type: boolean
Default: true
Description: Determines whether to run Kraken2 for shotgun metagenomic samples
Help Text: Given that Kraken2 is currently the only profiler available, this should not be changed to false.
```

- shotgun_do_kraken2_filtering
```
Type: boolean
Default: false
Description: Determines whether to use KrakenTools/extract_kraken_reads to filter Kraken2 output
Help Text: This allows you to either include or exclude reads with specific taxonomic IDs from downstream output. Running this will also cause Kraken2 to be re-run on this tool's output.
```

- shotgun_kraken2_filtering_taxids
```
Type: string
Default: null
Description: Space-delimited list of taxonomic IDs to filter
Help Text: IDs can be from any taxonomic rank
```

- shotgun_kraken2_filtering_mode
```
Type: string
Valid Values: exclude, include
Defualt: exclude
Description: Determines whether the specified taxonomic IDs are included (kept) or excluded (discarded)
Help Text: Default behavior is to exclude for the purpose of ensuring host reads are fully removed.
```

- shotgun_kraken2_filtering_include_parents
```
Type: boolean
Default: false
Description: Determines whether parent taxonomic IDs should be included in filter
Help Text: Determines whether parent taxonomic IDs should be included in filter
```

- shotgun_kraken2_filtering_include_children
```
Type: boolean
Default: false
Description: Determines whether child taxonomic IDs should be included in filter
Help Text: Determines whether child taxonomic IDs should be included in filter
```

- shotgun_do_bracken
```
Type: boolean
Default: true
Description: Determines whether to run Bracken for shotgun metagenomic samples
Help Text: Optional tool to estimate abundance of taxa within a sample. Requires Kraken2.
```

### Shotgun Profiling Standardisation

- shotgun_do_profiling_standardisation
```
Type: boolean
Default: false
Description: Determines whether to run Taxpasta for shotgun metagenomic samples
Help Text: Optional tool to standardise output from various taxonomic profiling tools.
```

- shotgun_profiling_standardisation_format
```
Type: string
Default: "tsv"
Valid Values: "tsv", "csv", "ods", "xlsx", "arrow", "parquet", "biom"
Description: Output format from Taxpasta
Help Text: Output format from Taxpasta
```

- shotgun_taxpasta_taxonomy
```
Type: string
Default: null
Description: Path to directory containing taxdump files
Help Text: Path to directory containing taxdump files
```

- shotgun_taxpasta_add_name
```
Type: boolean
Default: false
Description: Add taxon name to Taxpasta output
Help Text: Add taxon name to Taxpasta output
```

- shotgun_taxpasta_add_rank
```
Type: boolean
Default: false
Description: Add taxon rank to Taxpasta output
Help Text: Add taxon rank to Taxpasta output
```

- shotgun_taxpasta_add_lineage
```
Type: boolean
Default: false
Description: Add full taxon lineage to Taxpasta output - names
Help Text: Taxon names separated by semicolons
```

- shotgun_taxpasta_add_id_lineage
```
Type: boolean
Default: false
Description: Add full taxon lineage to Taxpasta output - IDs
Help Text: Taxon identifiers separated by semicolons
```

- shotgun_taxpasta_add_rank_lineage
```
Type: boolean
Default: false
Description: Add full taxon rank lineage to Taxpasta output
Help Text: Taxon ranks separated by semicolons
```

### Amplicon General Options

- amplicon_random_seed
```
Type: integer
Default: 66
Description: Random number seed used for certain processing tools.
Help Text: Can be left at the default value aside from very special circumstances.
```

- amplicon_paired_end_data
```
Type: boolean
Default: true
Description: Determines whether the pipeline processes incoming samples as paired-end data.
Help Text: Set to true for paired-end data and false for single-end data.
```

### Amplicon Pre-processing Options

- amplicon_do_cutadapt
```
Type: boolean
Default: true
Description: Determines whether cutadapt runs on incoming samples.
Help Text: Can be set to false for samples that have already been through the trimming and primer removal process.
```

- amplicon_minimum_read_count
```
Type: integer
Default: 1
Description: Minimum read count for a sample to be considered valid.
Help Text: Minimum read count for a sample to be considered valid.
```

- amplicon_forward_primer
```
Type: string
Description: Forward primer sequence
Help Text: Forward primer sequence
```

- amplicon_reverse_primer
```
Type: string
Description: Reverse primer sequence
Help Text: Reverse primer sequence
```

- amplicon_minimum_primer_overlap
```
Type: integer
Default: 3
Description: Minimum overlap to be considered a valid match with a primer sequence.
Help Text: This parameter corresponds to cutadapt's -O parameter.
```

- amplicon_maximum_primer_error_rate
```
Type: number
Default: .1
Description: Maximum error rate to be considered a valid match with a primer sequence.
Help Text: This parameter corresponds to cutadapt's -e parameter.
```

- amplicon_calculate_trunclen
```
Type: boolean
Default: true
Description: Determines whether the pipeline will automatically calculate the truncation length for read trimming and filtering.
Help Text: If this is true, the pipeline will calculate a truncation length based on the point at which the quality score drops below the amplicon_calculate_trunclen_quality_threshold parameter. If this is false, the pipeline will use the amplicon_trunclen_forward and amplicon_trunclen_reverse parameters.
```

- amplicon_calculate_trunclen_quality_threshold
```
Type: integer
Default: 20
Description: The minimum median quality score that will be used to calculate a truncation point for both forward and reverse reads.
Help Text: The minimum median quality score that will be used to calculate a truncation point for both forward and reverse reads.
```

- amplicon_trunclen_forward
```
Type: integer
Default: 0
Description: The number of bases after which forward reads will be truncated, to be used only if amplicon_calculate_trunclen is false.
Help Text: If set to 0, forward reads will not be truncated.
```

- amplicon_trunclen_reverse
```
Type: integer
Default: 0
Description: The number of bases after which reverse reads will be truncated, to be used only if amplicon_calculate_trunclen is false.
Help Text: If set to 0, reverse reads will not be truncated.
```

- amplicon_truncate_below_read_quality
```
Type: integer
Default: 2
Description: Truncate reads at the first instance of a quality score less than or equal to this value, corresponding to the truncQ parameter for DADA2's filterAndTrim function.
Help Text: Truncate reads at the first instance of a quality score less than or equal to this value, corresponding to the truncQ parameter for DADA2's filterAndTrim function.
```

- amplicon_trim_left
```
Type: integer
Default: 0
Description: The number of nucleotides to remove from the beginning of each read during DADA2's filterAndTrim function.
Help Text: The number of nucleotides to remove from the beginning of each read during DADA2's filterAndTrim function.
```

- amplicon_trim_right
```
Type: integer
Default: 0
Description: The number of nucleotides to remove from the end of each read during DADA2's filterAndTrim function.
Help Text: The number of nucleotides to remove from the end of each read during DADA2's filterAndTrim function.
```

- amplicon_maximum_length_before_trimming
```
Type: integer
Default: -1
Description: Maximum read length before trimming, corresponding to the maxLen parameter for DADA2's filterAndTrim function.
Help Text: A value of -1 will disable the parameter.
```

- amplicon_minimum_length_after_trimming
```
Type: integer
Default: 50
Description: Minimum read length after trimming, corresponding to the minLen parametr for DADA2's filterAndTrim function.
Help Text: Minimum read length after trimming, corresponding to the minLen parametr for DADA2's filterAndTrim function.
```

- amplicon_maximum_expected_error
```
Type: integer
Default: -1
Description: Maximum expected errors for a read to be kept after trimming, corresponding to the maxEE parameter for DADA2's filterAndTrim function.
Help Text: A value of 01 will disable the parameter.
```

- amplicon_abort_failed_preprocessing
```
Type: boolean
Default: false
Description: Determines whether the pipeline will abort when any samples fall below the amplicon_minimum_read_count parameter's threshold after preprocessing.
Help Text: When this parameter is set to true, the pipeline will abort. Otherwise, the pipeline will continue with samples whose read count is greater than amplicon_minimum_read_count.
```

### Amplicon ASV Inference Options

- amplicon_do_remove_chimeras
```
Type: boolean
Default: true
Description: Determines whether chimeric reads are removed.
Help Text: Removal of chimeric reads should only be skipped under very specific circumstances and with caution.
```

### Amplicon Taxonomic Classification Options

- amplicon_do_taxonomic_classification_dada2
```
Type: boolean
Default: false
Description: Determines whether taxonomic classification via DADA2 is performed.
Help Text: Determines whether taxonomic classification via DADA2 is performed.
```

- amplicon_taxonomic_classification_dada2_min_boot
```
Type: integer
Default: 50
Description: The minimum bootstrap confidence for assigning a taxonomic level.
Help Text: The minimum bootstrap confidence for assigning a taxonomic level.
```

- amplicon_do_taxonomic_classification_dada2_species
```
Type: boolean
Default: false
Description: Determines whether the DADA2 addSpecies function is included in taxonomic classification.
Help Text: Requires performing taxonomic classification via DADA2.
```

- amplicon_taxonomic_classification_species_multiple
```
Type: boolean
Default: false
Description: Determines whether dada2's addSpecies function is permitted to return multiple exact species-level matches for a given sequence.
Help Text: Setting this to false will return only unique matches, while true will return a comma-delimited list of exact matches.
```

- amplicon_do_taxonomic_classification_qiime2
```
Type: boolean
Default: true
Description: Determines whether taxonomic classification via QIIME 2 is performed.
Help Text: Determines whether taxonomic classification via QIIME 2 is performed.
```

### Amplicon Phylogenetic Placement Options

- amplicon_do_phylogenetic_placement
```
Type: boolean
Default: true
Description: Determines if phylogenetic placement is performed.
Help Text: Determines if phylogenetic placement is performed.
```

### Amplicon Taxa Filtering Options

- amplicon_taxa_to_exclude
```
Type: string
Description: List of taxa to exclude from downstream analysis.
Help Text: Comma-delimited list of terms to use for taxa filtering. Terms will be both fully and partially matched, can be any level of taxa, and should match the terminology used in your selected reference database.
```

- amplicon_minimum_abundance
```
Type: integer
Default: 1
Description: Minimum absolute abundance to remain in the feature table.
Help Text: A value of 1 will effectively disable the filter, while higher values will remove sequences with abundance counts under the threshold.
```

- amplicon_minimum_prevalence
```
Type: integer
Default: 1
Description: Minimum prevalence (or number of samples in which a taxon appears) to remain in the feature table.
Help Text: A value of 1 will effectively disable the filter, while higher values will remove sequences that appear in fewer samples than the threshold.
```

### Amplicon Analysis Options

- amplicon_do_rarefaction
```
Type: boolean
Default: true
Description: Determines whether rarefaction is performed before calculating diversity indices.
Help Text: Determines whether rarefaction is performed before calculating diversity indices.
```

- amplicon_rarefaction_minimum_sample_depth
```
Type: integer
Default: 500
Description: Minimum sampling depth to keep samples within the set.
Help Text: Minimum sampling depth to keep samples within the set.
```

- amplicon_taxonomy_for_analysis
```
Type: string
Default: "qiime2"
Valid Values: "qiime2", "dada2", ""
Description: Determines which tool's taxonomic classification to use for downstream analysis.
Help Text: Current options are qiime2 and dada2. Please ensure that you allow the taxonomic classifier of choice to run, or the pipeline will return an error. Leaving this blank will bypass all analysis steps.
```

- amplicon_do_export_sequences_absolute
```
Type: boolean
Default: true
Description: Determines whether an absolute abundance table of representative sequences is exported.
Help Text: Determines whether an absolute abundance table of representative sequences is exported.
```

- amplicon_do_export_sequences_relative
```
Type: boolean
Default: true
Description: Determines whether a relative abundance table of representative sequences is exported.
Help Text: Determines whether a relative abundance table of representative sequences is exported.
```

- amplicon_do_export_taxonomy_absolute
```
Type: boolean
Default: true
Description: Determines whether absolute abundance tables of taxonomic features are exported.
Help Text: Determines whether absolute abundance tables of taxonomic features are exported.
```

- amplicon_export_taxonomy_absolute_collapse_levels
```
Type: boolean
Default: "6"
Description: Determines what taxonomic levels the absolute abundance table is collapsed to for export. Provide a comma-delimited list of integers.
Help Text: Numeric values correspond to taxonomic tier from broadest (Kingdom = 1) to most specific (Species = 7). Selected levels need not be consecutive - for example a parameter of '2,4,6' would export tables collapsed to Phylum, Order, and Genus.
```

- amplicon_do_export_taxonomy_relative
```
Type: boolean
Default: true
Description: Determines whether relative abundance tables of taxonomic features are exported.
Help Text: Determines whether relative abundance tables of taxonomic features are exported.
```

- amplicon_export_taxonomy_relative_collapse_levels
```
Type: string
Default: "6"
Description: Determines what taxonomic levels the relative abundance table is collapsed to for export. Provide a comma-delimited list of integers.
Help Text: Numeric values correspond to taxonomic tier from broadest (Kingdom = 1) to most specific (Species = 7). Selected levels need not be consecutive - for example a parameter of '2,4,6' would export tables collapsed to Phylum, Order, and Genus.
```

- amplicon_do_export_taxonomy_barplot
```
Type: boolean
Default: true
Description: Determines whether QIIME 2's built-in barplot feature is used to generate a visualization of the taxonomy.
Help Text: Determines whether QIIME 2's built-in barplot feature is used to generate a visualization of the taxonomy.
```

- amplicon_do_alpha_diversity
```
Type: boolean
Default: true
Description: Determines whether alpha diversity is calculated and returned.
Help Text: Determines whether alpha diversity is calculated and returned.
```

- amplicon_alpha_diversity_metrics
```
Type: string
Default: "shannon,observed_features"
Description: Comma-delimited list of which metrics should be used to calculate alpha diversity.
Help Text: Please refer to https://docs.qiime2.org/2024.10/plugins/available/diversity/alpha/ for a full list of valid metrics.
```

- amplicon_do_alpha_diversity_phylogenetic
```
Type: boolean
Default: true
Description: Determines whether phylogenetic alpha diversity is calculated and returned.
Help Text: Determines whether phylogenetic alpha diversity is calculated and returned.
```

- amplicon_alpha_diversity_phylogenetic_metrics
```
Type: string
Default: "faith_pd"
Description: Comma-delimited list of which metrics should be used to calculate phylogenetic alpha diversity.
Help Text: Currently, faith_pd is the only available metric.
```

- amplicon_do_beta_diversity
```
Type: boolean
Default: true
Description: Determines whether beta diversity is calculated and returned.
Help Text: Determines whether beta diversity is calculated and returned.
```

- amplicon_beta_diversity_metrics
```
Type: string
Default: "braycurtis,jaccard"
Description: Comma-delimited list of which metrics should be used to calculate beta diversity.
Help Text: Please refer to https://docs.qiime2.org/2024.10/plugins/available/diversity/beta/ for a full list of valid metrics.
```

- amplicon_do_beta_diversity_phylogenetic
```
Type: boolean
Default: true
Description: Determines whether phylogenetic beta diversity is calculated and returned.
Help Text: Determines whether phylogenetic beta diversity is calculated and returned.
```

- amplicon_beta_diversity_phylogenetic_metrics
```
Type: string
Default: unweighted_unifrac,weighted_normalized_unifrac
Description: Comma-delimited list of which metrics should be used to calculate phylogenetic beta diversity.
Help Text: Please refer to https://docs.qiime2.org/2024.10/plugins/available/diversity/beta-phylogenetic/ for a full list of valid metrics.
```
