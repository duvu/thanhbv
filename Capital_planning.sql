create PROCEDURE "CAP_LOAD" (P_CP_SCENARIO_ID in varchar2, P_SNAPSHOT_DATE in date, 
                                        P_LOAD_JOB_NBR in integer, P_SCENARIO_ID in varchar2, P_INTER_COMPANY in varchar2)
  IS
  
  SUM_RWA NUMBER(24,2) := 0;            -- sum of RWA amounts
  
  BEGIN
  
    /*************************************************************/
    /* UPDATE CAP_RWA                                            */
    /*************************************************************/
    
    /* REMOVE ANY EXISTING DATA                                  */
    DELETE FROM CAP_RWA cr
    WHERE cr.CP_SCENARIO_ID = P_CP_SCENARIO_ID 
      AND cr.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
      AND cr.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
      AND cr.SCENARIO_ID = P_SCENARIO_ID 
      AND cr.INTER_COMPANY = P_INTER_COMPANY;  

    /* ADD CR ASSET CLASSES                                      */
    INSERT INTO CAP_RWA (
          CP_SCENARIO_ID,
          SNAPSHOT_DATE,
          LOAD_JOB_NBR,
          SCENARIO_ID,
          INTER_COMPANY,
          ASSET_CLASS,
          EAD_BASE,
          RW_BASE,
          RWA_BASE,
          EAD_PCT_CHG,
          EAD_ABS_CHG,
          RW_PCT_CHG,
          RW_ABS_CHG,
          RWA_CHG,
          RWA_CHG_YEAR1,
          RWA_CHG_YEAR2,
          RWA_CHG_YEAR3,
          EAD_SEN,
          RW_SEN,
          RWA_SEN
        )
    SELECT P_CP_SCENARIO_ID,
           P_SNAPSHOT_DATE,
           P_LOAD_JOB_NBR,
           P_SCENARIO_ID,
           P_INTER_COMPANY,
           tbl.ASSET_CLASS,
           tbl.EAD_BASE,
           null,
           tbl.RWA_BASE,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           tbl.EAD_SEN,
           NULL,
           tbl.RWA_SEN
    FROM (
        SELECT COALESCE(
                 CASE WHEN sbv.HEADING IN ('SOVEREIGN') THEN 'SOV' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('FINANCIAL_INSTIT') THEN 'FI' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('CORP') THEN 'CORP' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('RETAIL') THEN 'RET' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('MORTGAGES') THEN 'MORT' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('LOANS_SECURED_BY_REAL_ESTATE') THEN 'RE' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('NON-PERFORM_CLAIMS') THEN 'NP' ELSE NULL END,
                 CASE WHEN sbv.HEADING IN ('OTH_ONB') THEN 'OTH' ELSE NULL END
             ) as                                                               ASSET_CLASS,
               sbv.EXPOSURE_VALUE_LCY_AMT as                                    EAD_BASE,
               sbv.RWA_LCY_AMT as                                               RWA_BASE,
               sbv.EXPOSURE_VALUE_LCY_AMT as                                    EAD_SEN,
               sbv.RWA_LCY_AMT as                                               RWA_SEN
               
        FROM SBV_SUMMARY sbv
        WHERE sbv.HEADING IN ('SOVEREIGN','FINANCIAL_INSTIT','CORP','RETAIL','MORTGAGES','LOANS_SECURED_BY_REAL_ESTATE',
                              'NON-PERFORM_CLAIMS', 'OTH_ONB') AND
          sbv.SNAPSHOT_DATE = P_SNAPSHOT_DATE AND
          sbv.LOAD_JOB_NBR = P_LOAD_JOB_NBR AND
          sbv.SCENARIO_ID = P_SCENARIO_ID AND
          sbv.INTER_COMPANY = P_INTER_COMPANY AND
              (sbv.SBV_SUMMARY_TYPE LIKE 'SUMMARY%' OR sbv.SBV_SUMMARY_TYPE LIKE 'TOTAL%')
      ) tbl;  

 /* ADD CCR ASSET CLASSES                                     */
    INSERT INTO CAP_RWA (
          CP_SCENARIO_ID,
          SNAPSHOT_DATE,
          LOAD_JOB_NBR,
          SCENARIO_ID,
          INTER_COMPANY,
          ASSET_CLASS,
          EAD_BASE,
          RW_BASE,
          RWA_BASE,
          EAD_PCT_CHG,
          EAD_ABS_CHG,
          RW_PCT_CHG,
          RW_ABS_CHG,
          RWA_CHG,
          RWA_CHG_YEAR1,
          RWA_CHG_YEAR2,
          RWA_CHG_YEAR3,
          EAD_SEN,
          RW_SEN,
          RWA_SEN
        )
    SELECT P_CP_SCENARIO_ID,
           P_SNAPSHOT_DATE,
           P_LOAD_JOB_NBR,
           P_SCENARIO_ID,
           P_INTER_COMPANY,
           'CCR',
           tbl.EAD_BASE,
           null,
           tbl.RWA_BASE,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           tbl.EAD_SEN,
           null,
           tbl.RWA_SEN
           
      FROM (   
            SELECT  
               sum(sbv.EXPOSURE_VALUE_LCY_AMT) as EAD_BASE,
               sum(sbv.RWA_LCY_AMT) as RWA_BASE,
               sum(sbv.EXPOSURE_VALUE_LCY_AMT) as EAD_SEN,
               sum(sbv.RWA_LCY_AMT) as RWA_SEN
               
        FROM SBV_SUMMARY sbv
        WHERE sbv.HEADING IN ('CCR', 'CCR_REPO', 'CR_REPO') 
          AND sbv.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
          AND sbv.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
          AND sbv.SCENARIO_ID = P_SCENARIO_ID 
          AND sbv.INTER_COMPANY = P_INTER_COMPANY 
          AND (sbv.SBV_SUMMARY_TYPE LIKE 'SUMMARY%' OR sbv.SBV_SUMMARY_TYPE LIKE 'TOTAL%')
      ) tbl;  
  
    /* ADD MR ASSET CLASS                                       */
    INSERT INTO CAP_RWA (
          CP_SCENARIO_ID,
          SNAPSHOT_DATE,
          LOAD_JOB_NBR,
          SCENARIO_ID,
          INTER_COMPANY,
          ASSET_CLASS,
          EAD_BASE,
          RW_BASE,
          RWA_BASE,
          EAD_PCT_CHG,
          EAD_ABS_CHG,
          RW_PCT_CHG,
          RW_ABS_CHG,
          RWA_CHG,
          RWA_CHG_YEAR1,
          RWA_CHG_YEAR2,
          RWA_CHG_YEAR3,
          EAD_SEN,
          RW_SEN,
          RWA_SEN
        )
    SELECT P_CP_SCENARIO_ID,
           P_SNAPSHOT_DATE,
           P_LOAD_JOB_NBR,
           P_SCENARIO_ID,
           P_INTER_COMPANY,
           'MR',
           tbl.EAD_BASE,
           null,
           tbl.RWA_BASE,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           tbl.EAD_SEN,
           NULL,
           tbl.RWA_SEN
    FROM (
        SELECT   
               sum(sbv.EXPOSURE_VALUE_LCY_AMT) as EAD_BASE,
               sum(sbv.RWA_LCY_AMT) as RWA_BASE,
               sum(sbv.EXPOSURE_VALUE_LCY_AMT) as EAD_SEN,
               sum(sbv.RWA_LCY_AMT) as RWA_SEN
                
        FROM SBV_SUMMARY sbv
        WHERE sbv.HEADING IN ('FX_RISK', 'IRR_SPC', 'IRR_GNR', 'COMMODITY_RISK', 'OPTION_RISK' ) 
          AND sbv.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
          AND sbv.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
          AND sbv.SCENARIO_ID = P_SCENARIO_ID 
          AND sbv.INTER_COMPANY = P_INTER_COMPANY 
          AND (sbv.SBV_SUMMARY_TYPE LIKE 'SUMMARY%' OR sbv.SBV_SUMMARY_TYPE LIKE 'TOTAL%')
      ) tbl;   


 /* ADD OR ASSET CLASS                                       */
    INSERT INTO CAP_RWA (
          CP_SCENARIO_ID,
          SNAPSHOT_DATE,
          LOAD_JOB_NBR,
          SCENARIO_ID,
          INTER_COMPANY,
          ASSET_CLASS,
          EAD_BASE,
          RW_BASE,
          RWA_BASE,
          EAD_PCT_CHG,
          EAD_ABS_CHG,
          RW_PCT_CHG,
          RW_ABS_CHG,
          RWA_CHG,
          RWA_CHG_YEAR1,
          RWA_CHG_YEAR2,
          RWA_CHG_YEAR3,
          EAD_SEN,
          RW_SEN,
          RWA_SEN
        )
    SELECT P_CP_SCENARIO_ID,
           P_SNAPSHOT_DATE,
           P_LOAD_JOB_NBR,
           P_SCENARIO_ID,
           P_INTER_COMPANY,
           'OR',
           tbl.EAD_BASE,
           null,
           tbl.RWA_BASE,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           EAD_SEN,
           NULL,
           RWA_SEN
    FROM (
        SELECT   
               sbv.EXPOSURE_VALUE_LCY_AMT as EAD_BASE,
               sbv.RWA_LCY_AMT as RWA_BASE,
               sbv.EXPOSURE_VALUE_LCY_AMT as EAD_SEN,
               sbv.RWA_LCY_AMT as RWA_SEN
                
        FROM SBV_SUMMARY sbv
        WHERE sbv.HEADING = 'OPS_SUM_TOTAL' 
          AND sbv.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
          AND sbv.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
          AND sbv.SCENARIO_ID = P_SCENARIO_ID 
          AND sbv.INTER_COMPANY = P_INTER_COMPANY 
          AND (sbv.SBV_SUMMARY_TYPE LIKE 'SUMMARY%' OR sbv.SBV_SUMMARY_TYPE LIKE 'TOTAL%')
      ) tbl;  
      
   /* UPDATE RW VALUES                                       */   
      UPDATE CAP_RWA rwa
      SET rwa.RW_BASE = (CASE WHEN rwa.RWA_BASE <> 0 THEN rwa.RWA_BASE / rwa.EAD_BASE ELSE 0 END),
          rwa.RW_SEN = (CASE WHEN rwa.RWA_SEN <> 0 THEN rwa.RWA_SEN / rwa.EAD_SEN ELSE 0 END)
      
        WHERE rwa.CP_SCENARIO_ID = P_CP_SCENARIO_ID  
          AND rwa.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
          AND rwa.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
          AND rwa.SCENARIO_ID = P_SCENARIO_ID 
          AND rwa.INTER_COMPANY = P_INTER_COMPANY;  


    /**************************************************************************/
    
    /*************************************************************/
    /* UPDATE CAP_CAPITAL                                        */
    /*************************************************************/
    
    /* REMOVE ANY EXISTING DATA                                  */

   DELETE FROM CAP_CAPITAL cc
      WHERE cc.CP_SCENARIO_ID = P_CP_SCENARIO_ID 
        AND cc.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
        AND cc.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
        AND cc.SCENARIO_ID = P_SCENARIO_ID 
        AND cc.INTER_COMPANY = P_INTER_COMPANY;  
        
    /* ADD CAPITAL DATA                                          */
   INSERT INTO CAP_CAPITAL (
              CP_SCENARIO_ID,
              SNAPSHOT_DATE,
              LOAD_JOB_NBR,
              SCENARIO_ID,
              INTER_COMPANY,
              CAP_TIER_1_BASE,
              CAP_TIER_2_BASE,
              CAP_TOTAL_BASE ,
              CAP_TIER_1_PCT_CHG,
              CAP_TIER_1_ABS_CHG,
              CAP_TIER_2_PCT_CHG,
              CAP_TIER_2_ABS_CHG,
              CAP_TIER_1_CHG_AMT,
              CAP_TIER_2_CHG_AMT,
              CAP_TIER_1_CHG_YEAR1,
              CAP_TIER_2_CHG_YEAR1,
              CAP_TOTAL_CHG_YEAR1,
              CAP_TIER_1_CHG_YEAR2,
              CAP_TIER_2_CHG_YEAR2,
              CAP_TOTAL_CHG_YEAR2,
              CAP_TIER_1_CHG_YEAR3,
              CAP_TIER_2_CHG_YEAR3,
              CAP_TOTAL_CHG_YEAR3,
              CAP_TIER_1_SEN,
              CAP_TIER_2_SEN,
              CAP_TOTAL_SEN,
              CAR_TIER_1_BASE,
              CAR_TOTAL_BASE,
              CAR_TIER_1_SEN,
              CAR_TOTAL_SEN
      )
  SELECT P_CP_SCENARIO_ID,
           P_SNAPSHOT_DATE,
           P_LOAD_JOB_NBR,
           P_SCENARIO_ID,
           P_INTER_COMPANY,
           tbl.CAP_TIER_1_BASE,                                   -- CAP_TIER_1_BASE,
           tbl.CAP_TIER_2_BASE - nvl(DEDUCT_OTH,0),               -- CAP_TIER_2_BASE,
           tbl.CAP_TOTAL_BASE,                                    -- CAP_TOTAL_BASE ,
           0,                                                     -- CAP_TIER_1_PCT_CHG,
           0,                                                     -- CAP_TIER_1_ABS_CHG,
           0,                                                     -- CAP_TIER_2_PCT_CHG,
           0,                                                     -- CAP_TIER_2_ABS_CHG,
           0,                                                     -- CAP_TIER_1_CHG_AMT,
           0,                                                     -- CAP_TIER_2_CHG_AMT,
           0,                                                     -- CAP_TIER_1_CHG_YEAR1,
           0,                                                     -- CAP_TIER_2_CHG_YEAR1,
           0,                                                     -- CAP_TOTAL_CHG_YEAR1,
           0,                                                     -- CAP_TIER_1_CHG_YEAR2,
           0,                                                     -- CAP_TIER_2_CHG_YEAR2,
           0,                                                     -- CAP_TOTAL_CHG_YEAR2,
           0,                                                     -- CAP_TIER_1_CHG_YEAR3,
           0,                                                     -- CAP_TIER_2_CHG_YEAR3,
           0,                                                     -- CAP_TOTAL_CHG_YEAR3,
           tbl.CAP_TIER_1_SEN,                                    -- CAP_TIER_1_SEN,
           tbl.CAP_TIER_2_SEN - nvl(DEDUCT_OTH,0),                -- CAP_TIER_2_SEN,
           tbl.CAP_TOTAL_SEN,                                     -- CAP_TOTAL_SEN,
           NULL,                                                  -- CAR_TIER_1_BASE,
           NULL,                                                  -- CAR_TOTAL_BASE,
           NULL,                                                  -- CAR_TIER_1_SEN,
           NULL                                                   -- CAR_TOTAL_SEN
  FROM (SELECT t1.CAP_TIER_1_BASE,
               t1.CAP_TIER_2_BASE,
               t1.CAP_TOTAL_BASE,
               t1.CAP_TIER_1_SEN,
               t1.CAP_TIER_2_SEN,
               t1.CAP_TOTAL_SEN,
               t1.DEDUCT_OTH
                
        FROM (SELECT MAX(CASE
                           WHEN sbv.HEADING = 'TIER_1_CAP_AFTER_DEDUCT'
                                   THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TIER_1_BASE,
                     MAX(CASE
                           WHEN sbv.HEADING = 'TIER_2_CAP_AFTER_DEDUCT' THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TIER_2_BASE,
                     MAX(CASE
                           WHEN sbv.HEADING = 'TOTAL_CAP_AFTER_DEDUCT' THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TOTAL_BASE,     
                     MAX(CASE
                           WHEN sbv.HEADING = 'TIER_1_CAP_AFTER_DEDUCT'
                                   THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TIER_1_SEN,
                     MAX(CASE
                           WHEN sbv.HEADING = 'TIER_2_CAP_AFTER_DEDUCT' THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TIER_2_SEN,
                     MAX(CASE
                           WHEN sbv.HEADING = 'TOTAL_CAP_AFTER_DEDUCT' THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   CAP_TOTAL_SEN,
                    MAX(CASE
                           WHEN sbv.HEADING = 'DEDUCT_OTH' THEN 0 - sbv.EXPOSURE_VALUE_LCY_AMT
                           ELSE 0 END)   DEDUCT_OTH    
                      
              FROM SBV_SUMMARY sbv
              WHERE sbv.SNAPSHOT_DATE = P_SNAPSHOT_DATE
                AND sbv.LOAD_JOB_NBR = P_LOAD_JOB_NBR
                AND sbv.SCENARIO_ID = P_SCENARIO_ID
                AND sbv.INTER_COMPANY = P_INTER_COMPANY
                AND sbv.SBV_SUMMARY_TYPE LIKE 'SUMMARY%')
                 t1
       ) tbl;   
       
       /* UPDATE CAR VALUES                                       */   
       
      SUM_RWA := 0;
      SELECT  SUM(RWA_BASE) INTO SUM_RWA FROM CAP_RWA rwa WHERE rwa.CP_SCENARIO_ID = P_CP_SCENARIO_ID  
                                                           AND rwa.SNAPSHOT_DATE = P_SNAPSHOT_DATE
                                                           AND rwa.LOAD_JOB_NBR = P_LOAD_JOB_NBR  
                                                           AND rwa.SCENARIO_ID = P_SCENARIO_ID 
                                                           AND rwa.INTER_COMPANY = P_INTER_COMPANY;
                                                           
      UPDATE CAP_CAPITAL cap
      SET cap.CAR_TIER_1_BASE = cap.CAP_TIER_1_BASE / SUM_RWA,
          cap.CAR_TOTAL_BASE = cap.CAP_TOTAL_BASE / SUM_RWA,
          cap.CAR_TIER_1_SEN = cap.CAP_TIER_1_BASE / SUM_RWA,
          cap.CAR_TOTAL_SEN = cap.CAP_TOTAL_BASE / SUM_RWA
    
        WHERE cap.CP_SCENARIO_ID = P_CP_SCENARIO_ID  
          AND cap.SNAPSHOT_DATE = P_SNAPSHOT_DATE 
          AND cap.LOAD_JOB_NBR = P_LOAD_JOB_NBR 
          AND cap.SCENARIO_ID = P_SCENARIO_ID 
          AND cap.INTER_COMPANY = P_INTER_COMPANY;    
       

  END CAP_LOAD;
/



create PROCEDURE "CAP_CALC" (P_CP_SCENARIO_ID in varchar2, P_SNAPSHOT_DATE in date,
                                        P_LOAD_JOB_NBR in integer, P_SCENARIO_ID in varchar2, P_INTER_COMPANY in varchar2)
  IS

  SUM_RWA NUMBER(24,2) := 0;            -- sum of RWA amounts

  BEGIN

  -- Update CAP_RWA
  -- Update the Total Change Amount and then apply to generate the new SEN RWA AMT
    UPDATE CAP_RWA rwa
    SET RWA_CHG = RWA_BASE - (CASE WHEN EAD_PCT_CHG <> 0 THEN EAD_BASE * (1 + EAD_PCT_CHG) ELSE EAD_BASE + EAD_ABS_CHG END)
                        * (CASE WHEN RW_PCT_CHG <> 0 THEN RW_BASE * (1 + RW_PCT_CHG) ELSE RW_BASE + RW_ABS_CHG END),
    /*RWA_BASE - 
        (CASE WHEN EAD_PCT_CHG <> 0 THEN EAD_BASE * (EAD_PCT_CHG) ELSE 
              CASE WHEN EAD_ABS_CHG <> 0 THEN (EAD_BASE + EAD_ABS_CHG) ELSE 
                   CASE WHEN RW_PCT_CHG <> 0 OR RW_ABS_CHG <> 0 THEN EAD_BASE ELSE 0 END END END)
              * (CASE WHEN RW_PCT_CHG <> 0 THEN RW_BASE * (1 + RW_PCT_CHG) ELSE CASE WHEN RW_ABS_CHG <> 0 THEN RW_BASE + RW_ABS_CHG ELSE 1 END END),*/
        RW_SEN = (CASE WHEN RW_PCT_CHG <> 0 THEN RW_BASE * (1 + RW_PCT_CHG) ELSE RW_BASE + RW_ABS_CHG END),
        EAD_SEN = (CASE WHEN EAD_PCT_CHG <> 0 THEN EAD_BASE * (1 + EAD_PCT_CHG) ELSE EAD_BASE + EAD_ABS_CHG END),
        RWA_SEN = (CASE WHEN EAD_PCT_CHG <> 0 THEN EAD_BASE * (1 + EAD_PCT_CHG) ELSE EAD_BASE + EAD_ABS_CHG END)
                        * (CASE WHEN RW_PCT_CHG <> 0 THEN RW_BASE * (1 + RW_PCT_CHG) ELSE RW_BASE + RW_ABS_CHG END)

        WHERE rwa.CP_SCENARIO_ID = P_CP_SCENARIO_ID
           AND rwa.SNAPSHOT_DATE = P_SNAPSHOT_DATE
           AND rwa.LOAD_JOB_NBR = P_LOAD_JOB_NBR
           AND rwa.SCENARIO_ID = P_SCENARIO_ID
           AND rwa.INTER_COMPANY = P_INTER_COMPANY
           AND rwa.ASSET_CLASS IN ('SOV', 'FI', 'CORP', 'RET', 'MORT', 'RE', 'NP', 'OTH')

           ;

    -- Update to generate the new SEN RWA AMT for 'CCR', 'MR', 'OR'
    UPDATE CAP_RWA rwa
    SET
        RWA_SEN =   RWA_BASE  + RWA_CHG

        WHERE rwa.CP_SCENARIO_ID = P_CP_SCENARIO_ID
           AND rwa.SNAPSHOT_DATE = P_SNAPSHOT_DATE
           AND rwa.LOAD_JOB_NBR = P_LOAD_JOB_NBR
           AND rwa.SCENARIO_ID = P_SCENARIO_ID
           AND rwa.INTER_COMPANY = P_INTER_COMPANY
           AND rwa.ASSET_CLASS IN  ('CCR', 'MR', 'OR')

           ;


    -- Calculate Total SEN RWA_AMT
      SUM_RWA := 0;
      SELECT  SUM(RWA_SEN) INTO SUM_RWA FROM CAP_RWA rwa WHERE rwa.CP_SCENARIO_ID = P_CP_SCENARIO_ID
                                                           AND rwa.SNAPSHOT_DATE = P_SNAPSHOT_DATE
                                                           AND rwa.LOAD_JOB_NBR = P_LOAD_JOB_NBR
                                                           AND rwa.SCENARIO_ID = P_SCENARIO_ID
                                                           AND rwa.INTER_COMPANY = P_INTER_COMPANY
                                                           ;


  -- Update CAP_CAPITAL
    UPDATE CAP_CAPITAL cap
    SET CAP_TIER_1_CHG_AMT = (CASE WHEN CAP_TIER_1_PCT_CHG <> 0 THEN CAP_TIER_1_BASE * CAP_TIER_1_PCT_CHG ELSE CAP_TIER_1_ABS_CHG END),
        CAP_TIER_2_CHG_AMT = (CASE WHEN CAP_TIER_2_PCT_CHG <> 0 THEN CAP_TIER_2_BASE * CAP_TIER_2_PCT_CHG ELSE CAP_TIER_2_ABS_CHG END),
        CAP_TOTAL_CHG_YEAR1 = CAP_TIER_1_CHG_YEAR1 + CAP_TIER_2_CHG_YEAR1,
        CAP_TOTAL_CHG_YEAR2 = CAP_TIER_1_CHG_YEAR2 + CAP_TIER_2_CHG_YEAR2,
        CAP_TOTAL_CHG_YEAR3 = CAP_TIER_1_CHG_YEAR3 + CAP_TIER_2_CHG_YEAR3,
        CAP_TIER_1_SEN = (CASE WHEN CAP_TIER_1_PCT_CHG <> 0 THEN CAP_TIER_1_BASE * (1+ CAP_TIER_1_PCT_CHG) ELSE CAP_TIER_1_BASE + CAP_TIER_1_ABS_CHG END),
        CAP_TIER_2_SEN = (CASE WHEN CAP_TIER_2_PCT_CHG <> 0 THEN CAP_TIER_2_BASE * (1+ CAP_TIER_2_PCT_CHG) ELSE CAP_TIER_2_BASE + CAP_TIER_2_ABS_CHG END),
        CAP_TOTAL_SEN = (CASE WHEN CAP_TIER_1_PCT_CHG <> 0 THEN CAP_TIER_1_BASE * (1+ CAP_TIER_1_PCT_CHG) ELSE CAP_TIER_1_BASE + CAP_TIER_1_ABS_CHG END) +
            (CASE WHEN CAP_TIER_2_PCT_CHG <> 0 THEN CAP_TIER_2_BASE * (1+ CAP_TIER_2_PCT_CHG) ELSE CAP_TIER_2_BASE + CAP_TIER_2_ABS_CHG END),
        CAR_TIER_1_SEN = (CASE WHEN CAP_TIER_1_PCT_CHG <> 0 THEN CAP_TIER_1_BASE * (1+ CAP_TIER_1_PCT_CHG) ELSE CAP_TIER_1_BASE + CAP_TIER_1_ABS_CHG END) /
            SUM_RWA,
        CAR_TOTAL_SEN = ((CASE WHEN CAP_TIER_1_PCT_CHG <> 0 THEN CAP_TIER_1_BASE * (1+ CAP_TIER_1_PCT_CHG) ELSE CAP_TIER_1_BASE + CAP_TIER_1_ABS_CHG END) +
            (CASE WHEN CAP_TIER_2_PCT_CHG <> 0 THEN CAP_TIER_2_BASE * (1+ CAP_TIER_2_PCT_CHG) ELSE CAP_TIER_2_BASE + CAP_TIER_2_ABS_CHG END) ) / SUM_RWA

        WHERE cap.CP_SCENARIO_ID = P_CP_SCENARIO_ID
          AND cap.SNAPSHOT_DATE = P_SNAPSHOT_DATE
          AND cap.LOAD_JOB_NBR = P_LOAD_JOB_NBR
          AND cap.SCENARIO_ID = P_SCENARIO_ID
          AND cap.INTER_COMPANY = P_INTER_COMPANY
          ;

   COMMIT;

  END CAP_CALC;
/



