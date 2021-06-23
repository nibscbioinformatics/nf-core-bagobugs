////////////////////////////////////////////////////
/* --         LOCAL PARAMETER VALUES           -- */
////////////////////////////////////////////////////

params.summary_params = [:]

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.adapters, params.metaphlan_database ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = Channel.fromPath("${params.input}", checkIfExists:true ) } else { exit 1, 'Input samplesheet not specified!' }
if (params.adapters) { ch_adapters = Channel.value(file("${params.adapters}", checkIfExists:true )) } else { exit 1, 'adapter.fa not specified!' }
if (params.metaphlan_database) { ch_metaphlan_db = Channel.value(file("${params.metaphlan_database}", type:'dir', checkIfExists:true )) } else { exit 1, 'Metaphlan database  not specified!' }

////////////////////////////////////////////////////
/* --          CONFIG FILES                    -- */
////////////////////////////////////////////////////

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

////////////////////////////////////////////////////
/* -- IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS-- */
////////////////////////////////////////////////////

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : '' // think this is needed for mutliqc??

// Modules: local
include { GET_SOFTWARE_VERSIONS                      } from '../modules/local/get_software_versions'        addParams( options: [publish_files : ['csv':'']]     )
include { METAPHLAN3_RUN as METAPHLAN_RUN            } from '../modules/local/metaphlan3/run/main'          addParams( options: modules['metaphlan_run']         )
include { MERGE_METAPHLAN_PROFILES                   } from '../modules/local/merge_metaphlan_profiles'     addParams( options: modules['merge_metaphlan_profiles']                            )
include { CONCATENATE_FASTA as MERGE_PAIRS           } from '../modules/local/concatenate_fasta'            addParams( options: modules['concatenate_fasta']     )
include { HUMANN as HUMANN_RUN                       } from '../modules/local/humann/main'                  addParams( options: modules['humann_run']            )
include { MERGE_HUMANN_OUTPUT                        } from '../modules/local/merge_humann_output'          addParams( options: modules['merge_humann_output']                              )
include { NORMALISE_HUMANN_OUTPUT                    } from '../modules/local/normalise_humann_output'      addParams( options: modules['normalise_humann_output']                              )

// Modules: nf-core/modules
include { FASTQC as FASTQC_RAW                       } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_raw']            )
include { FASTQC as FASTQC_TRIMMED                   } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_trimmed']        )
include { MULTIQC                                    } from '../modules/nf-core/software/multiqc/main'      addParams( options: multiqc_options                  )
include { SEQTK_SAMPLE                               } from '../modules/nf-core/software/seqtk/sample/main' addParams( options: modules['seqtk_sample']          )
include { BBMAP_BBDUK                                } from '../modules/nf-core/software/bbmap/bbduk/main'  addParams( options: modules['bbmap_bbduk']           )
include { CAT_FASTQ                                  } from '../modules/nf-core/software/cat/fastq/main'    addParams( options: modules['cat_fastq']                             ) // TODO. for Evettes work

// Subworkflows: local
include { INPUT_CHECK                                } from '../subworkflows/input_check'                   addParams( options: [:]                              )

////////////////////////////////////////////////////
/* --           RUN MAIN WORKFLOW              -- */
////////////////////////////////////////////////////

// Info required for completion email and summary
def multiqc_report    = []

workflow BAGOBUGS {
    ch_software_versions = Channel.empty()

/*
=====================================================
        Sample Check & Input Staging
=====================================================
*/

    INPUT_CHECK (
        ch_input
    )
    .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq_cat }

/*
=====================================================
        Combine Multirun Fastq
=====================================================
*/

    CAT_FASTQ (
        ch_fastq_cat.multiple
    )
    .mix(ch_fastq_cat.single)
    .set { ch_fastq }

/*
=====================================================
        Decontamination & Deduplication
=====================================================
*/

    // TODO

