TRUNCATE TABLE stage_p2pacq_1400;
insert into  stage_p2pacq_1400 select * from stage_p2pacq s where s.trdate>= to_date('2021/03/21','yyyy/mm/dd')
