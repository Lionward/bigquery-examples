# The following query computes the allelic frequency for BRCA1 variants in the 
# 1,000 Genomes dataset further classified by gender from the phenotypic data.
SELECT
  contig_name,
  start_pos,
  gender,
  reference_bases,
  alternate_bases
  alt,
  SUM(ref_count)+SUM(alt_count) AS num_sample_alleles,
  SUM(ref_count) AS ref_cnt,
  SUM(alt_count) AS alt_cnt,
  SUM(ref_count)/(SUM(ref_count)+SUM(alt_count)) AS ref_freq,
  SUM(alt_count)/(SUM(ref_count)+SUM(alt_count)) AS alt_freq,
FROM (
  SELECT
    contig_name,
    start_pos,
    gender,
    reference_bases,
    alternate_bases,
    alt,
    SUM(IF(0 = allele1,
        1,
        0) + IF(0 = allele2,
        1,
        0)) AS ref_count,
    SUM(IF(alt = allele1,
        1,
        0) + IF(alt = allele2,
        1,
        0)) AS alt_count
  FROM (
    SELECT
      g.contig_name AS contig_name,
      g.start_pos AS start_pos,
      p.gender AS gender,
      g.reference_bases AS reference_bases,
      g.alternate_bases AS alternate_bases,
      POSITION(g.alternate_bases) AS alt,
      allele1,
      allele2,
    FROM
      FLATTEN((
        SELECT
          contig_name,
          start_pos,
          reference_bases,
          alternate_bases,
          call.callset_name,
          NTH(1,
            call.genotype) WITHIN call AS allele1,
          NTH(2,
            call.genotype) WITHIN call AS allele2,
        FROM
          [google.com:biggene:1000genomes.phase1_variants]
        WHERE
          contig_name = '17'
          AND start_pos BETWEEN 41196312
          AND 41277500
          AND vt='SNP'
          ),
        call) AS g
    JOIN
      [google.com:biggene:1000genomes.sample_info] p
    ON
      g.call.callset_name = p.sample
      )
  GROUP BY
    contig_name,
    start_pos,
    gender,
    reference_bases,
    alternate_bases,
    alt)
GROUP BY
  contig_name,
  start_pos,
  gender,
  reference_bases,
  alternate_bases,
  alt
ORDER BY
  contig_name,
  start_pos,
  gender,
  reference_bases,
  alt,
  alternate_bases
