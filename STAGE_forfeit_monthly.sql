drop table STAGE_forfeit_monthly purge;
create table STAGE_forfeit_monthly
as
SELECT /*+parallel(source 4) nologging */ t.* , 
(SELECT /*+parallel(source 4) nologging */ COUNT(*) FROM b s 
               WHERE s.Terminal = t.TerminalSerialId AND 
                     s.TrDate BETWEEN t.PreDateTime AND t.CurrentDateTime 
                     ) Tr_count
FROM a t
