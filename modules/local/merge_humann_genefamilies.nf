include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MERGE_HUMANN_GENEFAMILIES {
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
    // path profiles... only way I can think of doing this is merge all toght
    path genefamilies
    //path pathabundance
    //path pathcoverage

    output:
    path '*.tsv', emit: tsv
    //path 'merged_pathabundance.tsv'
    //path 'merged_pathcoverage.tsv'
      //  -i  $genefamilies \\

    script:  // This script is bundled with the humann3 tool
    """
    humann_join_tables \\
    -i  . \\
    --output merged_gfamilies.tsv \\
    --file_name genefamilies
    """
}

