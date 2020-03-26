#!/usr/bin/env nextflow
/*
Simply run nextflow pipeline as:
nextflow run main.nf --input "*fastq" --outdir output_folder
*/


/*
 * SET UP CONFIGURATION VARIABLES
*/
params.input = false
params.outdir = 'repeatexplorer'
params.fasta = "athaliana_tair10.fasta"
params.REPEXPLORER_PATH = "/home/superstar/rahul/000.softwares/repex_tarean/"



//input files
input_files = Channel
    .fromPath ( params.input )
    .map { [ "$it.baseName", file("$it") ] }
    .ifEmpty { exit 1, "Cannot find any input files matching: ${params.input}\nNB: Path needs to be enclosed in quotes!\n" }


// process fastqc {
//     tag "$name"
//     label 'env_small_snpcall'
//     publishDir "${params.outdir}/fastqc", mode: 'copy',
//         saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

//     input:
//     set val(name), file(reads) from read_files_fastqc

//     output:
//     file '*_fastqc.{zip,html}' into fastqc_results

//     script:
//     """
//     fastqc -q $reads
//     """
// }

process fastqc {
    tag "$name"
    label 'env_small_snpcall'
    publishDir "${params.outdir}/trimmed_fastq", mode: 'copy'

    input:
    set val(name), file(reads) from input_files

    output:
    file '*_fastqc.{zip,html}' into fastqc_results

    script:
    """
    fastqc -q $reads
    """
}



process repExplorer {
    tag "$name"
    publishDir "$params.outdir", mode: 'copy'

    input:
    set val(name), file(inter_fastq) from input_files

    output:
    file("cluster_out") into explorer_out

    script:
    """
    ${params.REPEXPLORER_PATH}/seqclust -p -c ${task.cpus} -r ${task.memory.toKilo()} -v cluster_out $inter_fastq
    """
}
