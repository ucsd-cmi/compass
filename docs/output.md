# ucsd-cmi/compass: Output

## Introduction

This document describes the output produced by the pipeline, broken down by tool. For information on including or excluding tools from the workflow, please see the [usage doc](usage.md). For details on any given tool's inner workings, please see its respective website.

## Output Structure

All directory paths below are relative to the main output directory.

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

### MultiQC

Regardless of pipeline parameters, MultiQC runs at the conclusion of every workflow instance and produces an HTML report, along with supporting data and visualizations, in the /multiqc directory.

### Pipeline Info

Separate from the tools used in the workflow, Nextflow produces output in the /pipeline_info directory including software versions, an execution report, a timeline, a diagram, and a logged parameters file.
