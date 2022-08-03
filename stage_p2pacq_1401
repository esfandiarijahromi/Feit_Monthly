truncate table  stage_p2pacq_1401;
insert into  stage_p2pacq_1401 select * from stage_p2pacq s where s.trdate>= to_date('2021/03/21','yyyy/mm/dd');
commit;
