# Find variants on chromosome 17 that reside on the same position with the same reference base
SELECT
  contig,
  position,
  reference_bases,
  COUNT(position) AS num_alternates
FROM
  [google.com:biggene:1000genomes.phase1_variants]
WHERE
  contig = '17'
GROUP BY
  contig,
  position,
  reference_bases
HAVING
  num_alternates > 1
ORDER BY
  contig,
  position,
  reference_bases;