// x > 1401/4
// y > 1401/5
// delete  Fact_Feit_Monthly t  where t.montha in (&y)

insert into new_feit_fact
SELECT * FROM (
WITH a AS (SELECT t.terminalserialid
       , t.montha
       , t.marketerid
       , SUM(t.nstatetimeperhour) feithour FROM fact_feit_monthly t where t.montha ='&x' 
       GROUP BY t.terminalserialid,t.montha,t.marketerid)

SELECT a.* , REPLACE (montha,'/','0') monthid,
            CASE WHEN a.feithour <=24 THEN 0
            WHEN a.feithour > 24 AND a.feithour <= 45 THEN (a.feithour-24) * 7000
            WHEN a.feithour > 45 AND a.feithour <= 81 THEN (105000) + ((a.feithour-45)*9000)
            WHEN a.feithour > 81 AND a.feithour <=136 THEN (105000) + (252000) + ((a.feithour-81)*12000)
            WHEN a.feithour >136 AND a.feithour <=744 THEN (105000) + (252000) + (550000) + ((a.feithour-136)*17000)
      END feit
FROM a
where a.feithour > 24
)