/*
=====================================================
        Preprocessing & QC
=====================================================
*/

    FASTQC_RAW (
        ch_fastq
    )
    ch_software_versions = ch_software_versions.mix(FASTQC_RAW.out.version.first().ifEmpty(null))

    BBMAP_BBDUK (
        ch_fastq,
        ch_adapters
    )
    ch_trimmed_reads = BBMAP_BBDUK.out.reads
    ch_software_versions = ch_software_versions.mix(BBMAP_BBDUK.out.version.first().ifEmpty(null))

    FASTQC_TRIMMED (
        ch_trimmed_reads
    )

    if (!params.skip_seqtk) {
        SEQTK_SAMPLE (
            ch_trimmed_reads,
            "${params.subsampling_depth}"
        )
        ch_processed_reads = SEQTK_SAMPLE.out.reads
        ch_software_versions = ch_software_versions.mix(SEQTK_SAMPLE.out.version.first().ifEmpty(null))
        } else {
            ch_processed_reads = BBMAP_BBDUK.out.reads
        }

/*
===================================================
        Taxonomic & Functional Classification
===================================================
*/
    // TODO metaphlan build/index DB option?

    METAPHLAN_RUN (
        ch_processed_reads,
        ch_metaphlan_db
    )
    ch_metaphlan_profiles = METAPHLAN_RUN.out.profile.collect{it[1]}
    ch_metaphlan_biom     = METAPHLAN_RUN.out.biom
    ch_software_versions  = ch_software_versions.mix(METAPHLAN_RUN.out.version.first().ifEmpty(null))


    MERGE_METAPHLAN_PROFILES (
        ch_metaphlan_profiles
    )

    if (!params.skip_humann) {
        // Check humann parameters
        ch_chocophlan_db = Channel.value(file("${params.chocophlan_database}", type:'dir', checkIfExists:true ))
        ch_uniref_db     = Channel.value(file("${params.uniref_database}", type:'dir', checkIfExists:true ))
        metaphlan_tb     = METAPHLAN_RUN.out.profile // limit chocophlan search to pangeonomes detected in metaphlan run

        MERGE_PAIRS (
            ch_processed_reads
        )
        ch_cat_reads = MERGE_PAIRS.out.joined_reads

        HUMANN_RUN (
            ch_cat_reads,
            ch_chocophlan_db,
            ch_uniref_db,
            metaphlan_tb
        )
        ch_software_versions  = ch_software_versions.mix(HUMANN_RUN.out.version.first().ifEmpty(null))

        // Combine humann output channels
        ch_merge_humann        = Channel.empty()
        ch_merge_humann        = ch_merge_humann.mix(HUMANN_RUN.out.genefamilies.collect{it[1]})
        ch_merge_humann        = ch_merge_humann.mix(HUMANN_RUN.out.abundance.collect{it[1]})
        ch_merge_humann        = ch_merge_humann.mix(HUMANN_RUN.out.coverage.collect{it[1]})

        MERGE_HUMANN_OUTPUT (
            ch_merge_humann
        )
        ch_norm_humann         = MERGE_HUMANN_OUTPUT.out

        NORMALISE_HUMANN_OUTPUT (
            ch_norm_humann
        )
    }

/*
==========================================
        Get Software Versions
==========================================
*/

    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )

/*
=============================
        MultiQC
=============================
*/
if (!params.skip_multiqc) {
    workflow_summary    = Workflow.paramsSummaryMultiqc(workflow, params.summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
            ch_multiqc_files.collect()
    )

    multiqc_report = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))

    }
}

////////////////////////////////////////////////////
/* --              COMPLETION EMAIL            -- */
////////////////////////////////////////////////////

workflow.onComplete {
    Completion.email(workflow, params, params.summary_params, projectDir, log, multiqc_report)
    Completion.summary(workflow, params, log)
}

////////////////////////////////////////////////////
/* --                  THE END                 -- */
////////////////////////////////////////////////////