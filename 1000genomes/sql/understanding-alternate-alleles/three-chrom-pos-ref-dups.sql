# Get three particular positions on chromosome 17 that have alternate variants.
SELECT
  contig_name,
  position,
  reference_bases,
  GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alt,
  GROUP_CONCAT(id) WITHIN RECORD AS ids,
  vt,
FROM
  [google.com:biggene:1000genomes.phase1_variants]
WHERE
  contig_name = '17'
  AND (position = 48515943
    OR position = 48570614
    OR position = 48659343);