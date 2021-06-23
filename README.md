# ![nf-core-bagobugs](docs/images/nf-core-bagobugs_logo.png)

**Metagenomics shotgun sequencing analysis pipeline**.

[![GitHub Actions CI Status](https://github.com/nf-core/bagobugs/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/bagobugs/actions)
[![GitHub Actions Linting Status](https://github.com/nf-core/bagobugs/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/bagobugs/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A520.04.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](https://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/bagobugs.svg)](https://hub.docker.com/r/nfcore/bagobugs)
[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23bagobugs-4A154B?logo=slack)](https://nfcore.slack.com/channels/bagobugs)

## Introduction

**nf-core/bagobugs** is a bioinformatics analysis pipeline for metagenomic shotgun sequencing data. The pipeline takes illumina fastq files as input, performs adapter and quality trimming, subsampling, and taxonomic and functional profiling using the biobakery tool suite (MetaPhlAn 3.0, HUMAnN 3.0)

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

1. Install [`Nextflow`](https://nf-co.re/usage/installation) (`>=20.04.0`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility _(please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_

3. Download the pipeline and test it on a minimal dataset with a single command.

    * **Please Note** Before running the pipeline you will need to download the relevant databases. Please see the [usage](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/dev/docs/usage.md) section of this guide for further information and download links

    ```bash
    ## clone pipeline into work directory
    git clone https://github.com/nibscbioinformatics/nf-core-bagobugs.git
    ## test pipeline to ensure it is working
    nextflow run nf-core-bagobugs -profile test,<docker/singularity/conda/institute>
    ```

    * Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.

    * **Note** For NIBSC HPC users, Franceso has created a `nibsc` profile for executing nextflow pipelines. This can be implemented using `-profile nibsc` at the command line.

    * If you are using singularity then the pipeline will auto-detect this and attempt to download the Singularity images directly as opposed to performing a conversion from Docker images. If you are persistently observing issues downloading Singularity images directly due to timeout or network issues then please use the `--singularity_pull_docker_container` parameter to pull and convert the Docker image instead. Alternatively, it is highly recommended to use the nf-core download command to pre-download all of the required containers before running the pipeline and to set the `NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir` Nextflow options to be able to store and re-use the images from a central location for future pipeline runs.

    * If you are using conda, it is highly recommended to use the `NXF_CONDA_CACHEDIR` or `conda.cacheDir` settings to store the environments in a central location for future pipeline runs.


4. Start running your own analysis!

> Typical command for full pipeline functionality (Taxonomic & Functional profiling)

    ```bash
    nextflow run nf-core-bagobugs -profile <docker/singularity/conda/nibsc> --input '/Full/Path/To/samplesheet.csv' --adapters '/Full/Path/To/adapters.fa' --metaphlan_database '/Full/Path/To/metaphlan_database_folder' --chocophlan_database = '/Full/Path/To/chocophlan_database_folder'  --uniref_database = '/Full/Path/To/uniref_database_folder'
    ```

> Typical command for functional profiling only (MetaPhlAn3 only)

    ```bash
    nextflow run nf-core-bagobugs -profile <docker/singularity/conda/institute> --input '/Full/Path/To/samplesheet.csv' --adapters '/Full/Path/To/adapters.fa' --metaphlan_database '/Full/Path/To/metaphlan_database_folder' --skip_humann
    ```

See [usage docs](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/dev/docs/usage.md) for all of the available options when running the pipeline.

## Pipeline Summary

By default, the pipeline currently performs the following:


* Sequencing quality control (`FastQC`)
* Adapter and base quality trimming (`BBDuk`)
* Read subsampling (`Seqtk`)
* Taxonomic Profiling (`MetaPhlAn3`)
* Combine MetaPhlAn3 profiles (`merge_metaphlan_profiles`)
* Merge paired reads for HUMaNN3 input (`concatenate fastq`)
* Functional Profiling (`HUMAnN3`)
* Merge HUMAnN3 output profiles (`merge_humann_output`)
* Normalise HUMAnN3 output (`normalise_human_output`)
* Overall pipeline run summaries (`MultiQC`)

## Documentation

The nf-core/bagobugs pipeline comes with documentation about the pipeline: [usage](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/dev/docs/usage.md) and [output](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/dev/docs/output.md).
**Detailed information about how to specify the input can be found under input specifications.**
## Credits

nf-core/bagobugs was originally written by Martin Gordon & Ravneet Bhuller.
## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#bagobugs` channel](https://nfcore.slack.com/channels/bagobugs) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nf-core/bagobugs for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

In addition, references of tools and data used in this pipeline are as follows:

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->
