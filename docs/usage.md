# nf-core-bagobugs: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/bagobugs/usage](https://nf-co.re/bagobugs/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Multiple runs of the same sample

The `sample` identifiers have to be the same when you have re-sequenced the same sample more than once e.g. to increase sequencing depth. The pipeline will concatenate the raw reads before performing any downstream analysis. Below is an example for the same sample sequenced across 3 lanes:

```bash
sample,fastq_1,fastq_2
CONTROL_REP1,/FULL/PATH/TO/AEG588A1_S1_L002_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,/FULL/PATH/TO/AEG588A1_S1_L003_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A1_S1_L003_R2_001.fastq.gz
CONTROL_REP1,/FULL/PATH/TO/AEG588A1_S1_L004_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A1_S1_L004_R2_001.fastq.gz
```

### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet. The samplesheet can have as many columns as you desire, however, **there is a strict requirement for the first 3 columns to match those defined in the table below.**

A final samplesheet file consisting of both single- and paired-end data may look something like the one below (*remember to include the commas to specify third column is empty for single-end data*). This is for 6 samples, where `TREATMENT_REP3` has been sequenced twice.

```bash
sample,fastq_1,fastq_2
CONTROL_REP1,/FULL/PATH/TO/AEG588A1_S1_L002_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP2,/FULL/PATH/TO/AEG588A2_S2_L002_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A2_S2_L002_R2_001.fastq.gz
CONTROL_REP3,/FULL/PATH/TO/AEG588A3_S3_L002_R1_001.fastq.gz,/FULL/PATH/TO/AEG588A3_S3_L002_R2_001.fastq.gz
TREATMENT_REP1,/FULL/PATH/TO/AEG588A4_S4_L003_R1_001.fastq.gz,
TREATMENT_REP2,/FULL/PATH/TO/AEG588A5_S5_L003_R1_001.fastq.gz,
TREATMENT_REP3,/FULL/PATH/TO/AEG588A6_S6_L003_R1_001.fastq.gz,
TREATMENT_REP3,/FULL/PATH/TO/AEG588A6_S6_L004_R1_001.fastq.gz,
```

| Column         | Description                                                                                                                 |
|----------------|-----------------------------------------------------------------------------------------------------------------------------|
| `sample`       | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample.               |
| `fastq_1`      | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".  |
| `fastq_2`      | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".  |


An [example samplesheet](docs/test_samplesheet.csv) has been provided with the pipeline.

## Reference Databases

The bagobugs pipeline requires a set of databases that are queried during its execution. These should be automatically downloaded either the first time you use the tool (MetaPhlAn), or using specialised scripts (HUMAnN), or should be created by the user. Specifically, you will need:

