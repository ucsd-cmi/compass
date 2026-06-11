# ucsd-cmi/compass: Output

## Introduction

This document describes the output produced by the pipeline, broken down by tool. For information on including or excluding tools from the workflow, please see the [usage doc](usage.md). For details on any given tool's inner workings, please see its respective website.

## Output Structure - Shotgun Samples

All directory paths below are relative to the main output directory for shotgun data.

### FastQC

Regardless of pipeline parameters, FastQC will run once as the first step in the workflow, evaluating the raw FASTQ files included in the run. The FastQC reports for this instance will be in /fastqc/raw, with each FASTQ file having a report named {sample_id}_{run_id}\_raw\_{1|2}_fastqc.{html|zip}.

If you opt to run preprocessing, FastQC will run a second time after fastp, evaluating the preprocessed instances of the FASTQ files. These reports will be in /fastqc/trimmed, with each FASTQ file having a report named {sample_id}_{run_id}\_trimmed\_{1|2}_fastqc.{html|zip}.

### fastp

If you opt to run preprocessing, fastp will perform trimming and read filtering and yield the following files in the /fastp directory:
- {sample_id}\_{run_id}.fastp.{html|json|log} - Logging and reporting in a variety of formats
- {sample_id}\_{run_id}\_R{1|2}.fastp.fastq.gz - The trimmed, filtered, and unmerged reads
- {Sample_id\_{run_id}}.merged.fastq.gz - The trimmed, filtered, and successfully merged reads

### Bowtie2

If you opt to run host removal, Bowtie2 will produce the following files for each sample included in a run, all in the /bowtie2 directory:
- {sample_id}\_{run_id}.bam - A sorted BAM file with the results of alignment against the reference genome
- {sample_id}\_{run_id}.bowtie2.log - A log file containing alignment statistics for the given sample
- {sample_id}\_{run_id}.unmapped\_{1|2}.fastq.gz - FASTQ files containing unaligned reads

### SAMtools

If you opt to run host removal, SAMtools will produce the following output in the /samtools directory:
- {sample_id}\_{run_id}\_{1|2}.fastq.gz - FASTQ file containing reads with the READ1/READ2 FLAG set
- {sample_id}\_{run_id}\_other.fastq.gz - FASTQ file containing reads where either both or neither of the READ1 and READ2 FLAGs are set
- {sample_id}\_{run_id}\_singleton.fastq.gz - FASTQ file containing any singletons found in the sample
- {sample_id}\_{run_id}.bam.bai - An index file for a coordinate-sorted BAM file
- {sample_id}\_{run_id}.stats - A file containing stats from samtools
- {sample_id}\_{run_id}.unmapped.bam - BAM file containing reads that did not map to the host in Bowtie2

### SeqKit

If you opt to do read pairing, SeqKit will produce the following output in the /seqkit directory:

- {sample_id}\_{run_id}\_{1|2}.paired.fastq.gz - FASTQ files with singletons filtered out.

### Kraken2

If you opt to run Kraken2, the following output will appear in the /kraken2 directory. {prefix} is conditional on whehter you opted to do run-merging. If you did, {prefix} will be equivalent to {sample_id}. If you did not, {prefix} will be equivalent to {saaple_id}\_{run_id}:

- {prefix}.classified\_{1|2}.fastq.gz - FASTQ files containing reads that Kraken2 was able to classify using the selected reference database
- {prefix}.kraken2.classifiedreads.txt - A full list of the read IDs the mappings they each had against the reference database
- {prefix}.kraken2.report.txt - A summary report containing fractional abundance for classified taxa
- {prefix}.unclassified\_{1|2}.fastq.gz - FASTQ files containing reads that Kraken2 was unable to classify

### Bracken

If you opt to run Bracken, the following output will appear in the /bracken directory, using the same {prefix} conditions as Kraken2:

- {prefix}.kraken2.report_bracken.txt - A summary report of Bracken output
- {prefix}.tsv - A TSV file containing the full Bracken output for the sample

### TAXPASTA

If you opt to run profiling standardisation, the following output will appear in the /taxpasta directory, using the same {prefix} conditions as Kraken2 and Bracken:

- bracken_{prefix}.tsv - If you opted to run Bracken, this will be the reformatted Bracken output
- kraken2_(prefix).tsv = If you opted to run Kraken2, this will be the reformatted Kraken2 output

## Output Structure - Amplicon Samples

### FastQC

Regardless of pipeline parameters, FastQC will run once as the first step in the workflow, evaluating the raw FASTQ files included in the run. The FastQC reports for this instance will be in /fastqc/raw, with each FASTQ file having a report named {sample_id}_{run_id}\_raw\_{1|2}_fastqc.{html|zip}.

