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

// Cloned Repeat Explorer 2 in March, 2020 
// URL: git clone git@bitbucket.org:rbpisupati/repex_tarean.git
params.REPEXPLORER_PATH = "/home/superstar/rahul/000.softwares/repex_tarean/"



// Fastq sampling, filtering options
params.sample_fastq = 1000000 // 1 million reads
params.min_quality = 30 //


//input fastq paired files
input_files = Channel
    .fromFilePairs ( params.input )
    .ifEmpty { exit 1, "Cannot find any input files matching: ${params.input}\nNB: Path needs to be enclosed in quotes!\n" }


process filteringFastq {
    tag "$name"
    publishDir "${params.outdir}/sampledFastq", mode: 'copy'

    input:
    set val(name), file(reads) from input_files

    output:
    set val(name), file("${name}.filtered.fas") into interleaved_fastq
    file("${name}.filtered.png") into out_inter_png

    script:
    num_reads = params.sample_fastq / 2
    """
    seqtk sample -s100 ${reads[0]} $num_reads > ${name}.sample.1.fq
    seqtk sample -s100 ${reads[1]} $num_reads > ${name}.sample.2.fq

    ${params.REPEXPLORER_PATH}/re_utilities/paired_fastq_filtering_wrapper.sh \
    -a ${name}.sample.1.fq  -b ${name}.sample.2.fq \
    -c $params.min_quality \
    -G ${name}.filtered.png \
    -N 0 -R -o ${name}.filtered.fas
    """
    // fastq_quality_filter -Q33 -q $params.min_quality -i ${name}.sample.1.fq -o ${name}.qual.sampled.1.fq
    // fastq_quality_filter -Q33 -q $params.min_quality -i ${name}.sample.2.fq -o ${name}.qual.sampled.2.fq
}


process repExplorer {
    tag "$name"
    publishDir "$params.outdir", mode: 'copy'

    input:
    set val(name), file(inter_fastq) from interleaved_fastq

    output:
    file("re_${name}") into explorer_out

    script:
    """
    ${params.REPEXPLORER_PATH}/seqclust -p \
    -c ${task.cpus} -r ${task.memory.toKilo()} \
    -v re_${name} $inter_fastq
    """
}
