# nf-core/bagobugs: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* [FastQC](#fastqc) - Read quality control
* [BBDUK](#bbduk) - Adapter and quality trimming
* [Seqtk](#seqtk) - Read subsampling (250k)
* [MetaPhlAn3](#metaphlan3) - Taxonomic profiling
* [HUMANn3](#humann3) - Functional profiling
* [MultiQC](#multiqc) - Aggregate report describing results from the whole pipeline
* [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

## FastQC

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences.

For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

**Output files:**

* `results/QC/<fastqc_raw/fastqc_trimmed>`
  * `*_fastqc.html`: FastQC report containing quality metrics for your untrimmed raw fastq files.
* `fastqc/zips/`
  * `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.

## MultiQC

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarizing all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability.

For more information about how to use MultiQC reports, see [https://multiqc.info](https://multiqc.info).

**Output files:**

* `results/Summary/multiqc`
  * `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  * `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  * `multiqc_plots/`: directory containing static images from the report in various formats.

## BBDuk

[BBDUK](https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/) is an adapter and quality trimming tool that is a part of the Bbtools suite of bioinformatics tools. It combines most common data-quality-related trimming, filtering, and masking operations into a single high-performance tool. It is capable of quality-trimming and filtering, adapter-trimming, contaminant-filtering via kmer matching, sequence masking, GC-filtering, length filtering, entropy-filtering, format conversion, histogram generation, subsampling, quality-score recalibration, kmer cardinality estimation, and various other operations in a single pass.

**Output files**

* `results/QC/trimmed_reads/`
  * `*.fastq.gz` : trimmed/modified fastq reads
  * `*.log` : log file from the bbduk trimming process.

## Seqtk

[SEQTK](https://github.com/lh3/seqtk) is a fast and lightweight tool for processing sequences in the FASTA or FASTQ format. It seamlessly parses both FASTA and FASTQ files which can also be optionally compressed by gzip.


**Output files**

* `results/QC/subsampled_reads/`
  * `*.fastq.gz` : subsampled reads


## MetaPhlAn3

[METAPHLAN](https://github.com/biobakery/MetaPhlAn) is a computational tool for profiling the composition of microbial communities (Bacteria, Archaea and Eukaryotes) from metagenomic shotgun sequencing data.

**Output files**

* `results/Analysis/metaphlan3/`
  * `*_profile.tsv` : Tab-separated output file of the predicted taxon relative abundances (`merged_*_profile.tsv` are combined profiles from multiple samples)

## HUMAnN3

[HUMANN](https://github.com/biobakery/humann) is a pipeline for efficiently and accurately profiling the presence/absence and abundance of microbial pathways in a community from metagenomic or metatranscriptomic sequencing data (typically millions of short DNA/RNA reads). This process, referred to as functional profiling, aims to describe the metabolic potential of a microbial community and its members.

**Output files**

* `results/Analysis/humann3/`
  * `*_genefamilies.tsv` : File containing the abundances of each gene family in the community in reads per kilobase (RPK) units
  * `*_pathabundance.tsv` : File containing the abundances of each pathway in the community, also in RPK units as described for gene families
      pattern:
  * `*_pathcoverage.tsv` : File containing the pathway coverage
  * `*_log` : HUMAnN log file

* `results/Analysis/humann3/merged_profiles`
  * `merged_genefamilies-cpm.tsv` : File containing the combined normalised (cpm) abundances of each gene family in the community in reads per kilobase (RPK) units
  * `merged_pathabundance-cpm.tsv` : File containing the combined normalised (cpm) abundances of each pathway in the community, also in RPK units as described for gene families
      pattern:
  * `merged_pathcoverage-cpm.tsv` : File containing the normalised (cpm) combined pathway coverage

## Pipeline information

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

**Output files:**

* `pipeline_info/`
  * Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  * Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.csv`.
  * Documentation for interpretation of results in HTML format: `results_description.html`.
