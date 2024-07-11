#!/bin/bash
#Started Feb 1, 2024, BT
#Version 2.0 first tested stable version with case-controls for distribution (July 3, 2024)
zenity --width 1000 --info --title "Significant Variants Unique to Cases - SVUC" --text "
Version 2

ABOUT: 
A GUI tool for using snpSift and snpEff to find and annotate variants in case/control comparisons that are significant to cases.  Two modes are used: absolute correlation and statistical model.  In absolute mode, only variants unique to all cases and never found in any control are reported. Statistical mode provides the choice of one (or more) of 5 statistical case-control tests (see https://pcingola.github.io/SnpEff/snpsift/casecontrol/ for more details). This tool accepts up to three VCFs, and when 2 or more VCFs selected, a venn diagram is produced of variants unique and common to the different callers. 

INPUTS: 
1. Up to three multi-sample VCF files (compressed with bgzip and indexed with tabix).  VCFs should contain the same samples with exactly the same sample name.
2. A snpEff genome database for the reference genome used in the creation of the VCF files. 
3. A two column plain text file that contains the sample names in column 1 and the status in column 2, where - is used for control, + for case and 0 for neutral.  
4. P-value thresholds for various statistical case-control tests. If multiple tests are selected (by chaning the number from zero), then any variants passing at least one test will be reported. 
5. A variety of parameters for generating a Venn diagram when more than 1 VCF is selected for analysis.      

OUTPUTS:
1. SnpEff annotated VCFs containing significant variants from each chosen input VCF (both absolute and statistical modes).  
2. An annotated VCF of significant variants common to all input VCFs.  SnpEff output genes.txt and html reports for each VCF.  
3. A human-readable table of significant annotated variants. 
4. A venn diagram, when more than one VCF chosen, of significant variants from all input VCFs.
5. A log file that records the various inputs and parameters used.  

WARNINGS: Paths to VCF files should not contain spaces or the symbols / or $.  For example, it is okay if your VCFs are on an external USB drive named My_Drive, but if your drive is named My Drive, /MyDrive, etc., the program may not find your files. 

Venn diagrams are created using the postion of variant call, not the call itself. Future versions can be made to be more sophisticated in terms of variant call and number of input VCFs if needed.  

DEPENDENCIES:  Bash, Zenity, YAD, java, curl, perl, snpSift, snpEff, grep, awk, R, ggplot2(R), VennDiagram(R)
VERSION INFORMATION: July 3, 2024 BT

LICENSE:  
MIT License, Copyright (c) 2024 Bradley John Till

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the *Software*), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

directory=`zenity --width 500 --title="DIRECTORY" --text "Enter text to create a new directory (e.g. Trial1_Feb01_2024_BT).  
WARNING: No spaces or symbols other than an underscore." --entry`

if [ "$?" != 0 ]
then
    exit
    fi
mkdir $directory
cd $directory
wget https://ucdavis.box.com/shared/static/88rfin2w4991xtdsq1si0gxch5shr9o5.jpeg 
mv 88rfin2w4991xtdsq1si0gxch5shr9o5.jpeg SVUClogo.jpeg
wget https://ucdavis.box.com/shared/static/3a2979wh6firtcod3hpfo0g98xum2jhn.jpeg 
mv 3a2979wh6firtcod3hpfo0g98xum2jhn.jpeg SVUCvenn.jpeg
a=$(free -th | grep "Total" | awk '{print $2}' | sed 's/Gi//g')
YADINPUT=$(yad --width=600 --title="SVUC PARAMETERS" --image=SVUClogo.jpeg --text="CAUTION: Avoid the use of | and $ as these are special symbols for this program"  --form --field="Your Initials (for the log file)" "Enter" --field="**********VCF SELECTION (Must end in .vcf.gz Leave blank if you don't choose a VCF)**********":LBL "" --field="Caller used to make first VCF (name will appear on files and plot, click to change)" "blank" --field="Select the first VCF:FL" "" --field="Caller used to make second VCF (click to change)" "blank" --field="Select the second VCF:FL" "" --field="Caller used to make third VCF (click to change)" "blank" --field="Select the third VCF:FL" "" --field="**********OTHER PARAMETERS**********":LBL ""  --field="Select the snpEff.jar file:FL" "" --field="Select the snpSift.jar file:FL" "" --field="Select the two column case control file:FL" "" --field="Name of the snpEff genome database (case sensitive)" "Enter" --field="P-value threshold: Cochran-Armitage trend model (Change from zero to activate. Click box to manually edit):CBE" '0!0.05!0.005!0.01!0.02!0.03!0.04!0.06!0.07!0.08' --field="P-value threshold: Genotypic / Codominant model (Change from zero to activate. Click box to manually edit):CBE" '0!0.05!0.005!0.01!0.02!0.03!0.04!0.06!0.07!0.08' --field="P-value threshold: Allelic model (Change from zero to activate. Click box to manually edit):CBE" '0!0.05!0.005!0.01!0.02!0.03!0.04!0.06!0.07!0.08' --field="P-value threshold: Dominant model (Change from zero to activate. Click box to manually edit):CBE" '0!0.05!0.005!0.01!0.02!0.03!0.04!0.06!0.07!0.08' --field="P-value threshold: Recessive model (Change from zero to activate. Click box to manually edit):CBE" '0!0.05!0.005!0.01!0.02!0.03!0.04!0.06!0.07!0.08' --field="How much memory? (Computer total listed in Gb, try less than this)" $a) 
 echo $YADINPUT | tr '|' '\t' | datamash transpose | head -n -1  > parameters1
 awk 'NR==3 || NR==5 || NR==7 {print $1}' parameters1 | tr ' ' '_' | tr '\t' '_' | tr '/' '_' > vn1
awk 'NR==4 || NR==6 || NR==8 {print $1}' parameters1 | paste vn1 - | grep ".vcf.gz" > vn2 #keep this one for possible later use
rm vn1
a=$(wc -l vn2 | awk '{print $1}') 
echo "vcfcount" > ${a}.startingcount
find . -name 'doVenn' -type f -empty -delete
if [ ! -f "1.startingcount" ] ; 
then
 
