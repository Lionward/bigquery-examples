<!-- R Markdown Documentation, DO NOT EDIT THE PLAIN MARKDOWN VERSION OF THIS FILE -->

<!-- Copyright 2014 Google Inc. All rights reserved. -->

<!-- Licensed under the Apache License, Version 2.0 (the "License"); -->
<!-- you may not use this file except in compliance with the License. -->
<!-- You may obtain a copy of the License at -->

<!--     http://www.apache.org/licenses/LICENSE-2.0 -->

<!-- Unless required by applicable law or agreed to in writing, software -->
<!-- distributed under the License is distributed on an "AS IS" BASIS, -->
<!-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. -->
<!-- See the License for the specific language governing permissions and -->
<!-- limitations under the License. -->

Understanding Alternate Alleles in 1,000 Genomes VCF Data
========================================================

We know from the [FAQ](http://www.1000genomes.org/faq/are-all-genotype-calls-current-release-vcf-files-bi-allelic) that the 1,000 Genomes VCF data is [bi-allelic](http://www.1000genomes.org/faq/are-all-genotype-calls-current-release-vcf-files-bi-allelic) → meaning that each row in the source VCF has only one value in the ALT field.  So for each sample in a row, the genotype was called as either the reference or the single ALT value.  At any particular position in the genome we can have much more variation than a single alternate, so we need to understand how that is encoded in this data set.



Let’s explore the question _“Is (contig, position, reference_bases) a unique key in the 1,000 Genomes Data?”_


```
# Find variants on chromosome 17 that reside on the same start_pos with the same reference base
SELECT
  contig_name,
  start_pos,
  reference_bases,
  COUNT(start_pos) AS num_alternates
FROM
  [google.com:biggene:1000genomes.phase1_variants]
WHERE
  contig_name = '17'
GROUP BY
  contig_name,
  start_pos,
  reference_bases
HAVING
  num_alternates > 1
ORDER BY
  contig_name,
  start_pos,
  reference_bases
```
Number of rows returned by this query: 417.

We see the first six tabular results:
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:15 2014 -->
<TABLE border=1>
<TR> <TH> contig_name </TH> <TH> start_pos </TH> <TH> reference_bases </TH> <TH> num_alternates </TH>  </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 184673 </TD> <TD> G </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 211032 </TD> <TD> C </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 240040 </TD> <TD> G </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 443436 </TD> <TD> A </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 533536 </TD> <TD> A </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 557991 </TD> <TD> A </TD> <TD align="right">   2 </TD> </TR>
   </TABLE>
So we see from the data that the answer to our question is “No”.

So how many rows might we see per (contig, position, reference_bases) tuple?

```
# Count number of alternate variants on chromosome 17 for the same start_pos and
# reference base
SELECT
  num_alternates,
  COUNT(num_alternates) AS num_records
FROM (
  SELECT
    contig_name,
    start_pos,
    reference_bases,
    COUNT(start_pos) AS num_alternates,
  FROM
    [google.com:biggene:1000genomes.phase1_variants]
  WHERE
    contig_name = '17'
  GROUP BY
    contig_name,
    start_pos,
    reference_bases)
GROUP BY
  num_alternates
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:19 2014 -->
<TABLE border=1>
<TR> <TH> num_alternates </TH> <TH> num_records </TH>  </TR>
  <TR> <TD align="right">   1 </TD> <TD align="right"> 1045899 </TD> </TR>
  <TR> <TD align="right">   2 </TD> <TD align="right"> 417 </TD> </TR>
   </TABLE>
So we see that for any particular (contig, position, reference_bases) tuple the vast majority have a single alternate allele and a few have two.

Let’s examine a few of the tuples with two alternate alleles more closely.

```
# Get three particular start_pos on chromosome 17 that have alternate variants.
SELECT
  contig_name,
  start_pos,
  reference_bases,
  GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
#  GROUP_CONCAT(id) WITHIN RECORD AS ids,
  vt,
FROM
  [google.com:biggene:1000genomes.phase1_variants]
WHERE
  contig_name = '17'
  AND (start_pos = 48515943
    OR start_pos = 48570614
    OR start_pos = 48659343)
ORDER BY
  start_pos,
  reference_bases,
  alt
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:24 2014 -->
<TABLE border=1>
<TR> <TH> contig_name </TH> <TH> start_pos </TH> <TH> reference_bases </TH> <TH> alt </TH> <TH> vt </TH>  </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> T </TD> <TD> G </TD> <TD> SNP </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> T </TD> <TD> TG </TD> <TD> INDEL </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48570614 </TD> <TD> A </TD> <TD> AT </TD> <TD> INDEL </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48570614 </TD> <TD> A </TD> <TD> T </TD> <TD> SNP </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48659343 </TD> <TD> C </TD> <TD> CTGGT </TD> <TD> INDEL </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48659343 </TD> <TD> C </TD> <TD> T </TD> <TD> SNP </TD> </TR>
   </TABLE>
From this small sample, it appears that the alternate allele is either a SNP or an INDEL.

Is that the case for all the records corresponding to duplicate (contig, position, reference_bases) tuples?

```
# Count by variant type the number of alternate variants on chromosome 17 for the same
# start_pos and reference base
SELECT
  vt,
  COUNT(vt) AS num_variant_type
FROM
  [google.com:biggene:1000genomes.phase1_variants] AS variants
JOIN (
  SELECT
    contig_name,
    start_pos,
    reference_bases,
    COUNT(start_pos) AS num_alternates,
  FROM
    [google.com:biggene:1000genomes.phase1_variants]
  WHERE
    contig_name = '17'
  GROUP EACH BY
    contig_name,
    start_pos,
    reference_bases
  HAVING
    num_alternates > 1) AS dups
ON
  variants.contig_name = dups.contig_name
  AND variants.start_pos = dups.start_pos
  AND variants.reference_bases = dups.reference_bases
WHERE
  variants.contig_name = '17'
GROUP EACH BY
  vt
ORDER BY
  vt
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:28 2014 -->
<TABLE border=1>
<TR> <TH> vt </TH> <TH> num_variant_type </TH>  </TR>
  <TR> <TD> INDEL </TD> <TD align="right"> 412 </TD> </TR>
  <TR> <TD> SNP </TD> <TD align="right"> 417 </TD> </TR>
  <TR> <TD> SV </TD> <TD align="right">   5 </TD> </TR>
   </TABLE>
It appears that for all records for duplicate (contig, position, reference_bases) tuples that we have a SNP and also an INDEL or SV.

For records corresponding to a unique (contig, position, reference_bases) tuple, are the variants always SNPs?

```
# Count by variant type the number of variants on chromosome 17 unique for a
# start_pos and reference base
SELECT
  vt,
  COUNT(vt) AS num_variant_type
FROM
  [google.com:biggene:1000genomes.phase1_variants] AS variants
JOIN EACH (
  SELECT
    contig_name,
    start_pos,
    reference_bases,
    COUNT(start_pos) AS num_alternates
  FROM
    [google.com:biggene:1000genomes.phase1_variants]
  WHERE
    contig_name = '17'
  GROUP EACH BY
    contig_name,
    start_pos,
    reference_bases
  HAVING
    num_alternates = 1) AS singles
ON
  variants.contig_name = singles.contig_name
  AND variants.start_pos = singles.start_pos
  AND variants.reference_bases = singles.reference_bases
WHERE
  variants.contig_name = '17'
GROUP EACH BY
  vt
ORDER BY
  vt
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:31 2014 -->
<TABLE border=1>
<TR> <TH> vt </TH> <TH> num_variant_type </TH>  </TR>
  <TR> <TD> INDEL </TD> <TD align="right"> 38754 </TD> </TR>
  <TR> <TD> SNP </TD> <TD align="right"> 1006702 </TD> </TR>
  <TR> <TD> SV </TD> <TD align="right"> 443 </TD> </TR>
   </TABLE>
And we see that the answer to our question is “No” - for records corresponding to a unique (contig, position, reference_bases) tuple, the variants are mostly SNPs but also INDELs and SVs.

So what does this all mean for a particular duplicate (contig, position, reference_bases) tuple for a particular sample at a particular genomic position?

```
# Get sample alleles for some specific variants.
# TODO(deflaux): update this to a user-defined function to generalize
# across more than two alternates.  For more info, see
# https://www.youtube.com/watch?v=GrD7ymUPt3M#t=1377
SELECT
  contig_name,
  start_pos,
  alt,
  reference_bases,
  sample_id,
  CASE
  WHEN 0 = allele1 THEN reference_bases
  WHEN 1 = allele1 THEN alt1
  WHEN 2 = allele1 THEN alt2 END AS allele1,
  CASE
  WHEN 0 = allele2 THEN reference_bases
  WHEN 1 = allele2 THEN alt1
  WHEN 2 = allele2 THEN alt2 END AS allele2,
FROM(
  SELECT
    contig_name,
    start_pos,
    GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
    reference_bases,
    call.callset_name AS sample_id,
    NTH(1,
      alternate_bases) WITHIN RECORD AS alt1,
    NTH(2,
      alternate_bases) WITHIN RECORD AS alt2,
    NTH(1, call.genotype) WITHIN call AS allele1,
    NTH(2, call.genotype) WITHIN call AS allele2,
  FROM
    [google.com:biggene:1000genomes.phase1_variants]
  WHERE
    contig_name = '17'
    AND start_pos = 48515943
  HAVING
    sample_id = 'HG00100' OR sample_id = 'HG00101')
ORDER BY
  alt,
  sample_id
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:36 2014 -->
<TABLE border=1>
<TR> <TH> contig_name </TH> <TH> start_pos </TH> <TH> alt </TH> <TH> reference_bases </TH> <TH> sample_id </TH> <TH> allele1 </TH> <TH> allele2 </TH>  </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> G </TD> <TD> T </TD> <TD> HG00100 </TD> <TD> T </TD> <TD> G </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> G </TD> <TD> T </TD> <TD> HG00101 </TD> <TD> T </TD> <TD> T </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> TG </TD> <TD> T </TD> <TD> HG00100 </TD> <TD> T </TD> <TD> TG </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> TG </TD> <TD> T </TD> <TD> HG00101 </TD> <TD> T </TD> <TD> T </TD> </TR>
   </TABLE>
We can see that HG00101 was called the same in both records but HG00100 was called differently.  So which is the [correct interpretation](http://vcftools.sourceforge.net/VCF-poster.pdf) for each allele at position 48515943 on chromosome 17?
```
first allele
xxxTxxxx

second allele
xxxGxxxx
or
xxxTGxxx
```
Let’s examine the quality, some INFO fields, and the genotype likelihoods a little more closely.

```
# Get data sufficient to make a judgment upon this particular sample's call.
SELECT
  contig_name,
  start_pos,
  reference_bases AS ref,
  GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
# TODO: uncomment these when the fields are restored to the table
#  quality,
#  GROUP_CONCAT(filter) WITHIN RECORD AS filters,
  avgpost,
  rsq
  vt,
  call.callset_name AS sample_id,
  call.phaseset AS phaseset,
  NTH(1, call.genotype) WITHIN call AS allele1,
  NTH(2, call.genotype) WITHIN call AS allele2,
  call.ds AS ds,
  GROUP_CONCAT(STRING(call.genotype_likelihood)) WITHIN call AS likelihoods,
FROM
  [google.com:biggene:1000genomes.phase1_variants]
WHERE
  contig_name = '17'
  AND start_pos = 48515943
HAVING
  sample_id = 'HG00100'
ORDER BY
  alt
Running query:   RUNNING  2.6sRunning query:   RUNNING  3.7sRunning query:   RUNNING  5.1s
```
<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:44 2014 -->
<TABLE border=1>
<TR> <TH> contig_name </TH> <TH> start_pos </TH> <TH> ref </TH> <TH> alt </TH> <TH> avgpost </TH> <TH> vt </TH> <TH> sample_id </TH> <TH> phaseset </TH> <TH> allele1 </TH> <TH> allele2 </TH> <TH> ds </TH> <TH> likelihoods </TH>  </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> T </TD> <TD> G </TD> <TD align="right"> 0.99 </TD> <TD align="right"> 0.99 </TD> <TD> HG00100 </TD> <TD> * </TD> <TD align="right">   0 </TD> <TD align="right">   1 </TD> <TD align="right"> 1.00 </TD> <TD> -3.52,0,-2.65 </TD> </TR>
  <TR> <TD> 17 </TD> <TD align="right"> 48515943 </TD> <TD> T </TD> <TD> TG </TD> <TD align="right"> 0.95 </TD> <TD align="right"> 0.90 </TD> <TD> HG00100 </TD> <TD> * </TD> <TD align="right">   0 </TD> <TD align="right">   1 </TD> <TD align="right"> 0.90 </TD> <TD> 0,-0.6,-5.4 </TD> </TR>
   </TABLE>
The [likelihoods](http://faculty.washington.edu/browning/beagle/intro-to-vcf.html) correspond to the REF/REF, REF/ALT, and ALT/ALT genotypes in that order.  See the [schema](https://bigquery.cloud.google.com/table/google.com:biggene:1000genomes.variants1kG?pli=1) for details about the other fields.

So a question for our users who have much experience in this domain, which variant is more likely for the second allele of HG00100?

### But we digress . . .

Our original question was _“Is (contig, position, reference_bases) a unique key in the 1,000 Genomes Data?”_ which we know is false.  So which columns do constitute a unique key?


```
# This query demonstrates that some additional field is needed to
# comprise a unique key for the rows in the table.
SELECT
  contig_name,
  start_pos,
  reference_bases,
  alt,
  vt,
  COUNT(1) AS cnt
FROM (
  SELECT
    contig_name,
    start_pos,
    reference_bases,
    GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
    vt,
  FROM
    [google.com:biggene:1000genomes.phase1_variants])
  GROUP EACH BY
  contig_name,
  start_pos,
  reference_bases,
  alt,
  vt
HAVING
  cnt > 1
ORDER BY
  contig_name
```

<!-- html table generated in R 3.1.1 by xtable 1.7-3 package -->
<!-- Fri Sep 19 12:40:50 2014 -->
<TABLE border=1>
<TR> <TH> contig_name </TH> <TH> start_pos </TH> <TH> reference_bases </TH> <TH> alt </TH> <TH> vt </TH> <TH> cnt </TH>  </TR>
  <TR> <TD> 14 </TD> <TD align="right"> 106885901 </TD> <TD> G </TD> <TD> &lt;U+003c&gt;DEL&lt;U+003e&gt; </TD> <TD> SV </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 19 </TD> <TD align="right"> 48773401 </TD> <TD> C </TD> <TD> &lt;U+003c&gt;DEL&lt;U+003e&gt; </TD> <TD> SV </TD> <TD align="right">   2 </TD> </TR>
  <TR> <TD> 6 </TD> <TD align="right"> 26745501 </TD> <TD> C </TD> <TD> &lt;U+003c&gt;DEL&lt;U+003e&gt; </TD> <TD> SV </TD> <TD align="right">   2 </TD> </TR>
   </TABLE>
Not quite.  We see a few structural variant deletions called at the same position.

Let's add in the `end` column:

```
# This query demonstrates that an additional field, 'end', is needed to  
# comprise a unique key for the rows in the table.
SELECT
  contig_name,
  start_pos,
  reference_bases,
  alt,
  vt,
  end,
  COUNT(1) AS cnt
FROM (
  SELECT
    contig_name,
    start_pos,
    reference_bases,
    GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
    vt,
    end,
  FROM
    [google.com:biggene:1000genomes.phase1_variants])
  GROUP EACH BY
  contig_name,
  start_pos,
  reference_bases,
  alt,
  vt,
  end
HAVING
  cnt > 1
```


```r
print(expect_true(is.null(result)))
```

```
As expected: is.null(result) is true 
```

And now we have it, a unique key is: (contig, position, reference_bases, alternate_bases, vt, end)

Lastly, what is a minimal unique key?

```
# This query demonstrates the minimal set of fields needed to  
# comprise a unique key for the rows in the table.
SELECT
  contig_name,
  start_pos,
  alt,
  end,
  COUNT(1) AS cnt
FROM (
  SELECT
    contig_name,
    start_pos,
    GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
    end,
  FROM
    [google.com:biggene:1000genomes.phase1_variants])
  GROUP EACH BY
  contig_name,
  start_pos,
  alt,
  end
HAVING
  cnt > 1
```


```r
print(expect_true(is.null(result)))
```

```
As expected: is.null(result) is true 
```

We see that a minimal unique key is: (contig, position, alternate_bases, end) or alternatively (contig, position, end, vt)
