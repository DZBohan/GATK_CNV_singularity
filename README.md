# Singularity GATK CNV Pipeline

#### Bohan Zhang Dec. 6

## Index

- [1. Introduction of the Pipeline](#1)

	- [1.1 Preparation step](#1.1)

	- [1.2 CNV analysis step](#1.2)

- [2. Dependencies](#2)

- [3. Required Files List](#3)

	- [3.1 Project level files](#3.1)

	- [3.2 Sample level files](#3.2)

- [4. Files Editing & creation](#4)

	- [4.1 Bam files viewing](#4.1)

	- [4.2 Bed file editing](#4.2)

	- [4.3 Dictionary file editing](#4.3)

	- [4.4 bamIdsUniq file creation](#4.4)

- [5. Introduction of Scripts](#5)

	- [5.1 Preparation step](#5.1)

	- [5.2 CNV analysis step](#5.2)

- [6. Introduction of Results](#6)

	- [6.1 CNV result plots](#6.1)

	- [6.2 CNV result tables](#6.2)

## <h2 id="1">1. Introduction of the Pipeline</h2>

This pipeline uses eight GATK tools. Here are the GATK tools used.

* PreprocessIntervals
* AnnotateIntervals
* CollectReadCounts
* CreatReadCountPanelOfNormals
* DenoiseReadCounts
* CollectAllelicCounts
* ModelSegments
* PlotModeledSegments

Here is the official web page introducing the [GATK CNV analysis steps](https://gatk.broadinstitute.org/hc/en-us/articles/360035531092).

The pipeline is theoretically divided into two steps, the `preparation step`, and the `CNV analysis step`. Now, I am going to have a brief introduction to the steps first.

### <h2 id="1.1">1.1 Preparation step</h2>

Here is a flowchart of the preparation step. The wave shape stands for files, and the rectangle stands for tools.

![Prestep_flow](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/preflow.png?raw=true)

This step aims to generate the interval files, including a `.interval_list` file and a `intervals.tsv` file, which are needed in the following step.

### <h2 id="1.2">1.2 CNV analysis step</h2>

Here is also a flowchart of the CNV analysis step.

![CNA_flow](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/mainflow.png?raw=true)

In this step, you are first collecting the read counts of both the tumor bam file and the normal bam file and collecting allelic counts of both the bam files. Then, you are supposed to generate a panel using the normal bam file.

The denoised step is required before doing the CNV analysis. By doing the denoised step, you will get a more straightforward plot, which can help you know the CNV of a sample easier. The denoised step is also one of the advantages of the GATK CNV analysis process.

![Denoised](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/denoised.png?raw=true)

The next thing is the CNV analysis. You will use the ModelSegments tool to get the CNV results tables and the PlotModeledSegments tool to get the CNV results plots. The results tables and plots will be introduced in chapter 6.

## <h2 id="2">2. Dependencies</h2>

Singularity version 3.10.0.

Slurm system on a Linux machine.

These bash commands are used in this pipeline.

- export
- vim
- source

## <h2 id="3">3. Required Files List</h2>

### <h2 id="3.1">3.1 Project-level files</h2>

These five files are the same among different samples in one project.

* Bed file (file.bed)
* Reference FASTA file (reference.fa)
* Reference FASTA index file (reference.fai)
* Reference dictionary file (reference.dict)
* Bam ids uniq list file (bamIdsUniq.txt)

### <h2 id="3.2">3.2 Sample-level files</h2>

These four files are sample-specific.

* Tumor bam file (tumor.cram or bam) 
* Tumor bam index file (tumor.crai or bai)
* Normal bam file (normal.cram or bam)
* Normal bam index file (normal.crai or bai)

## <h2 id="4">4. Files Editing & creation</h2>

Using this pipline, you need to edit the bed file and the dictionary file, and you also need to creat a bamIdsUniq file. 

### <h2 id="4.1">4.1 Bam files viewing</h2>

The first step of editing the files is to view the bam files you are analyzing to see the format people are using to represent different chromosomes.

By the way, bam files and cram files are the same in this pipeline, so I will always say bam files to stand for both bam and cram files in this documentation.

First, clone the repository into a directory you want on your Linux server.

```
cd /path/to/the/directory/you/want

```

```
git clone https://github.com/DZBohan/Sequenza_singularity.git
```

Then, go into the directory storing scripts.

```
cd /path/to/the/directory/you/want/GATK_CNV_singularity/scripts
```

or

```
cd GATK_CNV_singularity/scripts
```

Now, you need to pull the GATK singularity image file in the current directory.

```
singularity pull --name gatk.sif docker://broadinstitute/gatk:latest
```

Use the following code to give singularity access to the directory where the bam files are located.

```
export SINGULARITY_BIND = /path/to/bam/directory
```

Use this command to view a bam file in the project.

```
singularity exec gatk.sif samtools view /path/to/bam/directory/file.bam
```
Here are the two examples of the bam files.

![Image1](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/bam_example_1.png?raw=true)

![Image2](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/bam_example_2.png?raw=true)

As you can see in the third column of the two examples, there are two ways, "1" and "chr1", to represent the chromosome 1. It is important to know how to represent the chromosome number in the bam files.

### <h2 id="4.2">4.2 Bed file editing</h2>
Now, let's view a bed file we want. It's OK if a bed file has some additional columns.

![Bed](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/bed.png?raw=true)

Two places in the bed file may need to be edited. First, The original bed file has several rows of header like this.

HEADER

In the main part of a bed file, there are several lines that are not located on chromosomes 1-22 or x and y. 

NOTCHRO

Therefore, you need to use the following commands to remove both the header and the lines not on normal chromosomes. 

If the chromsomnes in the main part of the bed file are represented by 'chr' plus numbers, use this command.

```
egrep "^chr[0-9XY]" file.bed > file_edit.bed
```
Use this command if the chromosome numbers are represented by numbers only.

```
egrep "^[0-9XY]" file.bed > file_edit.bed
```

Second, you have already known how the chromosome numbers are represented ('chr' plus numbers or numbers only) in the bam files of the project in chapter 3.1. 

Therefore, you need to unify the format of the chromosome numbers (the first column) of the bed file with the bam files.

Use vim to edit the bed file.

```
vim file_edit.bed
```

Inside the vim editor, use the following command to convert the first column of each line from 'chr' plus numbers to numbers only.

```
:%s/chr/
```

Use the following command to convert the first column of each line from numbers only to 'chr' plus numbers.

```
:%s/^/chr
```

### <h2 id="4.3">4.3 Dictionary file editing</h2>

Let us view a dictionary file first.

![Dict](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/dict.png?raw=true)

The editing of the dictionary file is the same as the bed file. First, remove the header and the lines that are not on chromosomes 1-22 or x and y.

If the chromsomnes in the main part of the bed file are represented by 'chr' plus numbers, use this command.

```
egrep "^@SQ SN:chr[0-9XY]" reference.dict > reference_edit.dict
```

Use this command if the chromosome numbers are numbers only.

```
egrep "^@SQ SN:[0-9XY]" reference.dict > reference_edit.dict
```

One important thing is when saving a new `reference_edit.dict` file, you must keep the original `reference.dict` file also in the same place along with the `reference.fa` file. Do not remove it.

Second, unify the format of the chromosome numbers (after the 'SN:') of the bed file with the bam files.

Use vim to edit the bed file.

```
vim file_edit.bed
```

Inside the vim editor, use the following command to convert the first column of each line from 'chr' plus numbers to numbers only.

```
:%s/chr/
```

Use the following command to convert the chromosome formats from numbers only to 'chr' plus numbers.

```
:%s/SN:/SN:chr
```

### <h2 id="4.4">4.4 BamIdsUniq file creation</h2>

Using this pipeline, you are required to create a `bamIdsUniq.txt` file. The file should have two columns. The first column is all the tumor bam file names, and the second column is all the normal bam file names. Use commas to separate two columns. Here is an example of what the file looks like. I recommend you to put the `bamIdsUniq.txt` file into the scripts directory, but you can also put it somewhere else.

![BamIdsUniq](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/bamidsuniq.png?raw=true)

## <h2 id="5">5. Introduction of Scripts</h2>

This GATK CNV analysis pipeline includes two Slurm scripts, `gatk_cnv_prepare.slurm` and `gatk_cnv.slurm`. Both scripts have config files, `config_gatk_cnv.txt` and `config_gatk_cnv_prepare.txt`, for inputting the variables or files. In addition, there is a Python annotation script, `CNV_annotation_script.py`, applied in the second Slurm script. You already got these scripts and congfig files when cloning the GitHub repository. You can find them in the script directory.

### <h2 id="5.1">5.1 Preparation step</h2>

The first step, also called the preparation step, is a project-level step since all samples share the same reference and bed files.

This step aims to generate two intermedia files, `targets.preprocessed.interval_list` and `annotated_intervals.tsv` for all samples in the next step.

You alread pull the GATK sigularity image file `gatk.sif` in the scripts directory in chapter 3.1, so you do not need to do it again unless you did not do the pulling step before.

For inputting the variables and files, you do not need to modify the script, `gatk_cnv_prepare.slurm`, but write them into the config file `config_gatk_cnv_prepare.txt`. Now, let us have a look at the config file.

Config_Prepare_new

There are four variables in this config file, `output_path`, `bed`, `refer`, and `home`. 

`output_path` is the path of a directory to store the output files, `targets.preprocessed.interval_list` and `annotated_intervals.tsv`. `bed` is the absolute path of the `file_edit.bed` file.

`refer` is the absolute path of the `reference.fa file`. One important thing is that you should put the `reference.fai` and `reference.dict` files in the same directory as the `reference.fa` file. 

`home` is the absolute path of a directory which we give singularity access to, so this directory must be the parent of the directory for all other variables. A easier way is to use the path of the home directory as the variable `home`.

After completing the config file, you can submit the Slurm script, `gatk_cnv_prepare.slurm`, to run the preparation step. 

```
sbatch --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=4GB --time=1:00:00 gatk_cnv_prepare.slurm
```

You can modify the memory, time, and other parameters, but they are usually enough in this step.

Now, you should have the two new files, `targets.preprocessed.interval_list` and `annotated_intervals.tsv`, in the target directory and be able to go to the next step.

### <h2 id="5.2">5.2 CNV analysis step</h2>

You can do the main step with the two newly generated intermedia files. This step contains a Slurm script `gatk_cnv.slurm`, a config file `config_gatk_cnv.txt`, and a Python script `CNV_annotation_script.py`.

Same as the preparation step, if you alread had the GATK singularity image file `gatk.sif` in the scripts directory, you do not need to pull it again.

For inputting the variables and files, you need to add them into the config file `config_gatk_cnv.txt`. Now, let's have a look at this file.

CONFIG_new

`BAMDIR` is the absolute path of the directory storing bam files. You need to put the set of bam files (bai files as well) in one directory.

`FILE` is the absolute path of the `bamIdsUniq.txt` file you create in chapter 3.5.

`intlist` and `inttsv` are the absolute path of the intermedia files `targets.preprocessed.interval_list` and `annotated_intervals.tsv` generated in chapter 5.1.

`refer` is the absolute path of the `reference.fa` file. One important thing is that you should put the `reference.fai` and `reference.dict` files in the same directory as the `reference.fa` file.

`output_path` is the absolute path of the directory for storing the GATK CNV pipeline outputs. Finally, there should be a set of directories named by the tumor bam file names in this directory. Inside individual directories, you can find the output files of each sample.

`dict` is the absolute path of the dictionary file `reference_edit.dict` you edit in chapter 3.3.

`home` is the absolute path of a directory which we give singularity access to, so this directory must be the parent of the directory for all other input directories or files. A easier way is to use the path of the home directory as the variable `home`.

`modelseg_mem` is the java memory requirement of the ModelSegments step, which usually requires larger memory. 70G of memory is usually enough for the general bam files, around 20G - 40G. However, larger java memory for this step is required for some large bam files, maybe larger than 50G. You can change the job partition into `largemem`, and set this parameter as 256G or larger. 

After completing the config file, you can submit the Slurm script, `gatk_cnv.slurm`, to run the main step.

```
sbatch --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=80GB --time=8:00:00 --array=[1-2]%2 gatk_cnv.slurm
```

The parameter of the array depends on the number of samples you want to do. In other word, the total number of the array is supposed to be the same as the number of rows in the `bamIdsUniq.txt` files. The details of `bamIdsUniq.txt` can be found in the chapter 3.5. For example, if you have 50 samples requiring CNV analysis, and you want to run five jobs each time, you are supposed to set the array parameter as `--array=[1-50]%5`.

I set the default value of the memory parameter as 80GB since the ModuleSegments step usually requires 70GB. If your sample's bam files are large, you may face an error called `java out of memory`. You can change the parameter of `partition` into `largemem`, and set the larger value of both `mem` parameter and the `modelseg_mem` variable inside the `config_gatk_cnv.txt` file. Here is an example of the large bams' jobs.

```
sbatch --partition=largemem --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=500GB --time=8:00:00 --array=[1-2]%2 gatk_cnv.slurm
```

It usually takes 2-5 hours to run the pipeline once, meaning if you set the array as `--array=[1-50]%5`, it will take 20-50 hours to run all 50 samples. After running the main step, you will get a set of directories, which are the same number as the samples, inside the output directory you set, and the name of each directory is supposed to be the same as the tumor bam's filename.

![Output1](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/output1.png?raw=true)

Inside each individual directory, there should be 12 files (five `.seg` files, two `.tsv` files, four `.param` files and a `.png` image).

Output2_new

This main step should have generated several intermedia files, but you cannot see them in the final results since I added a clean-up step in the script. Here I also list all intermedia files generated by this step in case you are interested in them.

```
tumor_bam_name_t.counts.hdf5
normal_bam_name_g.counts.hdf5
normal_bam_name_cnv.pon.hdf5
tumor_bam_name.standardizedCR.tsv
tumor_bam_name.denoisedCR.tsv
tumor_bam_name_t.allelicCounts.tsv
normal_bam_name_g.allelicCounts.tsv
```

## <h2 id="6">6. Introduction of Results</h2>

The results of the GATK CNV pipelilne can be divided into three categories, CNV plots, segment level CNV table, and gene level CNV table. First, let us have a look at the CNV plots.

### <h2 id="6.1">6.1 CNV result plots</h2>

Here is an example of the GATK pipeline CNV plots.

![CNV_plots](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/Sample1.modeled.png?raw=true)

You can finally get two plots from running the GATK pipeline on a set of tumor normal samples. The x-axis of both plots shows the different segments on different chromosomes. The y-axis of the first plot is `denoised copy ratio`. The y-axis of the second plot is `alternate allele fraction`.

For the color, the official webpage explained this. "Different copy ratio segments are indicated by alternating blue and orange color groups
The denoised median is drawn in thick black"

### <h2 id="6.2">6.2 CNV result tables</h2>

As I mentioned in chapter 5.2, the GATK CNV pipeline has 12 output files. The `.seg` files are the result tables you are looking for. There are five `.seg` files in total.

```
tumor_bam_filename.modelBegin.seg
tumor_bam_filename.modelFinal.seg
tumor_bam_filename.cr.seg
tumor_bam_filename.cr.igv.seg
tumor_bam_filename.af.igv.seg
```

The first two tables are the initial and final log2 copy ratio results before and after the segmentation step. Both have the log2 copy ratio results at different positions, 10, 50, and 90, so it is hard to get final readable results for these two files.

`tumor_bam_filename.cr.seg` and `tumor_bam_filename.cr.igv.seg` essentially include the same data，segments' position information, number of the probs and the mean value of log2 copy ratio, but the latter is more arrangeable and perfect being used for annotation. `tumor_bam_filename.af.igv.seg` has same format as `tumor_bam_filename.cr.igv.seg`, and the only difference is that the log2 copy ratio in the last column is replaced with the allele fraction.

Therefore, `tumor_bam_filename.cr.igv.seg` and `tumor_bam_filename.af.igv.seg` are the two more informative results. Here are the first ten rows of these two tables.

![Cr](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/cr.png?raw=true)

![Af](https://github.com/DZBohan/GATK_CNV_Pipeline/blob/main/images/af.png?raw=true)