YADINPUT2=$(yad --width=600 --title="VENN DIAGRAM PARAMETERS" --image=SVUCvenn.jpeg --text="****The defaults below typically produce a legible plot.****" --form  --field="Color in Venn for first VCF (click to change)":CLR "#456f01" --field="Color in Venn for second VCF (click to change)":CLR "deepskyblue4" --field="Color in Venn for third VCF (click to change)":CLR "#ffac12" --field="Outlines of Venn diagram:CB" 'None!Solid!Dashes!Dots' --field="Diagram rotation in degrees (click box to manually edit):CBE" '30!0!45!90!135!180!225!270!315' --field="Size of values (numbers) in Venn circles (click to change, or manually edit)":NUM "1[!0..50[!.5[!1]]]" --field="Font of numbers in Venn circles:CB" 'sans!serif!Palatino!AvantGarde!Helvetica-Narrow!URWBookman!NimbusMon!URWHelvetica!NimbusSanCond!CenturySch!URWPalladio' --field="Style of numbers in Venn circles:CB" 'plain!bold!italic!bold.italic' --field="Size of labels (click to change, or manually edit)":NUM "1.4[!0..50[!.1[!1]]]" --field="Font of labels:CB" 'sans!serif!Palatino!AvantGarde!Helvetica-Narrow!URWBookman!NimbusMon!URWHelvetica!NimbusSanCond!CenturySch!URWPalladio' --field="Style of labels:CB" 'plain!bold!italic!bold.italic' --field="Format to save plot:CB" 'jpeg!tiff!pdf!png!bmp!eps!svg') 
echo $YADINPUT2 | tr '|' '\t' | datamash transpose | head -n -1 | awk '{if ($1=="None") print "\x22""blank""\x22"; else print $0}' | awk '{if ($1=="Solid") print 1; else print $0}' | awk '{if ($1=="Dashes") print 2; else print $0}' | awk '{if ($1=="Dots") print 3; else print $0}' > parameters2

fi
#Start the log 
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>TVAt.log 2>&1
now=$(date)  
echo "SVUC Version 2.0
Script Started $now."  
(#Start 
echo "# Collecting Parameters"; sleep 2  
#Get samples file and rename  
awk 'NR==12 {print "cp", $1, "samples.txt"}' parameters1 > mv1.sh
chmod +x mv1.sh
./mv1.sh

awk '{print "bcftools query -l", $2, ">", $1".samples"}' vn2 > samples.sh 
chmod +x samples.sh
./samples.sh 

#control for cases where the user didn't list all the samples, or had a typo
#remove info action controls data structure
for i in *.samples; do 
a=$(awk 'NR==1 {print FILENAME}' $i | sed 's/.samples//g')
awk 'NR==FNR{a[$1]=$2;next}{if (a[$1]) print a[$1]; else print "0"}' samples.txt $i | datamash transpose | sed 's/\t//g' | awk -v var=$a '{print var, $0}' > ${i%.*}.st1; done 
cat *.st1 > stage1
echo "5"
echo "# Formatting VCFs for filtering (This may take some time)"; sleep 2
b=$(awk 'NR==11 {print $1}' parameters1)
awk -v var=$b 'NR==FNR{a[$1]=$2;next}{if (a[$1]) print "bcftools annotate --remove INFO", $2, "| java -jar", var, "caseControl \x22"a[$1]"\x22 - >",$1".tmpcasecontrol"; else print "ERROR"}' stage1 vn2 > sifting.sh
chmod +x sifting.sh
./sifting.sh     
   
echo "10"
echo "# Filtering VCFs in absolute mode"; sleep 2
######################################################## ABSOLUTE FILTERING HERE ##################################################################

##remove the neutral calls 
#inclcudes printing the code, 1 line per vcf
a=$(wc -l vn2 | awk '{print $1}')
b=$(awk 'NR==11 {print $1}' parameters1)
c=$(awk 'NR==19 {print $1}' parameters1)

awk '{if ($2!="0") print $0}' samples.txt | awk '{if ($2=="-") print "isRef (GEN["$1"]) &"; else if ($2=="+") print "(isHom (GEN["$1"]) & isVariant(GEN["$1"]) || isHet ( GEN["$1"])) & "}' | datamash transpose | tr '\t' ' ' | awk 'NF{NF-=1};1' | awk -v var=$a '{for(i=0;i<var;i++)print}' | awk -v var1=$b -v var2=$c '{print "java -Xmx"var2"g -jar", var1, "filter \x22"$0"\x22"}' > siftcode1
awk '{print $2, ">",$1"_absolutefilter1.vcf"}' vn2 | paste siftcode1 - | tr '\t' ' ' > siftcode2
awk 'NR==1 {print "#!/bin/bash" "\n" "#Genotype_based_vcf_subsetting"}' vn2 > sifthead1
cat sifthead1 siftcode2 > absolute1.sh 
rm siftcode1 siftcode2 sifthead1
chmod +x absolute1.sh 
./absolute1.sh 
b=$(awk 'NR==10 {print $1}' parameters1)
c=$(awk 'NR==19 {print $1}' parameters1)
d=$(awk 'NR==13 {print $1}' parameters1)
ls *absolutefilter1.vcf | awk '{{print $1, substr($1, 1, length($1)-20)}}' | awk -v var1=$b -v var2=$c -v var3=$d  '{print "java -Xmx"var2"g -jar", var1, var3, $1, ">", $2"_absolute_annotate.vcf ; mv snpEff_genes.txt",$2"_absolute_snpEff_genes.txt ; mv snpEff_summary.html", $2"_absolute_snpEff_summary.html"}' > abann1
awk 'NR==1 {print "#!/bin/bash" "\n" "#Annotation_of_absolute_vcf_subsetting"}' vn2 > abannhead
cat abannhead abann1 > abbann1c.sh
rm abannhead abann1 
chmod +x abbann1c.sh 
./abbann1c.sh 

#Make a human readable table using perl script provided with SnpEff.  Note that this is modified from BT's tool VAPID (see https://github.com/bjtill/VAPID-CLI, or https://github.com/bjtill/VAPID-GUI)
#get the perl code
curl https://raw.githubusercontent.com/pcingola/SnpEff/master/scripts/vcfEffOnePerLine.pl > vcfEffOnePerLine.pl
#Run the tool
for i in *_absolute_annotate.vcf; do 
bcftools query -l $i | datamash transpose > ${i%_*}.samples
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)
cat $i | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > ${i%_*}.tmp
echo "SnpSift is complete"
tail -n +2 ${i%_*}.tmp > ${i%_*}.tmp1
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' ${i%_*}.samples > ${i%_*}.header1
tr ' ' '\t' < ${i%_*}.header1 > ${i%_*}.header2
echo "Final steps in progresss"
cat ${i%_*}.header2 ${i%_*}.tmp1 > ${i%_*}_PSHT.text; done 
rm *.samples *.tmp *.tmp1 *.header1 *.header2
#End VAPID on single VCFS
#Begin the vcf comparisons 
echo "30"
echo "# Comparing VCFs created using absolute mode"; sleep 2
#######################################################Three VCF Absolute Module ##################################################################

