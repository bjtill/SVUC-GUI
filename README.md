# SVUC-GUI
Significant Variants Unique to Cases, Graphical Interface Version. A tool to compare DNA sequence variants in one or more multi-sample VCF files, and report those variants unique to, or statistically significant in, case samples when compared to controls. 
_________________________________________________________________________________________________________________________________________________
Use at your own risk. I cannot provide support. All information obtained/inferred with this script is without any implied warranty of fitness for any purpose or use whatsoever.

ABOUT:  

One approach to finding DNA sequence variants that are potentially causative for phenotypic differences between samples is to compare variants from a multi-sample variant call format (VCF) file.  The simplest approach is to identify variants common to all of the “case” individuals that express the phenotype and never present in the “control” samples that do not express the phenotype (this is termed “absolute” filtering in this program).  An alternative approach is to use different statistical models (e.g. recessive or dominant) to identify variants that are significantly associated with the case samples (this is termed “casecontrol” ) .  SVUC supports up to three input VCFs, typically created using different callers.  Analysis is performed on individual VCFs and also the set of variants that are common to all supplied VCFs.  Variants found in common are considered higher confidence.  In addition, candidate variants are functionally annotated with SnpEff, and a human-readable table of annotated variants is produced (https://pcingola.github.io/SnpEff/adds/SnpEff_paper.pdf).  

INPUTS: 

1. Up to three multi-sample VCF files (compressed with bgzip and indexed with tabix).  VCFs should contain the same samples with exactly the same sample name.
2. A snpEff genome database for the reference genome used in the creation of the VCF files. 
3. A two column plain text file that contains the sample names in column 1 and the status in column 2, where - is used for control, + for case and 0 for neutral.  
4. P-value thresholds for various statistical case-control tests. If multiple tests are selected (by chaning the number from zero), then any variants passing at least one test will be reported. 
5. A variety of parameters for generating a Venn diagram when more than 1 VCF is selected for analysis.

OUTPUTS:

1. SnpEff annotated VCFs containing significant variants from each chosen input VCF (both absolute and statistical modes).  SnpEff output genes.txt and html reports for each VCF.
2. An annotated VCF of significant variants common to all input VCFs.  SnpEff output genes.txt and html reports for each VCF.  
3. A human-readable table of significant annotated variants (both absolute and casecontrol). 
4. Venn diagrams, when more than one VCF chosen, of significant variants from all input VCFs, along with data tables used to produce the diagrams (both absolute and casecontrol).
5. A log file that records the various inputs and parameters used.

REQUIREMENTS:  

Bash, Zenity, YAD, java, curl, perl, snpSift, snpEff, grep, awk, R, ggplot2(R), VennDiagram(R)

TO RUN:

This program was built to run on Linux and tested on Ubuntu 20.04 and 22.04.  In theory it can be run on macOS by installing the various dependencies (e.g. using Homebrew). However, I experienced issues installing YAD.  Zenity installed okay, and so one could convert the YAD inputs to Zenity, or create a command line version.  No testing has been done with Windows and a Bash emulator.  

Download the .sh file and give it permission to run on your computer.  Open a Linux terminal and type chmod +x SVUC_V2.sh (or whatever the file is called).  Launch by typing ./SVUC_V2.sh .  You will first be prompted to create a directory name.  This directory will be created in the location you are running the program, and the analysis will be carried out in this directory.  Once complete, a new window will appear where you will  select the VCF files and various other parameters.  If you provide more than one VCF, another window will appear that allows you to modify the Venn diagram parameters.  
