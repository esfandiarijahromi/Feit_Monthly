delete Fact_Feit_Monthly t  where t.montha in (&x);

DECLARE
   CURSOR feit_cursor IS SELECT * FROM fact_feit_contract;

BEGIN
  for feit_item in feit_cursor
  LOOP
      begin
      feit_monthly( feit_item.terminalserialid, feit_item.marketerid , feit_item.FSDATE,feit_item.FEDATE,feit_item.CSDATE,feit_item.CEDATE);
      end;
  END LOOP;
END;