if [ -f "3.startingcount" ] ; 
then

##Convert to VC1, 2 and 3 based on the annotation file above
ls *_absolute_annotate.vcf > FinVCFsA  #Note that the listing here is alphabetical.
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFsA | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1A"}' > firstA 
awk 'NR==2 {print "grep -v","\x22""#""\x22",$1}' FinVCFsA | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC2A"}' > secondA
awk 'NR==3 {print "grep -v","\x22""#""\x22",$1}' FinVCFsA | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC3A"}' > thirdA 
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFsA | awk '{print $0, "> VC1bodyA"}' > bodyA 
awk 'NR==1 {print "grep","\x22""#""\x22",$1}' FinVCFsA | awk '{print $0, "> vheadA"}' > headerA

printf '#!/bin/bash \n' > topA
cat topA headerA firstA secondA thirdA bodyA > Part1A.sh
chmod +x Part1A.sh
./Part1A.sh 
rm topA headerA firstA secondA thirdA bodyA

echo "35"

echo "# Counting Variants Unique In Each VCF"; sleep 2

awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC1A VC2A VC3A | wc -l > VCF3UniqueCountA #Unique in #3
awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC1A VC3A VC2A | wc -l > VCF2UniqueCountA  #Unque in #2
awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC3A VC2A VC1A | wc -l > VCF1UniqueCountA #Unique in #1

echo "40"

echo "# Counting Variants Common In Two Or More VCFs"; sleep 2
awk '{print $1}' VC1A VC2A VC3A | sort | uniq -c | awk '{if ($1==3){print $2" "$3}}' > ChPos_InAllThreeA
wc -l ChPos_InAllThreeA > CommonCountA

awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC1A VC2A | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC3A - | wc -l > Unique_VCF1_VCF2_CountA
awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC1A VC3A | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC2A - | wc -l > Unique_VCF1_VCF3_CountA
awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC3A VC2A | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC1A - | wc -l > Unique_VCF2_VCF3_CountA
echo "45"

echo "# Plotting Data"; sleep 2

echo "tmp" > tmpA
a=$(wc -l VC1A | awk '{print $1}') #first number
b=$(wc -l VC2A | awk '{print $1}') #second number
c=$(wc -l VC3A | awk '{print $1}') #third number 
d=$(awk '{print $1}' CommonCountA) #seventh number 
e=$(head -1 Unique_VCF1_VCF2_CountA)
f=$(head -1 Unique_VCF2_VCF3_CountA)
g=$(head -1 Unique_VCF1_VCF3_CountA)
h=$(awk -v var1=$d -v var2=$e '{print var1+var2}' tmpA) #the fourth number 
i=$(awk -v var1=$d -v var3=$f '{print var1+var3}' tmpA) #the fifth number
j=$(awk -v var1=$d -v var4=$g '{print var1+var4}' tmpA) #the sixth number
k=$(awk 'NR==3 {print $1}' parameters1) #vcf1 name
l=$(awk 'NR==5 {print $1}' parameters1) #vcf2 name
m=$(awk 'NR==7 {print $1}' parameters1) #vcf3 name
n=$(awk 'NR==5 {print $1}' parameters2) 
o=$(awk 'NR==4 {print $1}' parameters2) 
p=$(awk 'NR==1 {print $1}' parameters2) #three colors 
q=$(awk 'NR==2 {print $1}' parameters2)
r=$(awk 'NR==3 {print $1}' parameters2)
s=$(awk 'NR==6 {print $1}' parameters2)
t=$(awk 'NR==7 {print $1}' parameters2)
u=$(awk 'NR==8 {print $1}' parameters2)
v=$(awk 'NR==9 {print $1}' parameters2)
w=$(awk 'NR==10 {print $1}' parameters2)
x=$(awk 'NR==11 {print $1}' parameters2)
y=$(awk 'NR==12 {print $1}' parameters2)
z=$(date "+%Y%m%d_%H%M")

printf 'library(ggplot2) \nlibrary(VennDiagram) \np <- draw.triple.venn(%s, %s, %s, %s, %s, %s, %s, c("%s", "%s", "%s"), sep.dist = 0.1, rotation.degree = %s, lty = %s, fill = c("%s", "%s", "%s"),  cex=%s, fontfamily="%s", fontface="%s", cat.cex=%s, cat.fontfamily = "%s", cat.fontface = "%s", rptation=1) \nggsave(plot = p, filename= "ThreeVCFVenn_Absolute_%s.%s")' $a $b $c $h $i $j $d $k $l $m $n $o $p $q $r $s $t $u $v $w $x $z $y > vennA.r
Rscript vennA.r
rm Rplots.pdf
rm vennA.r
echo "50"

