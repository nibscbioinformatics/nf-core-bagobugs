// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CONCATENATE_FASTA {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*_joined.fastq.gz'), emit: joined_reads

   // when:
	// !meta.singleEnd // can't include when in script for submission to nf-core but should work well locally (maybe move to nf-script)
    //     cat ${reads[0]} ${reads[1]} >  ${prefix}_joined.fastq.gz


    script:
    def prefix     = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    cat $reads >  ${prefix}_joined.fastq.gz
    """
}