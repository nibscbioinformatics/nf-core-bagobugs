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

ch_metaphlan_db = Channel.value(file("${params.metaphlan_database}", type:'dir', checkIfExists:true ))
ch_adapters = Channel.value(file("${params.adapters}", checkIfExists:true ))
ch_input = Channel.fromPath("${params.input}", checkIfExists:true )

// Check mandatory parameters
//if (!params.input) exit 1, 'Input samplesheet not specified!'
//if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
//if (params.adapters) { ch_adapters = file(params.adapters) } else { exit 1, 'Adapter file not specified!' }
//if (params.metaphlan_database) { ch_metaphlan_db = file(params.metaphlan_database) } else { exit 1, 'Metaphlan database not specified!' }

//if (!params.adapters) exit 1, 'No adapter files specified'
//if (!params.metaphlan_database) exit 1, 'No path for methaplan database supplied'

// Validate input parameters - TODO create sensible tests for workflow in schema doc
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
multiqc_options.args += params.multiqc_title ? " --title \"$params.multiqc_title\"" : ''

// Modules: local
include { GET_SOFTWARE_VERSIONS    }  from '../modules/local/get_software_versions'        addParams( options: [publish_files : ['csv':'']]    )
include { METAPHLAN3_RUN as METAPHLAN_RUN            } from '../modules/local/metaphlan3/run/main'           addParams( options: modules['metaphlan_run']       )

// Modules: nf-core/modules
include { FASTQC as FASTQC_RAW     } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_raw']            )
include { FASTQC as FASTQC_TRIMMED } from '../modules/nf-core/software/fastqc/main'       addParams( options: modules['fastqc_trimmed']        )
include { MULTIQC                  } from '../modules/nf-core/software/multiqc/main'      addParams( options: multiqc_options                  )
include { SEQTK_SAMPLE             } from '../modules/nf-core/software/seqtk/sample/main' addParams( options: modules['seqtk_sample']          )
include { BBMAP_BBDUK             }  from '../modules/nf-core/software/bbmap/bbduk/main'   addParams( options: modules['bbmap_bbduk']          )
include { CAT_FASTQ               }  from '../modules/nf-core/software/cat/fastq/main'   addParams( options: [:] )

// Subworkflows: local
include { INPUT_CHECK              } from '../subworkflows/input_check'    addParams( options: [:] )
include { CHECK_INPUT              } from '../subworkflows/check_input'           addParams( options: [:] )

////////////////////////////////////////////////////
/* --  Create channel for adapters & reference databases  -- */
////////////////////////////////////////////////////

// redundancy wiht what I created above - compare output and check

//if (params.metaphlan_database) {
  //  Channel
  //      .value(file( "${params.metaphlan_database}" ))
  //      .set { ch_metaphlan_db }
//} else {
 //   ch_metaphlan_db = Channel.empty()
//}

///if (params.adapters) {
   // Channel
     //   .value(file( "${params.adapters}" ))
       // .set { ch_adapters }
//} else {
  //  ch_adapters = Channel.empty()
//}

////////////////////////////////////////////////////
/* --           RUN MAIN WORKFLOW              -- */
////////////////////////////////////////////////////

// Info required for completion email and summary
def multiqc_report    = []

workflow BAGOBUGS {
    ch_software_versions = Channel.empty()

    /*
    * Read in sample sheet and stage inputs
    */

     INPUT_CHECK (
        ch_input
    )

    //CHECK_INPUT ()
    //ch_raw_short_reads = CHECK_INPUT.out.raw_short_reads

/*
=====================================================
        Preprocessing and QC for short reads
=====================================================
*/

    FASTQC_RAW (
        INPUT_CHECK.out.reads
    )
    ch_software_versions = ch_software_versions.mix(FASTQC_RAW.out.version.first().ifEmpty(null))

    BBMAP_BBDUK (
        INPUT_CHECK.out.reads,
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

// lets include this for Evette's work

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

    ch_software_versions = ch_software_versions.mix(METAPHLAN_RUN.out.version.first().ifEmpty(null))


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

    MULTIQC (
            ch_multiqc_config,
            ch_multiqc_custom_config.collect().ifEmpty([]),
            GET_SOFTWARE_VERSIONS.out.yaml.collect(),
            ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
        )
        multiqc_report = MULTIQC.out.report.toList()
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