echo "# Generating New VCF Containing Common Variants"; sleep 2

#Create a VCF of the common variants using VCF3 format 
awk '{print $1"_"$2, $0}' VC1bodyA | awk 'NR==FNR{a[$1]=$1;next}{if (a[$1]) print $0}' ChPos_InAllThreeA - | cut -f 2- -d " " | cat vheadA - > Absolute_CommonAllThree.vcf

echo "55"

echo "# Generating Summary Table"; sleep 2
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)

printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > topA
awk '{print "Number Variants Common In All VCFs:", $1}' CommonCountA > oneA
awk '{print "Number Variants Unique In VCF1:", $1}' VCF1UniqueCountA > twoA
awk '{print "Number Variants Unique In VCF2:", $1}' VCF2UniqueCountA > threeA
awk '{print "Number Variants Unique In VCF3:", $1}' VCF3UniqueCountA > fourA
awk '{print "Number Variants Common To VCF1 And VCF2 Only:", $1}' Unique_VCF1_VCF2_CountA > fiveA
awk '{print "Number Variants Common To VCF1 And VCF3 Only:", $1}' Unique_VCF1_VCF3_CountA > sixA
awk '{print "Number Variants Common To VCF2 and VCF3 Only:", $1}' Unique_VCF2_VCF3_CountA > sevenA

cat topA oneA twoA threeA fourA fiveA sixA sevenA > VCF_Compare_Summary_Absolute_${c}.txt

bcftools query -l Absolute_CommonAllThree.vcf | datamash transpose > samplesC1A
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)
cat Absolute_CommonAllThree.vcf | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > tmpC1A
echo "SnpSift is complete"
tail -n +2 tmpC1A > tmp1C1A
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' samplesC1A > header1C1A
tr ' ' '\t' < header1C1A > header2C1A
echo "Final steps in progresss"
cat header2C1A tmp1C1A > Common_All_Three_Absolute_PSHT.text 
rm samplesC1A tmpC1A tmp1C1A header1C1A header2C1A
rm *CountA *AllThreeA vheadA VC1A VC2A VC3A VC1bodyA Part1A.sh FinVCFsA


fi
##################################################################END ABSOLUTE THREE VCF ##########################################################

##################################################################BEGIN ABSOLUTE TWO VCF #########################################################
if [ -f "2.startingcount" ] ; 
then

##Convert to VC1, 2 based on the annotation file above
ls *_absolute_annotate.vcf > FinVCFsB
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFsB | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1B"}' > firstB 
awk 'NR==2 {print "grep -v","\x22""#""\x22",$1}' FinVCFsB | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC2B"}' > secondB

awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFsB | awk '{print $0, "> VC1bodyB"}' > bodyB 
awk 'NR==1 {print "grep","\x22""#""\x22",$1}' FinVCFsB | awk '{print $0, "> vheadB"}' > headerB

printf '#!/bin/bash \n' > topB
cat topB headerB firstB secondB bodyB > Part1B.sh
chmod +x Part1B.sh
./Part1B.sh 
rm topB headerB firstB secondB bodyB

echo "35"

echo "# Counting Variants Unique In Each VCF"; sleep 2

awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC1B VC2B | wc -l > VCF2UniqueCountB #Unique in #2
awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC2B VC1B | wc -l > VCF1UniqueCountB  #Unque in #2


echo "40"

echo "# Counting Variants Common In Two Or More VCFs"; sleep 2
awk '{print $1}' VC1B VC2B | sort | uniq -c | awk '{if ($1==2){print $2" "$3}}' > ChPos_InAllTwoB
wc -l ChPos_InAllTwoB > CommonCountB

echo "45"

echo "# Plotting Data"; sleep 2

echo "tmp" > tmpB
a=$(wc -l VC1B | awk '{print $1}') #first number
b=$(wc -l VC2B | awk '{print $1}') #second number

d=$(awk '{print $1}' CommonCountB) #third number


k=$(awk 'NR==3 {print $1}' parameters1) #vcf1 name
l=$(awk 'NR==5 {print $1}' parameters1) #vcf2 name

n=$(awk 'NR==5 {print $1}' parameters2) 
o=$(awk 'NR==4 {print $1}' parameters2) 
p=$(awk 'NR==1 {print $1}' parameters2) #three colors 
q=$(awk 'NR==2 {print $1}' parameters2)
r=$(awk 'NR==3 {print $1}' parameters2)
s=$(awk 'NR==6 {print $1}' parameters2)
t=$(awk 'NR==7 {print $1}' parameters2)
u=$(awk 'NR==8 {print $1}' parameters2)
v=$(awk 'NR==9 {print $1}' parameters2)
w=$(awk 'NR==10 {print $1}' parameters2)
x=$(awk 'NR==11 {print $1}' parameters2)
y=$(awk 'NR==12 {print $1}' parameters2)
z=$(date "+%Y%m%d_%H%M")


printf 'library(ggplot2) \nlibrary(VennDiagram) \np <- draw.pairwise.venn(%s, %s, %s, c("%s", "%s"), sep.dist = 0.1, rotation.degree = %s, lty = %s, fill = c("%s", "%s", "%s"),  cex=%s, fontfamily="%s", fontface="%s", cat.cex=%s, cat.fontfamily = "%s", cat.fontface = "%s", rptation=1) \nggsave(plot = p, filename= "TwoVCFVenn_Absolute_%s.%s")' $a $b $d $k $l $n $o $p $q $r $s $t $u $v $w $x $z $y > venn2B.r
Rscript venn2B.r

echo "50"

echo "# Generating New VCF Containing Common Variants"; sleep 2

#Create a VCF of the common variants using VCF3 format 
awk '{print $1"_"$2, $0}' VC1bodyB | awk 'NR==FNR{a[$1]=$1;next}{if (a[$1]) print $0}' ChPos_InAllTwoB - | cut -f 2- -d " " | cat vhead - > Absolute_CommonAllTwo.vcf

