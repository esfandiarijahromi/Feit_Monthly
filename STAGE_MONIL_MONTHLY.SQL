insert into  STAGE_MONIK_MONTHLY 
WITH terhmeh AS(
SELECT to_date('2021-03-21 00:00:00' , 'yyyy-mm-dd hh24:mi:ss') DateTime, TerminalId,FinalStatus FROM dwdb.monik s
WHERE datetime IN
(
SELECT MAX(datetime) 
FROM dwdb.monik
WHERE datetime <to_date('2021-03-21 00:00:00' , 'yyyy-mm-dd hh24:mi:ss') AND TerminalId = s.TerminalId
GROUP BY TerminalId) 
UNION ALL
SELECT  DateTime ,
      TerminalId,
        FinalStatus
FROM dwdb.monik
WHERE datetime >=to_date('2021-03-21  00:00:00' , 'yyyy-mm-dd hh24:mi:ss')
), 
termeh AS (
SELECT t.datetime,
       t.terminalID,
       t.finalstatus OLDfinalstatus,
       CASE WHEN t.finalstatus >90 THEN 98 ELSE t.finalstatus END finalstatus
FROM terhmeh t),


CTE AS
(
    SELECT  TerminalId,
            FinalStatus,
             DateTime ,
            CASE WHEN LAG(FinalStatus) OVER(PARTITION BY TerminalId ORDER BY  DateTime ) <> FinalStatus 
      THEN 
           1
            END As Filter
    FROM termeh
),
TerminalStatus AS
(
SELECT  DateTime  , TerminalId,FinalStatus
    FROM CTE
    WHERE (FILTER = 1 OR DateTime =  to_date('2021-03-21 00:00:00' , 'yyyy-mm-dd hh24:mi:ss') )
),

terminallogs AS
(
SELECT vw.TerminalId,
    t.TerminalSerialId,
    t.NetworkAddress,
    tp.Name,    
    vw.DateTime PreDateTime,
    vw.FinalStatus AS PreStatus,
    NVL(LEAD(vw.DateTime,1) OVER (PARTITION BY TerminalId ORDER BY vw.DateTime),SYSDATE) AS CurrentDateTime,   
    NVL(LEAD(vw.FinalStatus,1) OVER (PARTITION BY TerminalId ORDER BY vw.DateTime  ),vw.FinalStatus) AS CurrentStatus

FROM TerminalStatus vw, dwdb.Terminals t , dwdb.terminalprofile tp
WHERE VW.TerminalId = t.Id AND t.TerminalProfileId = tp.Id),

terminalstage as 
(SELECT TerminalId,
       TerminalSerialId,
       Name,
       PreDateTime,
       to_char(PreDateTime , 'yyyy/mm/dd hh24:mi:ss','nls_calendar=persian')PPreDateTime,
       PreStatus,
       CurrentDateTime,
       to_char(CurrentDateTime , 'yyyy/mm/dd hh24:mi:ss','nls_calendar=persian')PCurrentDateTime,
       CurrentStatus,
      cast((currentdatetime - predatetime)*24 as NUMBER(38,13)) DATEDIFF
FROM terminallogs) 
select 
TerminalId,
       TerminalSerialId,
       Name,
       PreDateTime,
       PPreDateTime,
       PreStatus,
       CurrentDateTime,
       PCurrentDateTime,
       CurrentStatus,
       DATEDIFF
from terminalstage t where t.PreStatus=98 and t.DATEDIFF>=3;
commit;
