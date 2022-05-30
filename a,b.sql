truncate table a;
insert into a 
SELECT /*+parallel(source 4) nologging */ t.terminalid,
                                          substr(t.TerminalSerialId,-5) terminalserialid,
                                          t.name,
                                          t.predatetime,
                                          t.ppredatetime,
                                          t.prestatus,
                                          t.currentdatetime,
                                          t.pcurrentdatetime,
                                          t.currentstatus,
                                          t.datediff from STAGE_MONIK_MONTHLY t
                                          where t.currentdatetime>=to_date('&X','yyyy/mm/dd','nls_calendar=persian');
commit;

update a
set a.predatetime=to_date('&Y 00:00:00','yyyy/MM/DD HH24:MI:SS') 
where a.predatetime<to_date('&X','yyyy/mm/dd','nls_calendar=persian');

update a
set a.Ppredatetime='&X 00:00:00'   
where a.Ppredatetime<'&X';

truncate table b;                        
insert into /*+parallel(source 4) nologging */ b
SELECT /*+parallel(source 4) nologging */ s.trdate,
                                          substr(s.Terminal,-5) terminal,
                                          s.transactiontype,
                                          s.amount FROM dwdb.Stage_P2PACQ_1400 s
                                       
where substr(s.Terminal,-5) in 
(Select distinct substr(TerminalSerialId,-5) from  STAGE_MONIK_MONTHLY)
AND  s.trdate>=to_date('&X','yyyy/mm/dd','nls_calendar=persian');                            
commit;