echo "55"

echo "# Generating Summary Table"; sleep 2
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)

printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > top
awk '{print "Number Variants Common In All VCFs:", $1}' CommonCountB > oneB
awk '{print "Number Variants Unique In VCF1:", $1}' VCF1UniqueCountB > twoB
awk '{print "Number Variants Unique In VCF2:", $1}' VCF2UniqueCountB > threeB

cat topB oneB twoB threeB > VCF_Compare_Summary_Absolute_${c}.txt

#Code below from VAPID   

for i in *_absolute_annotate.vcf; do 
bcftools query -l $i | datamash transpose > ${i%_*}.samplesC1B
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)

cat $i | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > ${i%_*}.tmpC1B
echo "SnpSift is complete"
tail -n +2 ${i%_*}.tmpC1B > ${i%_*}.tmp1C1B
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' ${i%.*}.samplesC1B > ${i%.*}.header1C1B
tr ' ' '\t' < ${i%_*}.header1C1B > ${i%_*}.header2C1B
echo "Final steps in progresss"
cat ${i%_*}.header2C1B ${i%_*}.tmp1C1B > ${i%.*}_Absolute_PSHT.text; done 
rm *.samplesC1B *.tmpC1B *.tmp1C1B *.header1C1B *.header2C1B

bcftools query -l Absolute_CommonAllTwo.vcf | datamash transpose > samplesC1B
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)

cat Absolute_CommonAllTwo.vcf | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > tmpC1B
echo "SnpSift is complete"
tail -n +2 tmpC1B > tmp1C1B
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' samplesC1B > header1C1B
tr ' ' '\t' < header1C1B > header2C1B
echo "Final steps in progresss"
cat header2C1B tmp1C1B > Common_All_Two_Absolute_PSHT.text
rm samplesC1B tmpC1B tmp1C1B header1C1B header2C1B

fi
##########################################################END ABSOLUTE 2 VCF ######################################################################

##########################################################BEGIN ABSOLUTE 1 VCF ####################################################################


if [ -f "1.startingcount" ] ; 
then

echo "35"

echo "# Collecting information on the single VCF chosen"; sleep 2
ls *_absolute_annotate.vcf  > FinVCFsC
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFsC | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1C"}' > firstC 

printf '#!/bin/bash \n' > topC
cat topC firstC > Part1C.sh
chmod +x Part1C.sh
./Part1C.sh 
rm topC firstC

echo "55"

echo "# Generating Summary Table"; sleep 2

wc -l VC1C > CommonCountC
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)
printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > topC
awk '{print "Number Variants Common In The VCF:", $1}' CommonCountC > oneC
cat topC oneC > VCF_Compare_Summary_Absolute_${c}.txt

fi 

######################################################## END ABSOLUTE FILTERING ###################################################################
echo "60"

echo "# Evaluating VCFs in case-control mode"; sleep 2

for i in *.tmpcasecontrol; do 
grep "#" $i > ${i%.*}.header
echo "echo" > echo 
a=$(awk 'NR==10 {print $1}' parameters1) #snpeff
d=$(awk 'NR==13 {print $1}' parameters1) #SnpEff genome db
e=$(awk 'NR==14 {print $1}' parameters1) #p-value trend
e1=$(awk 'NR==14 {print $1}' parameters1) #p-value co-dom
e2=$(awk 'NR==14 {print $1}' parameters1) #p-value allelic
e3=$(awk 'NR==14 {print $1}' parameters1) #p-value Dominant
e4=$(awk 'NR==14 {print $1}' parameters1) #p-value recessive
f=$(awk 'NR==19 {print $1}' parameters1) #ram
g=$(awk -v var=$f -v var2=$a -v var3=$d '{print "java -Xmx"var"g -jar", var2, var3, "-"}' echo) 
grep -v "#" $i | awk -F';' '{print $1, $2, $3, $4, $5, $6, $7}' | sed 's/=/ /g' | awk -v var=$e -v var1=$e1 -v var2=$e2 -v var3=$e3 -v var4=$e4 '($13!="NaN" && $13 <= var) || ($15!="NaN" && $15 <= var1) || ($17!="NaN" && $17 <= var2) || ($19!="NaN" && $19 <= var3) || ($21!="NaN" && $21 <= var4)' | sed 's/CC_TREND /CC_TREND=/g' | sed 's/CC_GENO /CC_GENO=/g' | sed 's/CC_ALL /CC_ALL=/g' | sed 's/CC_DOM /CC_DOM=/g' | sed 's/CC_REC /CC_REC=/g' | sed 's/Cases /Cases=/g' | sed 's/Controls /Controls=/g' | awk '{print $1, $2, $3, $4, $5, $6, $7, $8";"$9";"$10";"$11";"$12":"$13";"$14, substr ($0, index ($0, $14))}' | cat ${i%.*}.header - | tr ' ' '\t' | $g > ${i%.*}_cc_ann.vcf #cc in name to indicate case-control
mv snpEff_genes.txt ${i%.*}_casecontrol_snpEff_genes.txt
mv snpEff_summary.html ${i%.*}_casecontrol_snpEff_summary.html ; done 
####################################################################START 3 VCF OPTION ###############################################
if [ -f "3.startingcount" ] ; 
then
echo "65"

echo "# Comparing case-control VCFs"; sleep 2
##Convert to VC1, 2 and 3 based on the annotation file above
ls *ann.vcf > FinVCFs
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1"}' > first 
awk 'NR==2 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC2"}' > second
awk 'NR==3 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC3"}' > third 
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "> VC1body"}' > body 
awk 'NR==1 {print "grep","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "> vhead"}' > header

printf '#!/bin/bash \n' > top
cat top header first second third body > Part1.sh
chmod +x Part1.sh
./Part1.sh 
rm top header first second third body

echo "70"

echo "# Counting Variants Unique In Each VCF"; sleep 2

awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC1 VC2 VC3 | wc -l > VCF3UniqueCount #Unique in #3
awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC1 VC3 VC2 | wc -l > VCF2UniqueCount  #Unique in #2
awk 'FILENAME!=ARGV[3]{seen[$0]++;next} !seen[$0]++' VC3 VC2 VC1 | wc -l > VCF1UniqueCount #Unique in #1

echo "75"

echo "# Counting Variants Common In Two Or More VCFs"; sleep 2
awk '{print $1}' VC1 VC2 VC3 | sort | uniq -c | awk '{if ($1==3){print $2" "$3}}' > ChPos_InAllThree
wc -l ChPos_InAllThree > CommonCount

awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC1 VC2 | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC3 - | wc -l > Unique_VCF1_VCF2_Count
awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC1 VC3 | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC2 - | wc -l > Unique_VCF1_VCF3_Count
awk ' FNR == 1 { b++ } { a[$0]++ } END { for (i in a) { if (a[i] == b) { print i } } } ' VC3 VC2 | awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC1 - | wc -l > Unique_VCF2_VCF3_Count
echo "80"

echo "# Plotting Data"; sleep 2

echo "tmp" > tmp
a=$(wc -l VC1 | awk '{print $1}') #first number
b=$(wc -l VC2 | awk '{print $1}') #second number
c=$(wc -l VC3 | awk '{print $1}') #third number 
d=$(awk '{print $1}' CommonCount) #seventh number 
e=$(head -1 Unique_VCF1_VCF2_Count)
f=$(head -1 Unique_VCF2_VCF3_Count)
g=$(head -1 Unique_VCF1_VCF3_Count)
h=$(awk -v var1=$d -v var2=$e '{print var1+var2}' tmp) #the fourth number 
i=$(awk -v var1=$d -v var3=$f '{print var1+var3}' tmp) #the fifth number
j=$(awk -v var1=$d -v var4=$g '{print var1+var4}' tmp) #the sixth number
k=$(awk 'NR==3 {print $1}' parameters1) #vcf1 name
l=$(awk 'NR==5 {print $1}' parameters1) #vcf2 name
m=$(awk 'NR==7 {print $1}' parameters1) #vcf3 name
n=$(awk 'NR==5 {print $1}' parameters2) 
o=$(awk 'NR==4 {print $1}' parameters2) 
p=$(awk 'NR==1 {print $1}' parameters2) #three colors 
q=$(awk 'NR==2 {print $1}' parameters2)
r=$(awk 'NR==3 {print $1}' parameters2)
s=$(awk 'NR==6 {print $1}' parameters2)
t=$(awk 'NR==7 {print $1}' parameters2)
u=$(awk 'NR==8 {print $1}' parameters2)
v=$(awk 'NR==9 {print $1}' parameters2)
w=$(awk 'NR==10 {print $1}' parameters2)
x=$(awk 'NR==11 {print $1}' parameters2)
y=$(awk 'NR==12 {print $1}' parameters2)
z=$(date "+%Y%m%d_%H%M")


printf 'library(ggplot2) \nlibrary(VennDiagram) \np <- draw.triple.venn(%s, %s, %s, %s, %s, %s, %s, c("%s", "%s", "%s"), sep.dist = 0.1, rotation.degree = %s, lty = %s, fill = c("%s", "%s", "%s"),  cex=%s, fontfamily="%s", fontface="%s", cat.cex=%s, cat.fontfamily = "%s", cat.fontface = "%s", rptation=1) \nggsave(plot = p, filename= "ThreeVCFVenn_casecontrol_%s.%s")' $a $b $c $h $i $j $d $k $l $m $n $o $p $q $r $s $t $u $v $w $x $z $y > venn1.r
Rscript venn1.r
rm Rplots.pdf
echo "90"

echo "# Generating New VCF Containing Common Variants"; sleep 2

#Create a VCF of the common variants using VCF3 format 
awk '{print $1"_"$2, $0}' VC1body | awk 'NR==FNR{a[$1]=$1;next}{if (a[$1]) print $0}' ChPos_InAllThree - | cut -f 2- -d " " | cat vhead - > CaseControl_CommonAllThree.vcf

echo "95"

echo "# Generating Summary Table"; sleep 2
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)

printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > top
awk '{print "Number Variants Common In All VCFs:", $1}' CommonCount > one
awk '{print "Number Variants Unique In VCF1:", $1}' VCF1UniqueCount > two
awk '{print "Number Variants Unique In VCF2:", $1}' VCF2UniqueCount > three
awk '{print "Number Variants Unique In VCF3:", $1}' VCF3UniqueCount > four
awk '{print "Number Variants Common To VCF1 And VCF2 Only:", $1}' Unique_VCF1_VCF2_Count > five
awk '{print "Number Variants Common To VCF1 And VCF3 Only:", $1}' Unique_VCF1_VCF3_Count > six
awk '{print "Number Variants Common To VCF2 and VCF3 Only:", $1}' Unique_VCF2_VCF3_Count > seven

cat top one two three four five six seven > VCF_Compare_Summary_casecontrol_${c}.txt

#Vapid on all three casecontrol vcfs and common variants

for i in *_cc_ann.vcf; do 
bcftools query -l $i | datamash transpose > ${i%_*}.samplesC1
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)

cat $i | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" > ${i%_*}.tmpC1
cat $i | ./vcfEffOnePerLine.pl | grep -v "#" | awk '{print substr ($0, index ($0, $11))}' | awk '{ for (i=1; i<=NF; i++) { printf "%s ", substr($i, 1, 3) } printf "\n" }' > ${i%_*}.tmpC2
paste ${i%_*}.tmpC1 ${i%_*}.tmpC2 > ${i%_*}.tmpC3
echo "SnpSift is complete"
tail -n +2 ${i%_*}.tmpC1 > ${i%_*}.tmp1C1
paste ${i%_*}.tmp1C1 ${i%_*}.tmpC2 | tr ' ' '\t' > ${i%_*}.tmpC3
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' ${i%_*}.samplesC1 > ${i%.*}.header1C1
tr ' ' '\t' < ${i%_*}.header1C1 > ${i%_*}.header2C1
echo "Final steps in progresss"
cat ${i%_*}.header2C1 ${i%_*}.tmpC3 > ${i%_*}_casecontrol_PSHT.text; done 
rm *.samplesC1 *.tmpC1 *.tmp1C1 *.header1C1 *.header2C1 *.tmpC2 *.tmpC3



