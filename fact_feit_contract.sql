drop table fact_feit_contract purge;
create table fact_feit_contract as 
WITH term AS
(SELECT t.TerminalCode,       
       t.MarketerId,
       t.crdate csdate,
       NVL(NVL(t.gsdate,LEAD(t.crdate, 1) OVER(PARTITION BY TerminalCode ORDER BY t.RequestId)),to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS','NLS_CALENDAR=PERSIAN')) cedate
FROM dim_vw_terminals t WHERE t.MarketerId != 999),
forfeit as(
SELECT t.terminalid,
       --SUBSTR(t.terminalserialid,2) terminalserialid,
       t.terminalserialid terminalserialid,
       t.name,
       t.currentdatetime,
       to_char(t.currentdatetime ,'YYYY/MM/DD HH24:MI:ss','NLS_CALENDAR=PERSIAN') Pcurrentdatetime,
       to_char(t.currentdatetime ,'YYYYMMDD','NLS_CALENDAR=PERSIAN') datetime,
       t.currentstatus,
       t.predatetime,
       CASE WHEN to_char(t.predatetime,'YYYY/MM/DD HH24:MI:ss') <= '2021/03/20 00:00:00'
         THEN '1400/01/01 00:00:00'
       ELSE to_char(t.predatetime ,'YYYY/MM/DD HH24:MI:ss','NLS_CALENDAR=PERSIAN') END Ppredatetime,
       t.prestatus,
       (t.datediff) statetimeperhour,
       t.TR_COUNT,
       to_char(t.currentdatetime ,'YYYYMMDD','NLS_CALENDAR=PERSIAN') PCURRENTDATE,
       to_char(t.predatetime ,'YYYYMMDD','NLS_CALENDAR=PERSIAN')PPREDATE,
       forfait_change(t.terminalserialid,to_char(t.predatetime ,'YYYY/MM/DD HH24:MI:ss','NLS_CALENDAR=PERSIAN') ,to_char(t.currentdatetime ,'YYYY/MM/DD HH24:MI:ss','NLS_CALENDAR=PERSIAN')) changes
       FROM STAGE_forfeit_monthly t       
       WHERE  t.tr_count = 0), 
       --and to_char(t.currentdatetime ,'YYYY/MM/DD HH24:MI:ss','NLS_CALENDAR=PERSIAN') <'1400/04/01 00:00:00'),

--============---forfait---==============
IN_Contract AS(
SELECT f.terminalserialid, 
       f.datetime,
       f.ppredatetime,
       f.pcurrentdatetime,
       t. MARKETERID MARKETERID,
       f.currentstatus,
       f.prestatus,
       --nvl(forfait_calc(f.terminalserialid,f.ppredatetime , f.pcurrentdatetime ),f.statetimeperhour)  feit,
       cast(((to_date(f.pcurrentdatetime, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian') -
           to_date(f.ppredatetime, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian')) * 24)as number(38,13)) nstatetimeperhour,
       'IN' feittype,
       t.csdate, 
       t.cedate, 
       f.ppredatetime fsdate,
       f.pcurrentdatetime fedate
FROM forfeit f LEFT JOIN term t ON   t.TerminalCode = f.terminalserialid AND f.ppredatetime >=t.csdate AND f.pcurrentdatetime<= t.cedate
WHERE t.csdate IS NOT NULL AND  t.cedate IS NOT NULL),
----forfait=======contract===============
cur_Contract AS (
SELECT f.terminalserialid, 
       f.datetime, 
       f.ppredatetime,
       f.pcurrentdatetime,
       --NVL(curMarketer_calc(f.terminalserialid,f.ppredatetime,f.pcurrentdatetime),t. MARKETERID) MARKETERID,
       t. MARKETERID,
       f.currentstatus,
       f.prestatus,
       --nvl(CurrForfait_calc(f.terminalserialid,f.ppredatetime , f.pcurrentdatetime ),0)  feit,
       cast(((to_date(f.pcurrentdatetime, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian') - to_date(t.csdate, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian')) * 24)as number(38,13)) nstatetimeperhour,
       'cur' feittype,
       t.csdate,
       t.cedate , 
       t.csdate fsdate,
       f.pcurrentdatetime fedate
FROM forfeit f LEFT JOIN term t ON   t.TerminalCode = f.terminalserialid AND f.ppredatetime <t.csdate AND f.pcurrentdatetime> t.csdate AND  f.pcurrentdatetime<= t.cedate
WHERE t.csdate IS NOT NULL AND  t.cedate IS NOT NULL 
),
 
--=====contract-------forfait------------
pre_Contract AS (
SELECT f.terminalserialid, 
       f.datetime,
       f.ppredatetime,
       f.pcurrentdatetime,
       t. MARKETERID ,
       f.currentstatus,
       f.prestatus,
       --preForfait_calc(f.terminalserialid,f.ppredatetime , f.pcurrentdatetime )  feit,
       cast(((to_date(t.cedate, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian') - to_date(f.ppredatetime, 'yyyy/mm/dd hh24:mi:ss', 'NLS_CALENDAR=persian')) * 24)as number(38,13)) nstatetimeperhour,
       'pre' feittype,
       t.csdate, 
       t.cedate , 
       f.ppredatetime fsdate,
       cedate fedate
FROM forfeit f LEFT JOIN term t ON   t.TerminalCode = f.terminalserialid AND f.ppredatetime >=t.csdate AND f.ppredatetime< t.cedate AND  f.pcurrentdatetime >= t.cedate
WHERE t.csdate IS NOT NULL AND  t.cedate IS NOT NULL
)
,
feit_contract as(
SELECT * FROM IN_Contract  f
UNION 
SELECT * FROM Pre_Contract f 
UNION 
SELECT * FROM Cur_Contract f  
)
select f.*,(SELECT /*+parallel(source 4) nologging */ to_char(min(s.trdate),'yyyy/mm/dd hh24:mi:ss','nls_calendar=persian') FROM Stage_P2PACQ s 
               WHERE substr(s.terminal,-5) =f.TerminalSerialId AND 
                     s.TrDate >= to_date(f.csdate,'yyyy/mm/dd hh24:mi:ss','nls_calendar=persian')
                     ) pftdate,0 as feit, cast(f.nstatetimeperhour/24 as number(38,4))as nday, 0 as feitcaltype , 
                     CASE WHEN currentstatus >= 90 THEN 1 else 0 END cur_status
 from feit_contract f
