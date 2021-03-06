include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process HUMANN {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "biobakery::humann=3.0.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/humann:3.0.0--pyh5e36f6f_1"
    } else {
        container "quay.io/biocontainers/humann:3.0.0--pyh5e36f6f_1"
    }

    input:
    tuple val(meta), path(input)
    path chocophlan_db
    path uniref_db
    tuple val(meta), path(metaphlan_tb) // metaphlan abundance table output - restrict choocophlan pangenome analysis step to these genomes (should speed up?)

    output:
    tuple val(meta), path("*_HUMAnN.log")       ,                 emit: log
    tuple val(meta), path("*_genefamilies.tsv") , optional:true,  emit: genefamilies //if input type gene table (.biom etc) genefamilies.tsv wont be created and NF will throw error
    tuple val(meta), path("*_pathabundance.tsv"),                 emit: abundance
    tuple val(meta), path("*_pathcoverage.tsv") ,                 emit: coverage
    path "*.version.txt"                        ,                 emit: version

    script:
    def software        = getSoftwareName(task.process)
    def prefix     = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def metaphlan_table = metaphlan_tb ? "--taxonomic-profile $metaphlan_tb" : '' // need this input to bypass the methaphlan pre-screening and restrict further steps to these genomes (use metaphlan output)
    def input_format    = ("$input".endsWith(".fastq.gz")) ? "--input-format fastq.gz" :  ("$input".endsWith(".fasta")) ? "--input-format fasta.gz" : ("$input".endsWith(".tsv")) ? "--input-format genetable" : ("$input".endsWith(".biom")) ? "--input-format biom" : ("$input".contains(".sam")) ? "--input-format sam" : ("$input".contains(".bam")) ? "--input-format bam" : ''


    """
    humann \\
        --input $input \\
        $input_format \\
        $metaphlan_table \\
        --output . \\
        --output-basename ${prefix} \\
        $options.args \\
        --threads ${task.cpus} \\
        --nucleotide-database $chocophlan_db \\
        --protein-database $uniref_db \\
        --o-log ${prefix}_HUMAnN.log

    echo \$(humann --version 2>&1) | sed 's/^.*humann //; s/Using.*\$//' > ${software}.version.txt
    """
}
