////////////////////////////////////////////////////
/* --         LOCAL PARAMETER VALUES           -- */
////////////////////////////////////////////////////

params.summary_params = [:]

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.adapters, params.metaphlan_database ] //add back  params.multiqc_config,
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = Channel.fromPath("${params.input}", checkIfExists:true ) } else { exit 1, 'Input samplesheet not specified!' }
if (params.adapters) { ch_adapters = Channel.value(file("${params.adapters}", checkIfExists:true )) } else { exit 1, 'Adapter file not specified!' }
if (params.metaphlan_database) { ch_metaphlan_db = Channel.value(file("${params.metaphlan_database}", type:'dir', checkIfExists:true )) } else { exit 1, 'Metaphlan database not specified!' }

// TODO create sensible tests for workflow
// Validate input parameters
// Workflow.validateWorkflowParams(params, log)

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
include { GET_SOFTWARE_VERSIONS                      } from '../modules/local/get_software_versions'                          addParams( options: [publish_files : ['csv':'']]    )
include { METAPHLAN3_RUN as METAPHLAN_RUN            } from '../modules/local/metaphlan3/run/main'           addParams( options: modules['metaphlan_run']       )
include {MERGE_METAPHLAN_PROFILES                    } from '../modules/local/merge_metaphlan_profiles'      addParams( options: [:] )

// Modules: nf-core/modules
include { FASTQC as FASTQC_RAW                       } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_raw']            )
include { FASTQC as FASTQC_TRIMMED                   } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_trimmed']        )
include { MULTIQC                                    } from '../modules/nf-core/software/multiqc/main'      addParams( options: multiqc_options                  )
include { SEQTK_SAMPLE                               } from '../modules/nf-core/software/seqtk/sample/main' addParams( options: modules['seqtk_sample']          )
include { BBMAP_BBDUK                                } from '../modules/nf-core/software/bbmap/bbduk/main'   addParams( options: modules['bbmap_bbduk']          )
include { CAT_FASTQ                                  } from '../modules/nf-core/software/cat/fastq/main'   addParams( options: [:] )

// Subworkflows: local
include { INPUT_CHECK                                } from '../subworkflows/input_check'    addParams( options: [:] )

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
    .map { // repeat function on each instance
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_') // for name (taken from sample col) split on '_'
            [ meta, fastq ] }
    .set { ch_fastq }

// for  samples across different runs... see Evette cat fastq step.. test this and incorporate

 //      .groupTuple(by: [0]) // group by sample name
 //   .branch { // is this creating an additional meta for if the sample has been prepared on individual or multiple sequencing
 //       meta, fastq ->
 //           single  : fastq.size() == 1
 //               return [ meta, fastq.flatten() ]
 //           multiple: fastq.size() > 1
 //               return [ meta, fastq.flatten() ]
 //   }
 //   .set { ch_fastq }


/*
=====================================================
        Preprocessing and QC for short reads
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

    SEQTK_SAMPLE (
        ch_trimmed_reads,
        250000
    )
    ch_subsampled_reads = SEQTK_SAMPLE.out.reads
    ch_software_versions = ch_software_versions.mix(SEQTK_SAMPLE.out.version.first().ifEmpty(null))

// will try correclty include this for Evette's work

 //   CAT_FASTQ (
 //       ch_subsampled_reads
 //   )
 //   ch_merged_reads = CAT_FASTQ.out.reads

/*
===================================================
        Taxonomic Classification
===================================================
*/

// here can try if statement; if db ch not null do this, else build metaphlanDB and use output as input here (look at mag)

    METAPHLAN_RUN (
        ch_subsampled_reads,
        ch_metaphlan_db
    )
    ch_metaphlan_profiles = METAPHLAN_RUN.out.profile.collect{it[1]}
    ch_software_versions = ch_software_versions.mix(METAPHLAN_RUN.out.version.first().ifEmpty(null))


    MERGE_METAPHLAN_PROFILES (
        ch_metaphlan_profiles
    )

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