> A FASTA file listing the adapter sequences to remove in the trimming step.
> TODO A FASTA file describing synthetic contaminants. TODO create fastq screen module to perform automatically for our pipelines
> TODO A FASTA file describing the contaminant (pan)genome. This file should be created by the users according to the contaminants present in their dataset and enviroment.
> TODO Bowtie2 DB if indexing database as part of pipeline - provide database for now...
> The Indexed MetaPhlAn database. This database has kindly been made accessible by the creator of the YAMP metagenomics nextflow pipeline and can be downloaded directly from [here](https://zenodo.org/record/4629921#.YMc87qhKg2x) (Note: this database is approximately 2GB in size)
> The ChocoPhlAn and UniRef databases for HUMAnN. Both can be downloaded directly by HUMAnN. Please refer to the [HUMANn3 user manual](https://github.com/biobakery/humann) for further details

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/bagobugs --input '/Full/Path/To/samplesheet.csv' -profile singularity
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core-bagobugs
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nibscbioinformatics/mf-core-bagobugs releases page](https://github.com/nibscbioinformatics/nf-core-bagobugs/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.


## Pipeline parameters

### `--input`

Use this to specify the Sample names and metadata, as well as the location of your input FastQ files. For example:

```bash
--input 'path/to/data/sample_data.csv'
```

Please note the following requirements:

1. The path must be enclosed in quotes, and it should refer to a comma separated .csv file
2. The csv must contain a header
3. The first column of the csv file should be `sample`
4. The second column of the csv file should be`fastq_1`
5. The third column of the csv file should be `fastq_2`

The input is always mandatory, unless you are running a test profile

### `--metaphlan_database`

Use this parameter to specify the full path to the directory containing local installation of the bowtie2-indexed MetaPhlAn 3 marker gene database (linked above)

```bash
--metaphlan_database = '/Data/metagenomics/metaphlan_databases'
```
Please note the following requirements:

1. The directory must contain the bowtie2-indexed database (`*.bt2 extension` ), rather than simply the database download
2. The database version must be `mpa_v30_CHOCOPhlAn_201901`. If you wish to use other versions of the metaphlan database the metaphlan3 `index` parameter must be adapted (see `tool-specific options` section below).

To downnload and decompress the database, please run:
```
wget https://zenodo.org/record/4629921/files/metaphlan_databases.tar.gz
tar -xzf metaphlan_databases.tar.gz
```

### `--adapters`

Use this parameter to specify the full path to the file containing the Illumina adapter sequences (fasta format). This adapters.fa file can be obtained from the [Unofficial BBTools github page](https://github.com/BioInfoTools/BBMap/tree/master/resources) but custom adapter fasta files will also work.

```bash
--adapters = '/Data/metagenomics/adapters.fa'
```

### `--chocophlan_database` (HUMMAnN3 only)

Use this parameter to specify the full path to the local installation of the chocophlan pangenome database. This path can specify either the complete or toy version of the chocophlan database database can be downloaded from the [HUMANN github page]()

```bash
--chocophlan_database = '/Data/metagenomics/humann_dbs_full/chocophlan'
```

Please note the following requirements:

1. The complete chocophlan database is very large (~17 GB) so please ensure you have sufficient storage space


### `--uniref_databas` (HUMMANn3 only)

Use this parameter to specify the full path to the local installation of the uniref database.


```bash
--uniref_database = '/Data/metagenomics/humann_dbs_full/uniref'
```
Please note the following requirements:

1. The complete chocophlan database is very large (34 GB) so please ensure you have sufficient storage space
2. *Note* The translated search against the uniref database of HUMANn3 can be skipped or a substituted for a alignment against a subset of the uniref protein database. Please see the [HUMANn3 user manual](https://github.com/biobakery/humann) for further details

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended.

* `docker`
  * A generic configuration profile to be used with [Docker](https://docker.com/)
  * Pulls software from Docker Hub: [`nfcore/bagobugs`](https://hub.docker.com/r/nfcore/bagobugs/)
* `singularity`
  * A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
  * Pulls software from Docker Hub: [`nfcore/bagobugs`](https://hub.docker.com/r/nfcore/bagobugs/)
* `conda`
  * Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter or Charliecloud.
  * A generic configuration profile to be used with [Conda](https://conda.io/docs/)
  * Pulls most software from [Bioconda](https://bioconda.github.io/)
* `test`
  * A profile with a complete configuration for automated testing
  * Includes links to test data so needs no other parameters

If you are running from within a NIBSC cluster, a *nibsc* profile is also available

* `nibsc`
  * uses singularity by default
  * sets the right mounts to run on NIBSC HPC cluster
  * uses *slurm* as tasks scheduler

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom Configuration
### Resource requests

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

Whilst these default requirements will hopefully work for most people with most data, you may find that you want to customise the compute resources that the pipeline requests. You can do this by creating a custom config file. For example, to give the workflow process `metaphlan_run` 32GB of memory, you could use the following config:

```nextflow
process {
  withName: metaphlan_run {
    memory = 32.GB
  }
}
```

To find the exact name of a process you wish to modify the compute resources, check the live-status of a nextflow run displayed on your terminal or check the nextflow error for a line like so: `Error executing process > 'METAPHLAN_RUN`. In this case the name to specify in the custom config file is `HUMANN`.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information.

### Tool-specific options

For the ultimate flexibility, we have implemented and are using Nextflow DSL2 modules in a way where it is possible to change tool-specific command-line arguments (e.g. providing an additional command-line argument to the `BBMAP_BBDUK` process) as well as publishing options (e.g. saving files produced by the `BBMAP_BBDUK` process that aren't saved by default by the pipeline). As this pipeline has been tailored to specific end-user requirements, it may be necessary to alter certain tools parameters to meet your requirements. In the majority of instances, as a user you won't have to change the default options set by the pipeline, however, there may be edge cases where creating a simple custom config file can improve the behaviour of the pipeline if for example it is failing due to a weird error that requires setting a tool-specific parameter to deal with smaller / larger genomes.

The command-line arguments passed to BBduk in the `BBMAP_BBDUK` module are a combination of:

* Mandatory arguments or those that need to be evaluated within the scope of the module, as supplied in the [`script`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/modules/nf-core/software/bbmap/bbduk/main.nf) section of the module file.

* An [`options.args`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) string of non-mandatory parameters that is set to default values for the module. These can be altered in the `conf/modules.config` file and used by the module in the sub-workflow / workflow context via the Nextflow `include` keyword and `addParams` Nextflow option [`see here`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/workflows/bagobugs.nf).

As mentioned at the beginning of this section it may also be necessary for users to overwrite the options passed to modules to be able to customise specific aspects of the way in which a particular tool is executed by the pipeline. Given that all of the default module options are stored in the pipeline's `modules.config` as a [`params` variable](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) it is also possible to overwrite any of these options via a custom config file.

Say for example we want to append an additional, non-mandatory parameter (i.e. `--remove-temp-output`) to the arguments passed to the `HUMANN` module. Firstly, we need to access the default `args` specified in the [`modules.config`](https://github.com/nibscbioinformatics/nf-core-bagobugs/blob/main/conf/modules.config) and edit the config file and add additional options you would like to provide.

As you will see in the example below, we have:

* appended `--remove-temp-output` to the default `args` used by the module.
* changed the default `publish_dir` value to where the files will eventually be published in the main results directory.


```nextflow
params {
    modules {
       'humann_run' {
            args           = "--remove-temp-output"
            publish_dir    = "new_humann3_results"

       }
    }
}
```

### Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

#### Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
