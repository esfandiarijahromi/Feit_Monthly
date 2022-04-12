CREATE OR REPLACE PROCEDURE feit_monthly
(terminalcode IN NUMBER,marketerid IN NUMBER, startDate IN NVARCHAR2, endDate IN NVARCHAR2,contractStartDate in nvarchar2,contractEndDate in nvarchar2 )
AS

--startDate VARCHAR2(19);
--endDate VARCHAR2(19);
startMonth NUMBER;
--startMonthV VARCHAR2(2);
endMonth NUMBER;
--endMonthV VARCHAR2(2);
startDay NUMBER;
endDay NUMBER;
startHour NUMBER;
endHour NUMBER;
startMinute NUMBER;
endMinute NUMBER;
startYear NUMBER;
endYear NUMBER;
ssaat NUMBER;
srooz NUMBER;
esaat NUMBER;
erooz NUMBER;
m NUMBER;

BEGIN
--startDate := '1399/08/09 11:45:31';
--endDate := '1399/09/09 11:45:31';
startMonth := To_number(SUBSTR(startDate,6,2));
--startMonthV:= SUBSTR(startDate,6,2);
endMonth := To_number(SUBSTR(endDate,6,2));
--endMonthV :=To_number(SUBSTR(endDate,6,2));
startDay := To_number(SUBSTR(startDate,9,2));
endDay := To_number(SUBSTR(endDate,9,2));
startHour := To_number(SUBSTR(startDate,12,2));
endHour := To_number(SUBSTR(endDate,12,2));
startMinute := To_number(SUBSTR(startDate,15,2));
endMinute := To_number(SUBSTR(endDate,15,2));
startYear := To_number(SUBSTR(startDate,1,4));
endYear := To_number(SUBSTR(endDate,1,4));
ssaat := 24-1-startHour;

/* srooz := 30-1-startDay;*/

/*esaat := endHour-1- 0;*/
esaat := endHour- 0;
erooz := endDay -1- 0;

if startMonth <7 then
 
  srooz:=31- startDay;
else   
  srooz:=30- startDay;

end if;

IF startMonth!= endMonth THEN
INSERT INTO fact_feit_monthly (Terminalserialid,Montha,Marketerid,Nstatetimeperhour,FSDATE,FEDATE,CSDATE,CEDATE) 
       VALUES (terminalcode, startYear||'/'||startMonth , marketerid, ((srooz*24 + ssaat)*60+(60-startMinute))/60, startDate , endDate ,contractStartDate ,contractEndDate  );
       
INSERT INTO fact_feit_monthly (Terminalserialid,Montha,Marketerid,Nstatetimeperhour,FSDATE,FEDATE,CSDATE,CEDATE) 
       VALUES (terminalcode, endYear||'/'||endMonth , marketerid, ((erooz*24 + esaat)*60+endMinute)/60, startDate , endDate ,contractStartDate ,contractEndDate);
       
FOR loop_counter IN  startMonth+1..endMonth-1
  
LOOP
if loop_counter <7 then
m:=31;
else m:=30;
end if;
   INSERT INTO fact_feit_monthly (Terminalserialid,Montha,Marketerid,Nstatetimeperhour, FSDATE,FEDATE,CSDATE,CEDATE)
   VALUES (terminalcode, endYear||'/'||loop_counter, marketerid , (m*24), startDate , endDate ,contractStartDate ,contractEndDate);
END LOOP;

ELSE
INSERT INTO fact_feit_monthly (Terminalserialid,Montha,Marketerid,Nstatetimeperhour,FSDATE,FEDATE,CSDATE,CEDATE)
       VALUES (terminalcode, startYear||'/'||startMonth , marketerid , (to_date(endDate   ,'yyyy/mm/dd hh24:mi:ss','NLS_CALENDAR=PERSIAN')  -
                                             to_date(startDate ,'yyyy/mm/dd hh24:mi:ss','NLS_CALENDAR=PERSIAN'))*24, startDate , endDate ,contractStartDate ,contractEndDate);
END IF;
COMMIT;
END;
