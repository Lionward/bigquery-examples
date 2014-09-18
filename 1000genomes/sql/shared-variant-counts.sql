# Count the number of variants shared by none, shared by one sample, two samples, etc...
SELECT
  num_samples_with_variant,
  COUNT(1) AS num_variants_shared_by_this_many_samples
FROM (
  SELECT
    SUM(IF(genotype.first_allele > 0
        OR genotype.second_allele > 0,
        1,
        0)) WITHIN RECORD AS num_samples_with_variant
  FROM
    [google.com:biggene:1000genomes.phase1_variants])
GROUP BY
  num_samples_with_variant
ORDER BY
  num_samples_with_variant;