bcftools query -l CaseControl_CommonAllThree.vcf | datamash transpose > samplesC1
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)
cat CaseControl_CommonAllThree.vcf | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" > tmpC1
cat CaseControl_CommonAllThree.vc | ./vcfEffOnePerLine.pl | grep -v "#" | awk '{print substr ($0, index ($0, $11))}' | awk '{ for (i=1; i<=NF; i++) { printf "%s ", substr($i, 1, 3) } printf "\n" }' > tmpC2
echo "SnpSift is complete"
tail -n +2 tmpC1 > tmp1C1
paste tmp1C1 tmpC2 > tmpC3
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' samplesC1 > header1C1
tr ' ' '\t' < header1C1 > header2C1
echo "Final steps in progresss"
cat header2C1 tmpC3 > Common_All_Three_casecontrol_PSHT.text
rm samplesC1 tmpC1 tmp1C1 header1C1 header2C1 tmpC2 tmpC3

fi

########################################### End 3 VCF Case Control Module ########################################################################################

########################################### Start 2 VCF Case Control Module ######################################################################################

if [ -f "2.startingcount" ] ; 
then
echo "65"

echo "# Comparing case-control VCFs"; sleep 2
##Convert to VC1, 2 based on the annotation file above
ls *ann.vcf > FinVCFs
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1"}' > first 
awk 'NR==2 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC2"}' > second

awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "> VC1body"}' > body 
awk 'NR==1 {print "grep","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "> vhead"}' > header

printf '#!/bin/bash \n' > top
cat top header first second body > Part1.sh
chmod +x Part1.sh
./Part1.sh 
rm top header first second body

echo "70"

echo "# Counting Variants Unique In Each VCF"; sleep 2

awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC1 VC2 | wc -l > VCF2UniqueCount #Unique in #2
awk 'FILENAME!=ARGV[2]{seen[$0]++;next} !seen[$0]++' VC2 VC1 | wc -l > VCF1UniqueCount  #Unique in #2


echo "75"

echo "# Counting Variants Common In Two Or More VCFs"; sleep 2
awk '{print $1}' VC1 VC2 | sort | uniq -c | awk '{if ($1==2){print $2" "$3}}' > ChPos_InAllTwo
wc -l ChPos_InAllTwo > CommonCount

echo "80"

echo "# Plotting Data"; sleep 2

echo "tmp" > tmp
a=$(wc -l VC1 | awk '{print $1}') #first number
b=$(wc -l VC2 | awk '{print $1}') #second number

d=$(awk '{print $1}' CommonCount) #third number


k=$(awk 'NR==3 {print $1}' parameters1) #vcf1 name
l=$(awk 'NR==5 {print $1}' parameters1) #vcf2 name

n=$(awk 'NR==5 {print $1}' parameters2) 
o=$(awk 'NR==4 {print $1}' parameters2) 
p=$(awk 'NR==1 {print $1}' parameters2) #three colors 
q=$(awk 'NR==2 {print $1}' parameters2)
r=$(awk 'NR==3 {print $1}' parameters2)
s=$(awk 'NR==6 {print $1}' parameters2)
t=$(awk 'NR==7 {print $1}' parameters2)
u=$(awk 'NR==8 {print $1}' parameters2)
v=$(awk 'NR==9 {print $1}' parameters2)
w=$(awk 'NR==10 {print $1}' parameters2)
x=$(awk 'NR==11 {print $1}' parameters2)
y=$(awk 'NR==12 {print $1}' parameters2)
z=$(date "+%Y%m%d_%H%M")


printf 'library(ggplot2) \nlibrary(VennDiagram) \np <- draw.pairwise.venn(%s, %s, %s, c("%s", "%s"), sep.dist = 0.1, rotation.degree = %s, lty = %s, fill = c("%s", "%s", "%s"),  cex=%s, fontfamily="%s", fontface="%s", cat.cex=%s, cat.fontfamily = "%s", cat.fontface = "%s", rptation=1) \nggsave(plot = p, filename= "TwoVCFVenn_casecontrol_%s.%s")' $a $b $d $k $l $n $o $p $q $r $s $t $u $v $w $x $z $y > venn2.r
Rscript venn2.r

echo "90"

echo "# Generating New VCF Containing Common Variants"; sleep 2

#Create a VCF of the common variants using VCF3 format 
awk '{print $1"_"$2, $0}' VC1body | awk 'NR==FNR{a[$1]=$1;next}{if (a[$1]) print $0}' ChPos_InAllTwo - | cut -f 2- -d " " | cat vhead - > CaseControl_CommonAllTwo.vcf

echo "95"

echo "# Generating Summary Table"; sleep 2
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)

printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > top
awk '{print "Number Variants Common In All VCFs:", $1}' CommonCount > one
awk '{print "Number Variants Unique In VCF1:", $1}' VCF1UniqueCount > two
awk '{print "Number Variants Unique In VCF2:", $1}' VCF2UniqueCount > three

cat top one two three > VCF_Compare_Summary_casecontrol_${c}.txt

#Vapid on all three casecontrol vcfs and common variants.  

for i in *_cc_ann.vcf; do 
bcftools query -l $i | datamash transpose > ${i%_*}.samplesC1
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)
cat $i | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > ${i%_*}.tmpC1
echo "SnpSift is complete"
tail -n +2 ${i%_*}.tmpC1 > ${i%_*}.tmp1C1
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' ${i%_*}.samplesC1 > ${i%_*}.header1C1
tr ' ' '\t' < ${i%_*}.header1C1 > ${i%_*}.header2C1
echo "Final steps in progresss"
cat ${i%_*}.header2C1 ${i%_*}.tmp1C1 > ${i%_*}_casecontrol_PSHT.text; done 
rm *.samplesC1 *.tmpC1 *.tmp1C1 *.header1C1 *.header2C1

