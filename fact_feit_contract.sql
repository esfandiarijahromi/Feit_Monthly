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
       t.Ppredatetime,
       t.prestatus,
       (t.datediff) statetimeperhour,
       t.TR_COUNT,
       to_char(t.currentdatetime ,'YYYYMMDD','NLS_CALENDAR=PERSIAN') PCURRENTDATE,
       to_char(t.predatetime ,'YYYYMMDD','NLS_CALENDAR=PERSIAN')PPREDATE
      
       FROM STAGE_forfeit_monthly t       
       WHERE  t.tr_count = 0 and 
       t.terminalserialid not in ('50008','50017','50029','50030','50032','50043','50055','50065','50070','50082','50094','50133','50149','50155','50156','50157','50158','50164','50188','50190',
        '50203','50206','50221','50234','50236','50239','50248','50251','50261','50268','50279','50286','50289','50328','50357','50362','50457','50463','50486','50507','50510','50528','50529','50568','50571','50984',
        '50986','51014','51089','51252','51284','51293','51362','51368','51369','51398','51400','51506','51665','50350','50527','50617','50581','50927')


       ), 
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
select f.*
 from feit_contract f
