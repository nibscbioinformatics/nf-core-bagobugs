// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process FASTQSCREEN {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::fastq-screen=0.14.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/fastq-screen:0.14.0--pl5262hdfd78af_1"
    } else {
        container "quay.io/biocontainers/fastq-screen:0.14.0--pl5262hdfd78af_1"
    }

    input:
    tuple val(meta), path(reads)
    path config_file

    output:
    tuple val(meta), path("*png")                   ,  optional:true, emit:  png
    tuple val(meta), path("*html")                  , emit: html
    tuple val(meta), path("*screen.txt")            , emit: report
    path("*.version.txt")          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def input    =  !meta.single_end ? "${reads[0]}" : "${reads}" // only use one of the read pairs as rtesults similiar (Babraham Institute )
    def version  = '0.14' // placeholder for now.. current version of singularity containers
    if (meta.single_end) {
    """
    fastq_screen \\
        $options.args \\
        --conf $config_file \\
        --threads $task.cpus \\
        $reads

    echo $version > ${software}.version.txt
    """
    } else {
    """
    fastq_screen \\
        $options.args \\
        --conf $config_file \\
        --threads $task.cpus \\
        ${reads[0]}

    fastq_screen \\
        $options.args \\
        --conf $config_file \\
        --threads $task.cpus \\
        ${reads[1]}

    echo $version > ${software}.version.txt
    """
    }

}