bcftools query -l CaseControl_CommonAllTwo.vcf | datamash transpose > samplesC1
echo "Just got the sample names"
a=$(awk 'NR==19 {print $1}' parameters1)
b=$(awk 'NR==11 {print $1}' parameters1)
cat CaseControl_CommonAllTwo.vcf | ./vcfEffOnePerLine.pl | java -Xmx${a}g -jar $b extractFields - "ANN[*].GENE" "EFF[*].GENE" "ANN[*].FEATUREID" CHROM POS  "EFF[*].EFFECT" "ANN[*].IMPACT" "EFF[*].AA" "ANN[*].HGVS_C" "GEN[*].GT" > tmpC1
echo "SnpSift is complete"
tail -n +2 tmpC1 > tmp1C1
awk '{print "AnnotatedGeneName", "EffGeneName", "FeatureID", "Chrom", "POS", "Effect", "Impact", "AAchange", "NucChange", $0}' samplesC1 > header1C1
tr ' ' '\t' < header1C1 > header2C1
echo "Final steps in progresss"
cat header2C1 tmp1C1 > Common_All_Two_casecontrol_PSHT.text
rm samplesC1 tmpC1 tmp1C1 header1C1 header2C1



fi
################################################ END TWO VCF MODULE ########################################################################################################

############################################### START ONE VCF MODULE #######################################################################################################

if [ -f "1.startingcount" ] ; 
then
echo "65"

echo "# Collecting information on single case-control VCF"; sleep 2
ls *ann.vcf > FinVCFs
awk 'NR==1 {print "grep -v","\x22""#""\x22",$1}' FinVCFs | awk '{print $0, "| awk","\047""{print $1""\x22""_""\x22""$2}""\047 > VC1"}' > first 

printf '#!/bin/bash \n' > top
cat top first > Part1.sh
chmod +x Part1.sh
./Part1.sh 
rm top first

echo "95"

echo "# Generating summary table"; sleep 2
wc -l VC1 > CommonCount
c=$(date "+%Y%m%d_%H%M")
a=$(awk 'NR==1 {print $1}' parameters1)
printf 'SUMMARY OF VCF COMPARISON PERFORMED BY %s ON %s \n \n** See Log File For VCF Callers Used ** \n \n\n' $a $c > top
awk '{print "Number Variants Common In The VCF:", $1}' CommonCount > one
cat top one > VCF_Compare_Summary_casecontrol_${c}.txt

fi 

echo "99"
echo "# Tidying"; sleep 2

mkdir ForTrash
mv *.sh ./ForTrash/
rm *absolutefilter1.vcf  *.header *.st1 *.tmpcasecontrol ChPos_InAllThree CommonCount echo FinVCFs five fiveA four fourA one oneA seven sevenA six sixA stage1 three threeA tmp tmpA top topA two twoA Unique_VCF1_VCF2_Count Unique_VCF1_VCF3_Count Unique_VCF2_VCF3_Count VC1 VC1body VC2 VC3 VCF1UniqueCount VCF2UniqueCount VCF3UniqueCount vcfEffOnePerLine.pl venn1.r vhead vn2 yad1 yad2

mkdir SingleVCFs_Results
mv *genes.txt ./SingleVCFs_Results/
mv *.html ./SingleVCFs_Results/
mv *_absolute_PSHT.text ./SingleVCFs_Results/
mv *_cc_casecontrol_PSHT.text ./SingleVCFs_Results/
mv *_annotate.vcf ./SingleVCFs_Results/
mv *_cc_ann.vcf ./SingleVCFs_Results/


echo "Script Finished $now. The logfile is named SASDt.log") | zenity --width 800 --title "PROGRESS" --progress --auto-close
now=$(date)
echo "Script Finished $now."

#Cleaning
awk '{print FILENAME}' *.startingcount | sed 's/.startingcount//g' | awk '{print "Number of user-selected VCFs:", $1}' > Vclog
printf 'User initials: \n\nCaller for first VCF: \nPath to first VCF: \nCaller for second VCF: \nPath to second VCF: \nCaller for third VCF: \nPath to third VCF: \n\nPath to snpEff.jar \nPath to SnpSift.jar \nPath to samples file: \nSnpEff genome DB name: \nP-value cutoff for Cochran-Armitage trend model: \nP-value cutoff for codominant model: \nP-value cutoff for allelic model: \nP-value cutoff for dominant model: \nP-value cutoff for recessive model: \nRAM in Gb allocated to this program:' > par1head
paste par1head parameters1 | tr '\t' ' ' > Par1log
echo "Samples and case control status selected:" > slog
a=$(date +"%m_%d_%Y")
cat TVAt.log Vclog Par1log slog samples.txt > SVUC_${a}.log
rm TVAt.log Vclog Par1log par1head *.startingcount parameters1 parameters2 samples.txt slog SVUClogo.jpeg SVUCvenn.jpeg
rm -r ForTrash
for i in *.txt; do 
mv $i ${i%.*}_${a}.txt; done 
for i in *.text; do 
mv $i ${i%.*}_${a}.text; done 
for i in *.vcf; do 
mv $i ${i%.*}_${a}.vcf; done 
cd SingleVCFs_Results
a=$(date +"%m_%d_%Y")
for i in *.txt; do 
mv $i ${i%.*}_${a}.txt; done 
for i in *.text; do 
mv $i ${i%.*}_${a}.text; done 
for i in *.vcf; do 
mv $i ${i%.*}_${a}.vcf; done 
for i in *.html; do 
mv $i ${i%.*}_${a}.html; done 
############################################################ END OF PROGRAM ###########################################

