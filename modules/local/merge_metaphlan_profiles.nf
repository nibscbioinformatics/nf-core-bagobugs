// Import generic module functions
include { saveFiles } from './functions'

params.options = [:]

process MERGE_METAPHLAN_PROFILES {
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'pipeline_info', publish_id:'') }

    conda (params.enable_conda ? "bioconda::metaphlan=3.0.9" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/metaphlan:3.0.9--pyhb7b1952_0"
    } else {
        container "quay.io/biocontainers/metaphlan:3.0.9--pyhb7b1952_0"
    }

    input:
    path profiles

    output:
    path '*.tsv', emit: txt


    script:  // This script is bundled with the metaphlan3 tool
    """
    merge_metaphlan_tables.py  $profiles > merged_metaphlan_profiles.tsv
    """
}