If you opt to run Cutadapt, FastQC will run a second time after fastp, evaluating the preprocessed instances of the FASTQ files. These reports will be in /fastqc/trimmed, with each FASTQ file having a report named {sample_id}_{run_id}\_trimmed\_{1|2}_fastqc.{html|zip}.


### Cutadapt

If you opt to run Cutadapt, the following output will appear in the /cutadapt directory:

- Trimmed reads for each sample with a name of {sample_id}_{run_id}_{1|2}.trim.fastq.qz
- A report for each sample with a name of {sample_id}_{run_id}.cutadapt.log

### DADA2

DADA2 is used for multiple, distinct steps throughout the pipeline and will create output for many of them, some of which are conditional.

DADA2 runs quality profiling on the aggregated reads for a processing run, either broken into groups for forward and reverse reads, or one group in the case of single-end data. The quality profiling steps runs both before reads are filtered and trimmed, and outputs the following into /dada2/quality_profile:

- {forward|reverse|single_end}\_pre\_quality\_stats\_mqc.png which is a graph for the reads before filtering and trimming
- {forward|reverse|single_end}\_post\_quality\_stats\_mqc.png which is a graph for the reads after filtering and trimming

The DADA2 filtering and trimming function (filterAndTrim) will store a copy of the trimmed reads in /dada2/filtered_and_trimmed_reads .

During the ASV inference process, DADA2 will output the following:

- An error model visualization will be exported to /dada2/error_model
- The denoising function will export transient R objects to /dada2/denoise - these don't have any specific value outside of continuing the pipeline, but are included as transient output

Once chimeric reads are removed and all of the run_ids are re-merged, comprehensive output for the processing run will be exported to /dada2:

- full\_asv\_table.rds will be an R object with the ASV table
- full\_asv\_table.tsv will be a spreadsheet representation of the ASV table
- full\_asv\_table\_with\_sequences.tsv will be a spreadsheet representation of the ASV table, including the actual sequences
- asv\_sequences.fasta will be a fasta file containing only the ASV sequences

If DADA2 is used for classifying taxonomy (and optionally, adding species), it will export one more file to /dada2:

- taxonomy.tsv will contain a table with the asv_id (an md5 hash of the actual sequence) and the corresponding taxonomic classification

### Phylogenetic Placement with SEPP (via QIIME 2)

If you opt to run phylogenetic placement, it will export the following output to /qiime2/sepp:

- tree.qza, a QIIME 2 object containing the phylogenetic tree with inserted feature data
- placements.qza, a QIIME 2 object containing feature placement information
- filtered_table.qza, a QIIME 2 object representing the feature table with entries removed that were not successfully inserted into the phylogenetic table

### QIIME 2

If you opt to use QIIME 2 for taxonomic classification, it will output two files in /qiime2/taxonomy:

- taxonomy.qza, a QIIME 2 object containing the taxonomic table - this is mostly used for the rest of the pipeline, but can also be used in QIIME 2 as a user sees fit
- taxonomy.tsv, a spreadsheet representation of the taxonomic table

At the analysis phase of the pipeline, each of the following modules will populate these directories:

- Exporting absolute taxonomy abundance tables will place .tsv files in /qiime2/taxonomy_absolute, with one file per taxonomic tier, corresponding to the parameters you provided
- Exporting relative taxonomy abundance tables will place .tsv files in /qiime2/taxonomy_relative, with one file per taxonomic tier, corresponding to the parameters you provided
- Exporting absolute sequence abundance tables will place feature_table.biom and feature_table.tsv in /qiime2/sequences_absolute
- Exporting relative sequence abundance tables will place asv_relative_abundance.tsv in /qiime2/sequences_relative
- Calculating alpha diversity and/or phylogenetic beta diversity will place one .tsv file for each metric selected in /qiime2/alpha_diversity
- Calculating beta diversity and/or phylogenetic beta diversity will place one .tsv file for each metric selected in /qiime2/beta_diversity
- Rendering a barplot of taxonomic abundance will place the barplot and its supporting data in /qiime2/barplot

## MultiQC

Regardless of pipeline parameters, MultiQC runs at the conclusion of every workflow instance and produces an HTML report, along with supporting data and visualizations, in the /multiqc directory. Please note, the MultiQC report includes a dynamic citation list, but does not currently include citations for reference databases used during the pipeline execution. Please ensure you're citing all of the reference databases you utilize. This note will be updated when the MultiQC report has been adjusted to auotmatically include data citations.

## Pipeline Info

Separate from the tools used in the workflow, Nextflow produces output in the /pipeline_info directory including software versions, an execution report, a timeline, a diagram, and a logged parameters file.
