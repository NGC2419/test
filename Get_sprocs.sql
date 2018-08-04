USE [BDESime]
GO

/****** Object:  StoredProcedure [Sime].[GetLoan]    Script Date: 8/14/2017 11:50:00 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
  
CREATE PROCEDURE [Sime].[GetLoan]
    @loan_number NVARCHAR(15) ,
    @investors VARCHAR(255)
AS
    BEGIN 
	
        SELECT TOP 1
                RTRIM(LTRIM(loan.[LOAN NUMBER])) AS loan_id ,
                RTRIM(LTRIM(loan.[LOAN NUMBER])) AS loan_number ,
                loan.[TOTAL MONTHLY PAYMENT] AS total_monthly_pmt ,
                IIF(loan.[INVESTOR ID] IS NULL, '', loan.[INVESTOR ID]) AS investor_id ,
                IIF(lai.investor_sub_group IS NULL, '', RTRIM(LTRIM(lai.investor_sub_group))) AS investor_sub_group ,
                IIF(loan.[LO TYPE] IS NULL, '', loan.[LO TYPE]) AS loan_type ,
                IIF(lai.loan_sub_group IS NULL, '', RTRIM(LTRIM(lai.loan_sub_group))) AS loan_sub_group ,
                IIF(lai.loan_type_description IS NULL, '', RTRIM(LTRIM(lai.loan_type_description))) AS loan_type_description ,
                IIF(loan.[MERS ID] IS NULL, '', loan.[MERS ID]) AS mers_id , 
          TRY_PARSE(
                loan.[NEXT PAYMENT DUE DATE] AS DATETIME ) AS next_pmt_due ,
                loan.[FIRST PRINCIPAL BALANCE] AS first_principal_balance ,
                loan.[FIRST P AND I AMOUNT] AS first_principal_balance_int ,
                loan.[ANNUAL INTEREST RATE] AS interest_rate ,
          TRY_PARSE(
                loan.[LOAN MATURES DATE] AS DATETIME ) AS mature_date ,
          TRY_PARSE(
                loan.[MERS REGISTRATION DATE] AS DATETIME ) AS mers_registration_date ,
                IIF(loan.[ORIGINAL CREDIT QUALITY CODE] IS NULL, '', loan.[ORIGINAL CREDIT QUALITY CODE]) AS original_credit_score ,
                lai.welcome_call welcome_call , -- not used
                lai.welcome_call_date welcome_call_date ,
                IIF(lai.investor_fullname IS NULL, '', lai.investor_fullname) AS investor_fullname ,
          TRY_PARSE(
                loan.[PAYMENT IN FULL DATE] AS DATETIME ) AS pif_date ,
          TRY_PARSE(
                loan.[PAYOFF EFFECTIVE DATE] AS DATETIME ) AS pif_effective_date ,
                IIF(loan.[PAYMENT IN FULL STOP CODE] IS NULL, '', loan.[PAYMENT IN FULL STOP CODE]) AS pif_code ,
           
          TRY_PARSE(
                loan.[LAST TRAN DATE] AS DATETIME ) AS last_tran_date ,
				  TRY_PARSE(
                loan.[ASSUMPTION DATE] AS DATETIME ) AS assumption_date ,
          TRY_PARSE(
                loan.[SALE DATE] AS DATETIME ) AS sale_date ,
                loan.[LOAN TO VALUE RATIO] AS ltv_ratio ,
                IIF(loan.[ASSUMPTION CODE] IS NULL, '', loan.[ASSUMPTION CODE]) AS assumable ,
                IIF(loan.[ASSUMPTION CODE] IS NULL
                OR loan.[ASSUMPTION CODE] = '', 1, 0) AS is_assumable ,
                lai.closing_date AS closing_date ,
                GETDATE() AS created ,
                GETDATE() AS updated ,
                ( SELECT TOP 1
                            IIF([IS COMPARE] IS NULL, 0, IIF([IS COMPARE] = 1, 1, 0))
                  FROM      BDESIME.dbo.delinquency_snapshot ds WITH ( NOLOCK )
                  WHERE     ds.[LOAN NUMBER] = loan.[LOAN NUMBER]
                  ORDER BY  ds.[LOAN DATE] DESC
                ) AS compare_ratio ,
                loan.load_date ,
                lai.loan_program AS loan_program ,
                lai.escrow_count ,
                lai.call_count ,
                lai.payment_count ,
                lai.task_count ,
                lai.collection_comment_count ,
                lai.lossmit_count ,
                lai.letter_count ,
                lai.long_comment_count ,
                lai.ptp_count ,
                lai.pay_plan_count ,
                lai.reo_count ,
                lai.average_payment_day ,
                lai.otd_count ,
                lai.drafting_count ,
                lai.fee_count ,
                lai.disbursements_count ,
                ISNULL([ACCRUED LATE CHARGE AMOUNT], 0) AS late_charge ,
                ISNULL([NSF FEE BALANCE], 0) AS fee_balance ,
                IIF([BILLING TABLE POSITION 04] = '1', 1, 0) e_estatement ,
                IIF([loan].[OPT OUT SOLICITATION STOP CODE] = '1' , 1,0) privacy_opt,
				lai.year_end_tax,
				loan.[SUSPENSE BALANCE] suspense_balance
        FROM    loan loan WITH ( NOLOCK )
                LEFT JOIN Sime.LoanAdditionalInfo lai ON loan.[LOAN NUMBER] = lai.loan_number
        WHERE   loan.[LOAN NUMBER] = @loan_number
                AND lai.investor_code IN (
                SELECT  *
                FROM    fnMultiValueSplit(@investors, ',') )
    END 














GO

/****** Object:  StoredProcedure [Sime].[GetLoanCallRecordings]    Script Date: 8/14/2017 11:50:00 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
CREATE PROCEDURE [Sime].[GetLoanCallRecordings] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
      
  
                SELECT  fa2.[Loan Number] Loan_Number ,
                        fa2.SID AS id ,
                        ( SELECT    COUNT(SID)
                          FROM      BDE_Data.dbo.five9_activity f
                          WHERE     f.[CALL ID] = fa2.[CALL ID]
                        ) AS parts ,
                        fa2.[TIMESTAMP] AS start_time ,
                        fa2.[CALL ID] CALL_ID ,
                        fa2.CAMPAIGN AS campaign ,
                        IIF(fa2.[CALL TYPE] IS NULL, '', fa2.[CALL TYPE]) AS call_type ,
                        IIF(fa2.AGENT IS NULL, '', fa2.AGENT) AS agent ,
                        fa2.[CALL TIME] AS call_time ,
                        fa2.[BILL TIME (ROUNDED)] AS bill_time ,
                        IIF(fa2.[AGENT NAME] IS NULL, '', fa2.[AGENT NAME]) AS agent_name ,
                        fa2.[CALL RECORDING PATH] AS path ,
                        fa2.[CALL RECORDING STATUS] AS status ,
                        IIF(fa2.NOTES IS NULL, '', fa2.NOTES) AS notes ,
                        GETDATE() AS created ,
                        GETDATE() AS updated ,
                        ISNULL(fa2.DISPOSITION, '') AS disposition ,
                        CASE LOWER(ISNULL(fa2.[CALL TYPE], ''))
                          WHEN 'inbound' THEN fa2.ANI
                          WHEN 'inbound voicemail' THEN fa2.ANI
                          WHEN 'internal' THEN fa2.ANI
                          WHEN '3rd party conference' THEN fa2.DNIS
                          WHEN '3rd party transfer' THEN fa2.DNIS
                          WHEN 'manual' THEN fa2.DNIS
                          WHEN 'outbound' THEN fa2.DNIS
                          WHEN 'preview' THEN fa2.DNIS
                          WHEN 'queue callback' THEN fa2.DNIS
                          WHEN 'skill call' THEN fa2.DNIS
                          WHEN 'test manual' THEN fa2.DNIS
                          ELSE fa2.DNIS
                        END AS phone ,
                        fa2.STORAGE
                FROM    BDE_Data.dbo.five9_activity fa2
                WHERE   fa2.[Loan Number] = @ln AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
                ORDER BY SID DESC
              
            END 
      




GO

/****** Object:  StoredProcedure [Sime].[GetLoanCollectionComments]    Script Date: 8/14/2017 11:50:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 
 
CREATE PROCEDURE [Sime].[GetLoanCollectionComments] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
        IF EXISTS ( SELECT  *
                    FROM    [dbo].[ListLoansForClient](@investors) ml
                    WHERE   ml.[Loan Number] = @ln )
            BEGIN
  
                SELECT  [cc].[LOAN NUMBER] loan_number,
                        IIF(cc.[COLLECTION COMMENTS KEY 1] IS NULL, '', CONVERT(NVARCHAR, cc.[COLLECTION COMMENTS KEY 1]))
                        + '-' + ISNULL(cc.[COLLECTION COMMENTS KEY 2], '')
                        + '-' + ISNULL([COMMENT NSF TYPE], '') + '-'
                        + ISNULL(cc.[COMMENT LETTER NUMBER], '')
                        + ISNULL(cc.[COMMENT LETTER CODE], '') COLLATE Latin1_General_CS_AS AS id ,
             
           TRY_PARSE(
                        cc.[COMMENT ADDED DATE] AS DATETIME ) AS added ,
                        cc.[COMMENT ADDED TIME] AS added_time ,
                        IIF(cc.[COMMENT RESPONSE CODE] IS NULL, '', cc.[COMMENT RESPONSE CODE]) AS response_code ,
                        IIF(cc.[COMMENT RESPONSE DESCRIPTION] IS NULL, '', cc.[COMMENT RESPONSE DESCRIPTION]) AS response_code_desc ,
                        IIF(cc.[COMMENT REASON DESCRIPTION] IS NULL, '', cc.[COMMENT REASON DESCRIPTION]) AS reason ,
                        cc.[COMMENT FORBEARANCE AMOUNT] AS forebeareance_amount ,
                        IIF(cc.[COMMENT LONG DESCRIPTION LINE1] IS NULL, '', cc.[COMMENT LONG DESCRIPTION LINE1]) AS comment_1 ,
                        IIF(cc.[COMMENT LONG DESCRIPTION LINE2] IS NULL, '', cc.[COMMENT LONG DESCRIPTION LINE2]) AS comment_2 ,
                        IIF(cc.[COMMENT LONG DESCRIPTION LINE3] IS NULL, '', cc.[COMMENT LONG DESCRIPTION LINE3]) AS comment_3 ,
           TRY_PARSE(
                        cc.[COMMENT REMINDER DATE] AS DATETIME ) AS reminder_date ,
                        GETDATE() AS created ,
                        GETDATE() AS updated ,
                        SID ,
                        load_date ,
                        cc.delta_file_byte
                FROM    collection_comment cc
                WHERE   cc.[LOAN NUMBER] = @ln
              
            END 
    END



GO

/****** Object:  StoredProcedure [Sime].[GetLoanCollections]    Script Date: 8/14/2017 11:50:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
CREATE PROCEDURE [Sime].[GetLoanCollections] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
        IF EXISTS ( SELECT * FROM [dbo].[ListLoansForClient](@investors) ml
                             WHERE  ml.[LOAN NUMBER] = @ln) 
            BEGIN
  
                 SELECT ISNULL([COLLECT OTHER FEES DUE AMOUNT], 0),  
            GETDATE() AS created ,
            GETDATE() AS updated ,
            SID ,
            co.load_date
    FROM    collections co WHERE co.[LOAN NUMBER]=@ln
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
    END

	 

GO

/****** Object:  StoredProcedure [Sime].[GetLoanEscrow]    Script Date: 8/14/2017 11:50:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




 
 
CREATE PROCEDURE [Sime].[GetLoanEscrow] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
        
  
                 SELECT  esc.[loan number] , -- loan_id - uniqueidentifier 
            esc.[ESCROW ADVANCE BALANCE] AS adv_balance ,
            esc.[ESCROW BALANCE] AS balance ,
            esc.[DISBURSEMENT STOP] AS disb_stop_code ,
                TRY_PARSE(
            esc.[LAST ANALYSIS DATE] AS DATETIME ) AS last_anal_date ,
            esc.[ESCROW MINIMUM BALANCE COUNT] AS min_balance_qty ,
            esc.[LAST ANALYSIS OS AMOUNT] AS last_anal_os_amt ,
            esc.[LAST ANALYSIS OS SPREAD MONTHS] AS last_anal_spd_qty ,
                TRY_PARSE(
            esc.[LAST ANALYSIS EFFECTIVE DATE] AS DATETIME ) last_anal_ef_date ,
            esc.[ASSESSMENT TAX MONTHLY AMOUNT] AS assmnt_mth_am ,
            esc.[ASSESSMENT TAX TOTAL AMOUNT] AS assmnt_tot_am ,
            esc.[CITY TAX MONTHLY AMOUNT] AS city_tax_mth_am ,
            esc.[CITY TAX TOTAL AMOUNT] AS city_tax_tot_am ,
            esc.[CITY TAX AMOUNT] AS city_tax_am ,
            esc.[COUNTY TAX MONTHLY AMOUNT] AS cnty_tax_mth_am ,
            esc.[COUNTY TAX TOTAL AMOUNT] AS cnty_tax_tot_am ,
            esc.[COUNTY TAX AMOUNT] AS county_tax_am ,
            esc.[COUPON MONTH] AS coupon_mth_no ,
            esc.[ESCROW EXPD ADVANCE BALANCE] AS exp_adv_ba ,
            esc.[HUD PART BALANCE] AS hud_part_ba ,
TRY_PARSE(
            esc.[INITIAL ESCROW STATEMENT DATE] AS DATETIME )   AS init_stmt_dt ,
            esc.[LIEN AMOUNT] AS lien_am ,
            esc.[MISC ESCROW AMOUNT] AS misc_am ,  
TRY_PARSE(
            esc.[OVER OR SHORT STOP CHG DATE] AS DATETIME )     AS os_st_chg_dt ,
            esc.[OVER OR SHORT AMOUNT] AS over_short_am ,
            esc.[PENDING OVER OR SHORT AMOUNT] AS pend_os_am ,
            esc.[SCHOOL TAX MONTHLY AMOUNT] AS schl_tax_mth_am ,
            esc.[SCHOOL TAX TOTAL AMOUNT] AS schl_tax_tot_am ,
            esc.[T AND I MONTHLY AMOUNT] AS ti_mnthly_am ,
            esc.[UTILITY TAX MONTHLY AMOUNT] AS utility_mth_am ,
            esc.[UTILITY TAX TOTAL AMOUNT] AS utility_tot_am ,
            esc.[HAZARD INS MONTHLY AMOUNT] AS hz_mnthly_am ,
TRY_PARSE(
            esc.[DISBURSEMENT STOP CHANGE DATE] AS DATETIME )  AS disb_st_chg_dt ,
            esc.[EARTHQUAKE INS MONTHLY AMOUNT] AS equake_mth_am ,
            esc.[EARTHQUAKE INS TOTAL AMOUNT] AS equake_tot_am ,
            esc.[FIRE INS MONTHLY AMOUNT] AS fire_mth_am ,
            esc.[FIRE INS TOTAL AMOUNT] AS fire_tot_am ,
            esc.[FLOOD INS MONTHLY AMOUNT] AS flood_mth_am ,
            esc.[FLOOD INS TOTAL AMOUNT] AS flood_tot_am ,
            esc.[WINDSTORM INS MONTHLY AMOUNT] AS wind_mth_am ,
            esc.[WINDSTORM INS TOTAL AMOUNT] AS wind_tot_am ,
            GETDATE() AS created ,
            GETDATE() AS updated ,
            SID ,
            esc.load_date
    FROM    escrow esc WHERE esc.[LOAN NUMBER]=@ln
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
   




GO

/****** Object:  StoredProcedure [Sime].[GetLoanEscrowDisbursement]    Script Date: 8/14/2017 11:50:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






 
 
CREATE PROCEDURE [Sime].[GetLoanEscrowDisbursement] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
       
  
                SELECT  edt.[LOAN NUMBER] AS loan_number ,
                        edt.[LOAN NUMBER] + '-'
                        + CAST(ISNULL(edt.[DSB TRANSACTION DATE], '') AS NVARCHAR)
                        + '-'
                        + IIF(edt.[DSB SEQUENCE NUMBER] IS NULL, '', CONVERT(NVARCHAR, edt.[DSB SEQUENCE NUMBER])) AS id ,
                        edt.[DSB TRANSACTION DATE] AS transaction_date ,
                        edt.[DSB SEQUENCE NUMBER] AS seq_no ,
                        edt.[DSB ACTION CODE] AS action_code ,
                        edt.[DSB AMOUNT] AS amount ,
                        ISNULL(edt.[DSB BATCH NUMBER], '') AS batch_number ,
                        edt.[DSB PAYEE ID] AS payee_id ,
                        edt.[DSB TRANSACTION CODE] AS trans_code ,
                        edt.[DSB HUD FEE AMOUNT] AS hud_fee_amount ,
                        edt.[CLIENT NUMBER] AS client_number ,
                        TRY_PARSE(
                        edt.[DSB DUE DATE] AS DATETIME ) AS due_date ,
                        ISNULL(edt.[DSB CHECK NUMBER MICR PREFIX], '') AS micr_pre_no ,
                        ISNULL(edt.[DSB MANUAL CHECK INDICATOR], '') AS manual_ck_code ,
                        edt.[DSB CHECK NUMBER] AS dsb_check_no ,
                      
                        TRY_PARSE(
                        edt.[DSB EFFECTIVE DATE] AS DATETIME ) AS effective_date ,
                        edt.[DSB SUSPENSE AMOUNT] AS suspense_amount ,
                        edt.[DSB REASON CODE INVESTOR TYPE] AS rsn_code_inv_ty ,
                        ISNULL(py.[PAYEE ADDRESS LINE 1], '') AS payee_addr_line1 ,
                        ISNULL(py.[PAYEE ADDRESS LINE 2], '') AS payee_addr_line2 ,
                        ISNULL(py.[PAYEE ADDRESS LINE 3], '') AS payee_addr_line3 ,
                        ISNULL(py.[PAYEE ADDRESS LINE 4], '') AS payee_addr_line4 ,
                        ISNULL(py.[PAYEE ADDRESS ZIP CODE], '') AS payee_zip ,
                        ISNULL(py.[PAYEE ALPHA CODE], '') AS payee_alpha ,
                        ISNULL(py.[PAYEE PHONE NUMBER], '') AS payee_phone ,
                        ISNULL(py.[PAYEE PROPERTY ADDR INDICATOR], '') AS payee_prop_addr_code ,
                        ISNULL(py.[PAYEE INDEX KEY], '') AS payee_index_key ,
						ISNULL(py.[PAYEE CONTACT NAME], '') AS payee_name ,
                        edt.load_date , -- load_date - datetime
                        edt.SID  -- SID - bigint
                FROM    escrow_disb_tran edt
                        LEFT JOIN payee py ON edt.[DSB PAYEE ID] = py.[PAYEE ID]
                WHERE   edt.[LOAN NUMBER] = @ln AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
              
            
    END










GO

/****** Object:  StoredProcedure [Sime].[GetLoanFees]    Script Date: 8/14/2017 11:50:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




 
 
CREATE PROCEDURE [Sime].[GetLoanFees] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
      
  
          SELECT   
			fee.delta_file_byte, 
			fee.fee_tran_cd,  
			fee.fee_cd , 
			IIF(di.itemKey = NULL , fee_cd + ' (No translation found)',  di.itemValue) tran_description,
			TRY_PARSE(fee_tran_dt AS DATETIME) tran_date,
			fee_tran_am ,
			CASE ISNULL(fee.fee_tran_ty,'')
				WHEN 'A' THEN 'Added Fee' + IIF(delta_file_byte = 'D', ' (DELETED)','')
				WHEN 'W' THEN 'Waived'+ IIF(delta_file_byte = 'D',' (DELETED)' ,'')
				WHEN 'P' THEN 'Paid'+ IIF(delta_file_byte = 'D',' (DELETED)' ,'')
				WHEN ''  THEN IIF(delta_file_byte = 'D',' (DELETED)' ,'')
				ELSE
                fee_tran_ty + IIF(delta_file_byte = 'D',' (DELETED)' ,'')
				END AS fee_paid,
			fee.load_date,
            fee.SID
    FROM    BDE_Data.dbo.fee fee 
			LEFT JOIN bdesime.sime.DictionaryItems di ON fee_cd = di.itemkey AND  di.type =  34
			WHERE fee.ln_no = @ln  AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
     









GO

/****** Object:  StoredProcedure [Sime].[GetLoanLetters]    Script Date: 8/14/2017 11:50:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
 
CREATE PROCEDURE [Sime].[GetLoanLetters] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
      
  
          SELECT  lt.[LOAN NUMBER] + '-' + ISNULL(lt.[LETTER RECORD NUMBER], '') AS letter_id ,
            lt.[loan number] AS loan_number ,
            lt.[LETTER ID] AS letter_code ,
                       
            lt.[LETTER DATE]   AS letter_date ,
            lt.[LETTER SENDER ID] AS sender_id ,
            lt.[LETTER VERSION NUMBER] AS [version] ,
            lt.[CLIENT NUMBER] AS client_id ,
            lt.[LETTER DESCRIPTION] AS [description] ,
						TRY_PARSE(
            lt.[LETTER PROCESSING DATE] AS DATETIME ) AS processing_date ,
            lt.[LETTER RECORD NUMBER] AS record_number ,
            lt.[LETTER SOURCE CODE] AS source_code ,
            lt.load_date ,
            lt.SID
    FROM    letter_writer lt WHERE lt.[LOAN NUMBER]=@ln AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
     






GO

/****** Object:  StoredProcedure [Sime].[GetLoanLongComments]    Script Date: 8/14/2017 11:50:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
 
CREATE PROCEDURE [Sime].[GetLoanLongComments] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
        IF EXISTS ( SELECT * FROM [dbo].[ListLoansForClient](@investors) ml
                             WHERE  ml.[LOAN NUMBER] = @ln) 
            BEGIN
  
         SELECT  lc.[loan number] loan_number,
            lc.[LONG COMMENT KEY REC ID] long_comment_key_rec_id ,
            lc.[LONG COMMENT KEY DT TM TEXT] long_comment_key_dt_tm_text,
           TRY_PARSE(
            lc.[LONG COMMENT DATE] AS DATETIME ) AS comment_date ,
            IIF(lc.[LONG COMMENT TEXT LINE 01] IS NULL, '', lc.[LONG COMMENT TEXT LINE 01]) AS comment_line1 ,
            IIF(lc.[LONG COMMENT TEXT LINE 02] IS NULL, '', lc.[LONG COMMENT TEXT LINE 02]) AS comment_line2 ,
            IIF(lc.[LONG COMMENT TEXT LINE 03] IS NULL, '', lc.[LONG COMMENT TEXT LINE 03]) AS comment_line3 ,
            IIF(lc.[LONG COMMENT TEXT LINE 04] IS NULL, '', lc.[LONG COMMENT TEXT LINE 04]) AS comment_line4 ,
            IIF(lc.[LONG COMMENT TEXT LINE 05] IS NULL, '', lc.[LONG COMMENT TEXT LINE 05]) AS comment_line5 ,
            IIF(lc.[LONG COMMENT TEXT LINE 06] IS NULL, '', lc.[LONG COMMENT TEXT LINE 06]) AS comment_line6 ,
            IIF(lc.[LONG COMMENT TEXT LINE 07] IS NULL, '', lc.[LONG COMMENT TEXT LINE 07]) AS comment_line7 ,
            IIF(lc.[LONG COMMENT TEXT LINE 08] IS NULL, '', lc.[LONG COMMENT TEXT LINE 08]) AS comment_line8 ,
            IIF(lc.[LONG COMMENT TEXT LINE 09] IS NULL, '', lc.[LONG COMMENT TEXT LINE 09]) AS comment_line9 ,
            IIF(lc.[LONG COMMENT TEXT LINE 10] IS NULL, '', lc.[LONG COMMENT TEXT LINE 10]) AS comment_line10 ,
            GETDATE() AS created ,
            GETDATE() AS updated ,
            SID ,
            load_date ,
            IIF(lc.[LONG COMMENT TEXT LINE 01] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 01])))
            + ' '
            + -- comment_line1 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 02] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 02])))
            + ' '
            + -- comment_line2 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 03] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 03])))
            + ' '
            + -- comment_line3 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 04] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 04])))
            + ' '
            + -- comment_line4 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 05] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 05])))
            + ' '
            + -- comment_line5 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 06] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 06])))
            + ' '
            + -- comment_line6 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 07] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 07])))
            + ' '
            + -- comment_line7 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 08] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 08])))
            + ' '
            + -- comment_line8 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 09] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 09])))
            + ' '
            + -- comment_line9 - nvarchar(50)
            IIF(lc.[LONG COMMENT TEXT LINE 10] IS NULL, '', LTRIM(RTRIM(lc.[LONG COMMENT TEXT LINE 10]))) AS long_comment
    FROM    long_comment lc WHERE lc.[LOAN NUMBER]=@ln
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
    END



GO

/****** Object:  StoredProcedure [Sime].[GetLoanLossMitigation]    Script Date: 8/14/2017 11:50:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
 
CREATE PROCEDURE [Sime].[GetLoanLossMitigation] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
        
  
                SELECT  LM.[LOAN NUMBER] loan_number,
                        LM.[LOAN NUMBER] + ' ' + LM.[LOSS MIT SET UP DATE] AS id ,
                        LM.[LOSS MIT STATUS CODE] AS status_code ,
           TRY_PARSE(
                        LM.[LOSS MIT SET UP DATE] AS DATETIME ) AS setup_date ,
           TRY_PARSE(
                        LM.[LOSS MIT APPROVAL DATE] AS DATETIME ) AS approved_date ,
           TRY_PARSE(
                        LM.[LOSS MIT REMOVAL DATE] AS DATETIME ) AS removal_date ,
                        LM.[LOSS MIT TYPE CODE] AS type ,
						LM.[LOSS MIT TEMPLATE NAME] AS template_name,
						lms.[LS STEP SEQUENCE NUMBER] AS step_number,
						TRY_PARSE(lms.[LS SETUP DATE] AS DATETIME) AS step_setup_date, 
						TRY_PARSE(lms.[LS ACTUAL COMPLETION DATE] AS DATETIME) AS step_completion_date, 
						TRY_PARSE(lms.[LS SCHEDULED COMPLETION DATE] AS DATETIME) AS step_sched_compl_date,
						step_name =(SELECT [Description] FROM [Sime].[LossMitStepNames]  WHERE [Code] =  LMS.[LS STEP CODE]),
                        GETDATE() AS created ,
                        GETDATE() AS updated ,
                        LMS.SID ,
                        LMS.load_date
                FROM    loss_mitigation LM
                        INNER JOIN loss_mit_steps LMS WITH ( NOLOCK ) ON LM.[LOAN NUMBER] = LMS.[LOAN NUMBER]
                                                              AND LM.[LOSS MIT SET UP DATE] = LMS.[LS SETUP DATE]
                WHERE   LM.[LOAN NUMBER] = @ln AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
				ORDER BY lm.[LOAN NUMBER], lm.[LOSS MIT SET UP DATE], step_number
            END 
    










GO

/****** Object:  StoredProcedure [Sime].[GetLoanMixedComments]    Script Date: 8/14/2017 11:50:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





 

 
CREATE PROCEDURE [Sime].[GetLoanMixedComments] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS 
    BEGIN
        DECLARE @empty UNIQUEIDENTIFIER = (SELECT CAST(CAST(0 as BINARY) AS UNIQUEIDENTIFIER))
        IF EXISTS ( SELECT  *
                    FROM    [dbo].[ListLoansForClient](@investors) ml
                    WHERE   ml.[Loan Number] = @ln )
            BEGIN
     
                SELECT  'CC' source ,
                        @empty id ,
                        cc.[LOAN NUMBER] loan_number , TRY_PARSE(
                        cc.[COMMENT ADDED DATE] AS DATETIME ) AS comment_date ,
                        cc.[COMMENT ADDED TIME] AS comment_time ,
                        IIF(RTRIM(LTRIM(ISNULL(cc.[COMMENT CONTACT DESCRIPTION],
                                               '') + ' '
                                        + ISNULL(cc.[COMMENT RESPONSE DESCRIPTION],
                                                 '') + ' '
                                        + ISNULL(cc.[COMMENT REASON DESCRIPTION],
                                                 ''))) = '', '', '(')
                        + RTRIM(LTRIM(ISNULL(cc.[COMMENT CONTACT DESCRIPTION],
                                             '') + ' '
                                      + ISNULL(cc.[COMMENT RESPONSE DESCRIPTION],
                                               '') + ' '
                                      + ISNULL(cc.[COMMENT REASON DESCRIPTION],
                                               '')))
                        + IIF(RTRIM(LTRIM(ISNULL(cc.[COMMENT CONTACT DESCRIPTION],
                                                 '') + ' '
                                          + ISNULL(cc.[COMMENT RESPONSE DESCRIPTION],
                                                   '') + ' '
                                          + ISNULL(cc.[COMMENT REASON DESCRIPTION],
                                                   ''))) = '', '', ') ')
                        + LTRIM(RTRIM(ISNULL(cc.[COMMENT LONG DESCRIPTION LINE1],
                                             '') + ' '
                                      + ISNULL(cc.[COMMENT LONG DESCRIPTION LINE2],
                                               '') + ' '
                                      + ISNULL(cc.[COMMENT LONG DESCRIPTION LINE3],
                                               ''))) comment ,
                        IIF([SEC USER NAME] IS NULL, [COMMENT ADDED ID], [SEC USER NAME]) AS comment_user_name
                FROM    BDESIME.dbo.collection_comment cc
                        LEFT JOIN BDESIME.dbo.security_user ON [cc].[COMMENT ADDED ID] = [USER ID]
                WHERE   cc.[LOAN NUMBER] = @ln
                UNION ALL
                SELECT  'LC' source ,
                        @empty id ,
                        lc.[LOAN NUMBER] loan_number ,  TRY_PARSE(
                        lc.[LONG COMMENT DATE] AS DATETIME ) AS comment_date ,
                        lc.[LONG COMMENT TIME] AS comment_time ,
                        LTRIM(RTRIM(ISNULL([LONG COMMENT TEXT LINE 01], '')
                                    + ' ' + ISNULL([LONG COMMENT TEXT LINE 02],
                                                   '') + ' '
                                    + ISNULL([LONG COMMENT TEXT LINE 03], '')
                                    + ' ' + ISNULL([LONG COMMENT TEXT LINE 04],
                                                   '') + ' '
                                    + ISNULL([LONG COMMENT TEXT LINE 05], '')
                                    + ' ' + ISNULL([LONG COMMENT TEXT LINE 06],
                                                   '') + ' '
                                    + ISNULL([LONG COMMENT TEXT LINE 07], '')
                                    + ' ' + ISNULL([LONG COMMENT TEXT LINE 08],
                                                   '') + ' '
                                    + ISNULL([LONG COMMENT TEXT LINE 09], '')
                                    + ' ' + ISNULL([LONG COMMENT TEXT LINE 10],
                                                   '') + ' ')) AS comment ,
                        IIF([SEC USER NAME] IS NULL, [LONG COMMENT USER ID], [SEC USER NAME]) AS comment_user_name
                FROM    BDESIME.dbo.long_comment lc
                        LEFT JOIN BDESIME.dbo.security_user ON [lc].[LONG COMMENT USER ID] = [USER ID]
                WHERE   lc.[LOAN NUMBER] = @ln
                UNION ALL
                SELECT  'SIME' source ,
                        id ,
                        scc.loan_number ,
                        scc.date_added comment_date ,
                        CONVERT(VARCHAR(8), date_added, 108) comment_time ,
                        LTRIM(RTRIM(IIF(LTRIM(RTRIM(ISNULL(contact_code, '')
                                                    + ' ' + ISNULL(reason_code,
                                                              '') + ' '
                                                    + ISNULL(response_code, ''))) = '', '', '( '
                                    + ISNULL(contact_code + ' ', '')
                                    + ISNULL(reason_code + ' ', '')
                                    + +ISNULL(response_code + ' ', '') + ')')
                                    + '  ' + ISNULL(scc.comment, ''))) comment ,
                        scc.user_name comment_user_name
                FROM    BDESIME.Sime.SimeCollectionComments scc
                WHERE   scc.loan_number = @ln
                        AND ( scc.batch_id IS NULL
                              OR CAST(scc.date_added AS DATE) = CAST(GETDATE() AS DATE)
                            )
                ORDER BY comment_date DESC ,
                        comment_time DESC
            END 
    END





















GO

/****** Object:  StoredProcedure [Sime].[GetLoanOtds]    Script Date: 8/14/2017 11:50:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







 
 
CREATE PROCEDURE [Sime].[GetLoanOtds] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
  
        SELECT  otd.[LOAN NUMBER] + '-' + ISNULL(otd.[OTD DATE], '') AS otd_id ,
                otd.[LOAN NUMBER] AS loan_number ,
                otd.[OTD  BANK ACCOUNT NUMBER] BankAccountNumber ,
                otd.[OTD  BANK ACCOUNT TYPE] BankAccountType ,
				otd.[OTD  ADDITIONAL PRINCIPAL CODE] AdditionalPrincipalCode,
                otd.[OTD BANK ACCOUNT NAME] BankAccountName ,
				TRY_PARSE(otd.[OTD PMT EFFECTIVE DATE] AS DATETIME ) EffectiveDate ,
                otd.[OTD TOTAL DRAFT AMOUNT] DraftAmount ,
                otd.[OTD ADDITIONL PRINCIPAL AMOUNT] AdditionalPrincipalAmount ,
				otd.[OTD DELINQUENCY FEE AMOUNT] DelinquencyFeeAmount,
				otd.[OTD DRAFT FEE AMOUNT] DraftFeeAmount,
                otd.[OTD CURRENT PAYMENT AMOUNT] CurrentPaymentAmount ,
                otd.[OTD ADDITIONAL ESCROW AMOUNT] AdditionalEscrowAmount ,
                otd.[OTD NUMBER OF PAYMENTS] NumberOfPayments ,
                otd.[OTD OTHER FEE AMOUNT] OtherFeeAmount ,				
			TRY_PARSE(otd.[OTD DATE] AS DATETIME ) AS OtdDate ,
                otd.load_date ,
                otd.SID
        FROM    dbo.one_time_draft otd
        WHERE   otd.[LOAN NUMBER] = @ln AND TRY_PARSE(otd.[OTD DATE] AS DATETIME) > DATEADD(d,-1 ,GETDATE()) AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
		ORDER BY
        TRY_PARSE(
                otd.[OTD PMT EFFECTIVE DATE] AS DATETIME ) DESC
    END 
     










GO

/****** Object:  StoredProcedure [Sime].[GetLoanPayments]    Script Date: 8/14/2017 11:50:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





 
 
CREATE PROCEDURE [Sime].[GetLoanPayments] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
    
                SELECT  pmt.[LOAN NUMBER] loan_number,
                        pmt.[LOAN NUMBER] + '-'
                        + LTRIM(RTRIM(ISNULL(CAST(pmt.[PMT TRANSACTION DATE] AS NVARCHAR),
                                             ''))) + '-'
                        + IIF(pmt.[PMT SEQUENCE NUMBER] IS NULL, '', CAST(pmt.[PMT SEQUENCE NUMBER] AS NVARCHAR))
                        + ISNULL(pmt.[PMT TRANSACTION CODE], '') AS id ,
                        pmt.[PMT TRANSACTION DATE] AS trans_date ,
                        pmt.[PMT ESCROW AMOUNT] AS escrow_amount ,
                        pmt.[PMT INTEREST AMOUNT] AS interest_amount ,
                        pmt.[PMT PRINCIPAL AMOUNT] AS principal_amount ,
                        pmt.[PMT TOTAL AMOUNT] AS payment_amount ,
                        pmt.[PMT TRANSACTION CODE] AS trans_code ,
				 TRY_PARSE(
                        pmt.[PMT DUE DATE] AS DATETIME ) AS due_date ,
                        pmt.[PMT TRANSACTION DATE] AS transaction_date ,
				TRY_PARSE(
                        pmt.[PMT EFFECTIVE DATE] AS DATETIME ) AS effective_date ,
                        pmt.[PMT SEQUENCE NUMBER] AS sequence_number ,
                        descr.trans_description AS trans_code_description ,
                        descr.trans_type AS trans_code_type ,
                        GETDATE() AS created ,
                        GETDATE() AS updated
                FROM    payment_tran pmt
                        INNER JOIN dbo.user_defined ud ON pmt.[LOAN NUMBER] = ud.[LOAN NUMBER]
                        LEFT JOIN Sime.PaymentDescriptions descr ON descr.company_code = ud.[USER 06 POSITION FIELD 1]
                                                              AND RTRIM(LTRIM(descr.pmt_trans_cd)) = RTRIM(LTRIM(pmt.[PMT TRANSACTION CODE]))
                WHERE   pmt.[LOAN NUMBER] = @ln 
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
    




GO

/****** Object:  StoredProcedure [Sime].[GetLoanPromisePaymentPlan]    Script Date: 8/14/2017 11:50:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







 

 
CREATE PROCEDURE [Sime].[GetLoanPromisePaymentPlan] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
  
  
        SELECT  ptp.[LOAN NUMBER] + ' ' + ptp.[PROMISE CREATION DATE] AS id ,
                ptp.[LOAN NUMBER] loan_number , -- loan_id - uniqueidentifier
          TRY_PARSE(
                ptp.[PROMISE CREATION DATE] AS DATETIME ) AS creation_date ,
          TRY_PARSE(
                ptp.[PROMISE AGREEMENT DATE] AS DATETIME ) AS agree_date ,
                ptp.[PROMISE ORIG DUE AMOUNT] AS orig_due_amount ,
				ptp.[PROMISE DUE AMOUNT] AS due_amount,
				ptp.[PROMISE PAID AMOUNT] AS pay_amount,
				ptp.[PROMISE PAID DATE] AS promise_pay_date,
				ptp.[PROMISE AMOUNT DUE DATE] due_date,
                GETDATE() AS created ,
                GETDATE() AS updated ,
                SID ,
                load_date
        FROM    BDESIME.dbo.promise_to_pay2 ptp
        WHERE   ptp.[LOAN NUMBER] = @ln AND TRY_PARSE(ptp.[PROMISE CREATION DATE] AS DATETIME) >= DATEADD(d,-1,GETDATE()) AND ptp.[PROMISE STATUS CODE] IS NULL
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
    END 
    
	 





GO

/****** Object:  StoredProcedure [Sime].[GetLoanPromiseToPay]    Script Date: 8/14/2017 11:50:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






  
 
CREATE PROCEDURE [Sime].[GetLoanPromiseToPay] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN 
  
        DECLARE @empty UNIQUEIDENTIFIER = ( SELECT  CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)
                                          )
        SELECT  'PTP' source ,
                @empty id ,
                ptp.[LOAN NUMBER] loan_number , -- loan_id - uniqueidentifier
          TRY_PARSE(
                ptp.[PROMISE TO PAY AGREEMENT DATE] AS DATETIME ) AS agree_date ,
          TRY_PARSE(
                ptp.[PROMISE TO PAY PROMISE BY DATE] AS DATETIME ) AS promise_by_date ,
                ptp.[PROMISE TO PAY AMOUNT] AS amount ,
                GETDATE() AS created
        FROM    BDESIME.dbo.promise_to_pay ptp
                INNER JOIN BDESIME.Sime.LoanAdditionalInfo lai ON ptp.[LOAN NUMBER] = lai.loan_number
        WHERE   ptp.[LOAN NUMBER] = @ln
                AND [PROMISE KEPT OR BROKEN FLAG] IS NULL
                AND TRY_PARSE(ptp.[PROMISE TO PAY PROMISE BY DATE] AS DATETIME) >= DATEADD(d,
                                                              -1, GETDATE())
                AND lai.investor_code IN (
                SELECT  *
                FROM    fnMultiValueSplit(@investors, ',') )
        UNION
        SELECT  'CC' source ,
                @empty id ,
                cc.[LOAN NUMBER] loan_number ,
                TRY_PARSE(
                cc.[COMMENT ADDED DATE] AS DATETIME ) agree_date ,
                 TRY_PARSE(
                cc.[COMMENT REMINDER DATE] AS DATETIME ) promise_by_date ,
                cc.[COMMENT FORBEARANCE AMOUNT] AS amount ,
                  TRY_PARSE(
                cc.[COMMENT ADDED DATE] AS DATETIME ) date_added
        FROM    BDESIME.dbo.collection_comment cc
                INNER JOIN BDESIME.Sime.LoanAdditionalInfo lai ON cc.[LOAN NUMBER] = lai.loan_number
        WHERE   ( cc.[LOAN NUMBER] = @ln
                  AND ( cc.[COMMENT FORBEARANCE AMOUNT] IS NOT NULL
                        AND cc.[COMMENT REMINDER DATE] IS NOT  NULL
                        AND cc.[COMMENT FORBEARANCE AMOUNT] > 0
                        AND TRY_PARSE(cc.[COMMENT REMINDER DATE] AS DATETIME) > GETDATE()
                      )
                  AND lai.investor_code IN (
                  SELECT    *
                  FROM      fnMultiValueSplit(@investors, ',') )
                )
        UNION
        SELECT  'SIME' source ,
                 id ,
                scc.loan_number loan_number ,
                scc.date_added agree_date ,
                scc.date promise_by_date ,
                scc.amount AS amount ,
                scc.date_added
        FROM    BDESIME.Sime.SimeCollectionComments scc
                INNER JOIN BDESIME.Sime.LoanAdditionalInfo lai ON scc.loan_number = lai.loan_number
        WHERE   ( scc.loan_number = @ln
                  AND scc.date IS NOT NULL
                  AND scc.amount IS NOT NULL
                  AND lai.investor_code IN (
                  SELECT    *
                  FROM      fnMultiValueSplit(@investors, ',') )
                )
                AND ( scc.batch_id IS NULL
                      OR CAST(scc.date_added AS DATE) = CAST(GETDATE() AS DATE)
                    )  
    END 
    









GO

/****** Object:  StoredProcedure [Sime].[GetLoanRecurringPayments]    Script Date: 8/14/2017 11:50:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





 
 
CREATE PROCEDURE [Sime].[GetLoanRecurringPayments] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
      
  
        SELECT  df.[LOAN NUMBER] AS recurring_id ,
                df.[LOAN NUMBER] AS loan_number ,
				TRY_PARSE(
                df.[DRAFT EFFECTIVE DATE] AS DATETIME ) EffectiveDate,
				TRY_PARSE(df.[DRAFT PENDING EFFECTIVE DATE] AS DATETIME) AS PendingEffectiveDate ,
                df.[DRAFT ROUTING TRANSIT NUMBER] RoutingNumber,
				df.[DRAFT ACCOUNT NUMBER] BankAccountNumber,
				df.[DRAFT DELAY DAYS QUANTITY] DelayDays,
				df.[DRAFT TYPE] DraftType,
				TRY_PARSE(df.[DRAFT LAST SCHEDULED DATE] AS DATETIME) LastScheduledDate,
				df.[DRAFT ADDITIONAL PRIN AMOUNT] AdditionalPrincipalAmount,
				df.[DRAFT ACCOUNT NAME] BankAccountName,
				df.[DRAFT LAST AMOUNT] LastAmount,
				df.[LAST TOTAL DRAFT AMOUNT] LastTotalDraftAmount ,
                df.load_date ,
                df.SID
        FROM    dbo.drafting df
        WHERE   df.[LOAN NUMBER] = @ln AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
		ORDER BY
        TRY_PARSE(
                df.[DRAFT EFFECTIVE DATE] AS DATETIME ) DESC
    END 
     








GO

/****** Object:  StoredProcedure [Sime].[GetLoanReo]    Script Date: 8/14/2017 11:50:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






 
 
CREATE PROCEDURE [Sime].[GetLoanReo] 
	-- Add the parameters for the stored procedure here
    @ln NVARCHAR(10) ,
    @investors VARCHAR(255)
AS
    BEGIN
 
         
  
                SELECT  reo.[LOAN NUMBER] loan_number,  
TRY_PARSE(
                        [REO SETUP DATE] AS DATETIME ) AS reo_setup_date ,
                        [REO STATUS CODE] AS reo_status_code ,
                        [REO FORECLOSURE SALE DATE] sale_date ,
                        [REO SALE TYPE] sale_type ,
                        [REO ACQUISITION DATE] acq_date ,
                        [REO AVAILABLE FOR SALE DATE] available_sale_date ,
                        GETDATE() AS created ,
                        GETDATE() AS updated ,
                        SID ,
                        reo.load_date
                FROM    reo reo
                WHERE   reo.[LOAN NUMBER] = @ln
              AND EXISTS ( SELECT u.[LOAN NUMBER]
                             FROM   BDESIME.dbo.user_defined u
                             WHERE  u.[LOAN NUMBER] = @ln
                                    AND [USER 06 POSITION FIELD 1] IN (
                                    SELECT  *
                                    FROM    fnMultiValueSplit(@investors, ',') ) )
            END 
   




GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForAssumption]    Script Date: 8/14/2017 11:50:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansForAssumption]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME
AS
    BEGIN
       	         
		SELECT  ln.ln_no loan_number,        
				[usr_6_pos1_xx] investor_code
		FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ln.ln_no = ud.ln_no                
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]                        
		WHERE   ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
				AND ( @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date )                        				
				AND CAST(ln.asm_dt AS DATE) = @atDate
    END 
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForDeedInLieuForeclosure]    Script Date: 8/14/2017 11:50:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 
CREATE PROCEDURE [BILLING].[GetLoansForDeedInLieuForeclosure]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512),
	@statusCodes NVARCHAR(512)
AS
    BEGIN 

        -- 25. and 67.

		SELECT ln.ln_no AS LOAN_NUMBER, 
		   ln.load_date, 
		   [usr_6_pos1_xx] investor_code ,		   
		   lm.lm_set_up_dt loss_mit_setup_date		   
		FROM
		(
			SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
			FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd
			WHERE  1=1
			AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate						
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt			
				AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date					
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date	
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHADIL,FHLMCDL,PRIVDIL,VADIL,FNMADIL' as parameter
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE 1=1		  
			  AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate			  			  
			  AND lm.lm_status_cd = @statusCodes

    END    

GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForFormalRepaymentPlans]    Script Date: 8/14/2017 11:50:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 
CREATE PROCEDURE [BILLING].[GetLoansForFormalRepaymentPlans]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,	
	@templateCodes NVARCHAR(512),
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)	
AS
    BEGIN 
		
		-- Events 31. Formal Repayment Plan:			 Status codes = ‘A’ or ‘C’. Step codes = ‘329, 990’. Actual completed date in Billing month. Template = ‘Repay’
		-- Events 65. Formal Repayment Plan Second Part: Status codes = ‘C’. Step codes = ‘329, 990’. Actual completed date in Billing month. Template = ‘Repay’

		--SELECT 			
		--	ln.ln_no loan_number,
		--	ln.load_date ,
		--	ud.usr_6_pos1_xx investor_code,
		--	lm.lm_set_up_dt loss_mit_setup_date
		--FROM
		--(
		--		SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
		--		FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 329,990 as parameter 
		--		WHERE  1=1
		--		AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate                        								
		--) lms
		--INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
		--				AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date				
		--INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
		--			AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		--INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
		--			AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		--INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		--INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes,',') sc ON sc.Item = lm.lm_status_cd
		--WHERE 1=1				
		--		AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate				
		--		AND lm.lm_template_nm = @templateCodes		
				
		
		SELECT
			lms.lm_status_cd,
			lms.lm_template_nm,
			ln.ln_no AS loan_number,
			ln.load_date,
			ud.usr_6_pos1_xx AS investor_code,
			lms.lm_set_up_dt AS loss_mit_setup_date,
			CAST(lms.ls_actual_compl_dt AS DATE) AS ls_actual_compl_dt
		FROM
		(		
				SELECT lms.ln_no, MAX(ls_setup_dt) AS ls_setup_dt, MAX(ls_actual_compl_dt) AS ls_actual_compl_dt, MAX(lm.lm_status_cd) AS lm_status_cd, 
				MAX(lm.lm_template_nm) AS lm_template_nm, MAX(lm.lm_set_up_dt) AS lm_set_up_dt
				FROM	   BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
						   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date				
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 329,990 as parameter 
				WHERE  lm.lm_template_nm = @templateCodes
				GROUP BY lms.ln_no
				HAVING COUNT(*) >= 2 AND MAX(CAST(lms.ls_actual_compl_dt AS DATE)) = @atDate
		) lms

		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes,',') sc ON sc.Item = lms.lm_status_cd
		WHERE 1=1						
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate
		    				
    END    




GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForHAMPFHAVACompletion]    Script Date: 8/14/2017 11:50:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [BILLING].[GetLoansForHAMPFHAVACompletion]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),	
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN 
        		
		SELECT 			
			ln.ln_no AS loan_number, 
			ln.load_date, 
			[usr_6_pos1_xx] investor_code ,			
			lm.lm_set_up_dt loss_mit_setup_date      
		FROM
		(
				SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
				FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- M17,746 as parameter 
				WHERE  1=1
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate                        								
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
						AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date				
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHAHAMP' as parameter		                                        
		WHERE 1=1		
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate								
				AND lm.lm_status_cd = @statusCodes -- 'C' as parameter 
	
    END    



GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForHAMPFHAVASetup]    Script Date: 8/14/2017 11:50:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [BILLING].[GetLoansForHAMPFHAVASetup]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),	
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN        		

		SELECT 			
			ln.ln_no AS LOAN_NUMBER, 
			ln.load_date, 
			[usr_6_pos1_xx] investor_code ,			
			lm.lm_set_up_dt loss_mit_setup_date      
		FROM
		(
				SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
				FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- H24 as parameter 
				WHERE  1=1
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate                        								
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
						AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date				
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHAHAMP' as parameter		                                        
		WHERE 1=1		
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate								
				AND lm.lm_status_cd = @statusCodes -- 'A' as parameter 

    END    



GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForHAMPModification]    Script Date: 8/14/2017 11:50:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
CREATE PROCEDURE [BILLING].[GetLoansForHAMPModification]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512),
	@statusCodes NVARCHAR(512)
AS
    BEGIN 
        		
		SELECT ln.ln_no AS LOAN_NUMBER, 
			ln.load_date, 
			[usr_6_pos1_xx] investor_code ,			
			lm.lm_set_up_dt loss_mit_setup_date                   
		FROM
		(
				SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
				FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- M17 as parameter 
				WHERE  1=1
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate                        				
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
						AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date                                        
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHAHAMP,FNMAHMP,FHAHMP2,FHAMOD,FHLMCMD,FHLMCST,FHLMHMP,FNMAMD2,FNMASTM,PRIVMD,USDAMOD,VAMOD' as parameter
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE 1=1                  
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate				
				AND lm.lm_status_cd = @statusCodes -- 'A' as parameter 

    END    


GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForNonHAMPModification]    Script Date: 8/14/2017 11:50:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansForNonHAMPModification]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),	
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN         		

		SELECT 			
			ln.ln_no AS LOAN_NUMBER, 
			ln.load_date, 
			[usr_6_pos1_xx] investor_code ,			
			lm.lm_set_up_dt loss_mit_setup_date      
		FROM
		(
				SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
				FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd
				WHERE  1=1
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date
					AND lm.lm_template_id NOT IN (SELECT Item FROM BDESime.dbo.fnMultiValueSplit(@templateCodes,',')) -- 'FHAHAMP,FHAHMP2,FHAPC,HNMAHMP,HAMP,VAHAMP,HAHAMP' as parameter		                                        
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE 1=1		
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate								
				AND lm.lm_status_cd = @statusCodes -- 'A' as parameter 

    END    



GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForNSFOrReturnedCheck]    Script Date: 8/14/2017 11:50:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansForNSFOrReturnedCheck]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME,
	@transactionCode NVARCHAR(512)
AS
    BEGIN
       	         
		SELECT  fee.[LOAN NUMBER] AS loan_number,
				MAX(fee.load_date) AS load_date,
				SUM(fee.[FEE TRANSACTION AMOUNT]) AS fee_amount,
				MAX([usr_6_pos1_xx]) AS investor_code
		FROM    BDESime.dbo.fee AS fee WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON fee.[LOAN NUMBER] = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE        			
				[FEE TRANSACTION] = @transactionCode -- 152 as parameter
				AND CAST(fee.[FEE TRANSACTION DATE] AS DATE) BETWEEN @atDate AND @atDateTo
				AND CAST(fee.[FEE TRANSACTION DATE] AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date
		GROUP BY fee.[LOAN NUMBER]		

    END 



GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForShortSaleCompleted]    Script Date: 8/14/2017 11:50:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansForShortSaleCompleted]
	@investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512),
	@statusCodes NVARCHAR(512)
AS
    BEGIN
        
		SELECT ln.ln_no AS LOAN_NUMBER, 
		   ln.load_date, 
		   [usr_6_pos1_xx] investor_code ,		   
		   lm.lm_set_up_dt loss_mit_setup_date		   
		FROM
		(
			SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
			FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 973 as parameter 
			WHERE  1=1
			AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate			
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt			
				AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date					
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date	
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHLMCSS,FNMASS,PRIVSS,VASS,FHASS,USDASS' as parameter
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes,',') sc ON sc.Item = lm.lm_status_cd -- 'A,C' as parameter 		  
		WHERE 1=1		  
			  AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate			  
			  AND lm.lm_status_cd = @statusCodes -- 'C' as parameter 		  
		
    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansForShortSaleSetup]    Script Date: 8/14/2017 11:50:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansForShortSaleSetup]
	@investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512),
	@statusCodes NVARCHAR(512)
AS
    BEGIN        						

		SELECT ln.ln_no AS LOAN_NUMBER, 
			   ln.load_date, 
			   [usr_6_pos1_xx] investor_code ,			   
			   lm.lm_set_up_dt loss_mit_setup_date			   
		FROM
		(
			SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
			FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 210 as parameter
			WHERE  1=1
			AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate			
		) lms
		INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt			
				AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date					
		INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
			   AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date	
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHLMCSS,FNMASS,PRIVSS,VASS,FHASS,USDASS' as parameter
		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE 1=1		  
			  AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate			  
			  AND lm.lm_status_cd = @statusCodes -- 'A'  as parameter		  

    END

GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInAppraisalFee]    Script Date: 8/14/2017 11:50:12 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansInAppraisalFee]
    @investors NVARCHAR(MAX),    
	@atDate DATETIME,
	@atDateTo DATETIME,
    @payeeCodes NVARCHAR(512)
AS
    BEGIN
        
		--SELECT 
		--		CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
		--		c.ln_no as loan_number,
		--		'Appraisal Fee' as Payee_Description,
		--		ud.usr_6_pos1_xx investor_code
		--FROM	BDESime.dbo.dim_corporate_adv_tran c WITH (NOLOCK) 
		--		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON c.ln_no = ud.ln_no
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = c.adv_corp_payee_id --'78N78,78T78' as parameter
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@reasonCodes,',') rc ON rc.Item = c.adv_reason_cd -- 'APPR' as parameter
		--WHERE 
		--		 CAST(c.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
		--		 AND c.adv_am > 0
		--		 AND ( @atDateTo BETWEEN c.valid_from_date AND c.valid_through_date)
  --               AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		--GROUP BY ud.usr_6_pos1_xx, c.ln_no, 
		--		 CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR)


		
		SELECT	
				CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
				t.ln_no as loan_number,
				'Appraisal Fee' as Payee_Description,
				ud.usr_6_pos1_xx investor_code
		FROM	BDESime.dbo.dim_corporate_adv_tran t WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON t.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = t.adv_corp_payee_id --'78N78,78T78' as parameter
		WHERE 1=1
				AND adv_am > 0
				
				AND (adv_trans_cd = '633')		

				AND CAST(t.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
				AND ( @atDateTo BETWEEN t.valid_from_date AND t.valid_through_date)
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		GROUP BY ud.usr_6_pos1_xx, t.ln_no, 
				 CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR)				

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInBankruptcy]    Script Date: 8/14/2017 11:50:12 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 

CREATE PROCEDURE [BILLING].[GetLoansInBankruptcy]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@atDateTo DATETIME,
	@statusCodes NVARCHAR(512)
AS
    BEGIN
         
		 SELECT  *
		 FROM    ( SELECT   ln.ln_no loan_number ,
							ud.[usr_6_pos1_xx] investor_code ,
							ROW_NUMBER() OVER ( PARTITION BY bk.ln_no ORDER BY bk.bkr_setup_dt DESC ) AS rn
					FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
							INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ln.ln_no = ud.ln_no
							INNER JOIN BDESime.dbo.dim_bankruptcy bk  WITH (NOLOCK) ON ln.ln_no = bk.ln_no
							INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
					WHERE   bk.bkr_status_cd = @statusCodes -- 'A' as parameter
							AND ( @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date )
							AND ( @atDateTo BETWEEN bk.valid_from_date AND bk.valid_through_date )
							AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
				) AS res
		 WHERE   res.rn = 1

    END
	 


GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFHACWCOT]    Script Date: 8/14/2017 11:50:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInFHACWCOT]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME,
	@templateCodes NVARCHAR(512),    
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)

AS
    BEGIN
        
		--SELECT ln.ln_no AS LOAN_NUMBER, [usr_6_pos1_xx] investor_code ,
  --         lm.lm_set_up_dt loss_mit_setup_date,
  --         CAST(lms.ls_actual_compl_dt AS DATE) AS ls_actual_compl_dt,
  --         lm.lm_template_id
  --      FROM
  --      (
  --          SELECT ln_no, ls_setup_dt, ls_actual_compl_dt
  --          FROM BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)
  --          INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 248,722 as parameter
  --          WHERE  1=1                
  --          AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
  --      ) lms
  --      INNER JOIN BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt                        
  --                      AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date                                        
  --      INNER JOIN BDESime.dbo.dim_loan ln  WITH (NOLOCK) ON ln.ln_no = lm.ln_no
  --                 AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date
  --      INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ud.ln_no = lms.ln_no
  --                 AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date        
  --      INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'TBD' as parameter
  --      INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
  --      WHERE 1=1                                    
		--		AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
  --              AND lm.lm_status_cd = @statusCodes -- 'A'  as parameter

		--UNION
		        
		SELECT rs.ln_no AS LOAN_NUMBER, MAX([usr_6_pos1_xx]) AS investor_code, '' AS loss_mit_setup_date,
			   MAX(CAST(rs.rs_actual_compl_dt AS DATE)) AS ls_actual_compl_dt, MAX(re.reo_template_id) AS lm_template_id
		FROM    BDESime.dbo.dim_reo re  WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt					
				INNER JOIN BDESime.dbo.dim_loan ln WITH (NOLOCK) ON re.ln_no = ln.ln_no					
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no					
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') s ON s.Item = rs.rs_step_cd -- '811,R04' as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = re.reo_template_id -- '3PSALE' as parameter
		WHERE   ln.ln_reo_status_cd = @statusCodes -- 'A' as parameter			
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date  AND re.valid_through_date )	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date  AND ln.valid_through_date )
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date  AND rs.valid_through_date OR CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
				)	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date  AND ud.valid_through_date )	
							
			GROUP BY rs.ln_no
			HAVING COUNT(*) >= 2 AND MAX(CAST(rs.rs_actual_compl_dt AS DATE)) BETWEEN @atDate AND @atDateTo


    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFHACWCOTSecondChance]    Script Date: 8/14/2017 11:50:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInFHACWCOTSecondChance]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME,
	@templateCodes NVARCHAR(512),    
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)

AS
    BEGIN       		
		        
		SELECT ls.ln_no AS LOAN_NUMBER, MAX([usr_6_pos1_xx]) AS investor_code, '' AS loss_mit_setup_date,
			   MAX(CAST(ls.ls_actual_compl_dt AS DATE)) AS ls_actual_compl_dt, MAX(lm.lm_template_id) AS lm_template_id
		FROM    BDESime.dbo.dim_loss_mitigation lm  WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_lossmitigation_step ls WITH (NOLOCK) ON lm.ln_no = ls.ln_no AND ls.ls_setup_dt = lm.lm_set_up_dt					
				INNER JOIN BDESime.dbo.dim_loan ln WITH (NOLOCK) ON lm.ln_no = ln.ln_no					
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON lm.ln_no = ud.ln_no					
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') s ON s.Item = ls.ls_step_cd -- '248, 722' as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = lm.lm_template_id -- 'FHASS' as parameter
		WHERE   ln.ln_lm_status_cd = @statusCodes -- 'A' as parameter			
				AND ( CAST(ls.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date  AND lm.valid_through_date )	
				AND ( CAST(ls.ls_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date  AND ln.valid_through_date )
				AND ( CAST(ls.ls_actual_compl_dt AS DATE) BETWEEN ls.valid_from_date  AND ls.valid_through_date OR CAST(ls.ls_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
				)	
				AND ( CAST(ls.ls_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date  AND ud.valid_through_date )	
							
		GROUP BY ls.ln_no
		HAVING COUNT(*) >= 2 AND MAX(CAST(ls.ls_actual_compl_dt AS DATE)) BETWEEN @atDate AND @atDateTo


    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFHAPartA]    Script Date: 8/14/2017 11:50:14 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansInFHAPartA]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateIds nvarchar(512),
	@statusCodes nvarchar(512),
	@stepCodes1 nvarchar(512),
	@stepCodes2 nvarchar(512),
	@types nvarchar(512)
AS
    BEGIN
         
		

		SELECT A.loan_number, A.investor_code, ISNULL(A.rs_setup_dt, B.rs_setup_dt) AS rs_setup_dt, A.rs_no, 
			   ISNULL(A.rs_actual_compl_dt, B.rs_actual_compl_dt) AS rs_actual_compl_dt 
		FROM (
			SELECT 
				ln.ln_no AS loan_number ,
				rs.rs_step_cd AS rs_step_cd,
				MAX(ud.[usr_6_pos1_xx]) AS investor_code , 
				MAX(rs.rs_setup_dt) AS rs_setup_dt,
				MAX(rs.rs_no) AS rs_no,
				MAX(rs.rs_actual_compl_dt) AS rs_actual_compl_dt
			FROM   
				BDESime.dbo.dim_loan ln WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_reo re WITH (NOLOCK) ON ln.ln_no = re.ln_no
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON rs.ln_no = re.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes1, ',') s ON s.Item = rs.rs_step_cd
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds, ',') t ON t.Item = re.reo_template_id
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes, ',') c ON c.Item = re.reo_status_cd
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@types,',') ty ON ty.Item = ln.ln_lo_ty -- '1,5' as parameter
			WHERE   1=1
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date AND rs.valid_through_date OR CAST(rs.rs_actual_compl_dt AS DATE) = @atDate)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date)
					AND rs.rs_actual_compl_dt IS NOT NULL
			GROUP BY ln.ln_no, rs.rs_step_cd
		) A

		INNER JOIN (
			SELECT 
				ln.ln_no AS loan_number ,
				rs.rs_step_cd AS rs_step_cd,	
				MAX(ud.[usr_6_pos1_xx]) AS investor_code , 
				MAX(rs.rs_setup_dt) AS rs_setup_dt,
				MAX(rs.rs_no) AS rs_no,
				MAX(rs.rs_actual_compl_dt) AS rs_actual_compl_dt		
			FROM   
				BDESime.dbo.dim_loan ln WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_reo re WITH (NOLOCK) ON ln.ln_no = re.ln_no
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON rs.ln_no = re.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes2, ',') s ON s.Item = rs.rs_step_cd
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds, ',') t ON t.Item = re.reo_template_id
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes, ',') c ON c.Item = re.reo_status_cd
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@types,',') ty ON ty.Item = ln.ln_lo_ty -- '1,5' as parameter
			WHERE 1=1
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date AND rs.valid_through_date OR CAST(rs.rs_actual_compl_dt AS DATE) = @atDate)
					AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date)
					AND rs.rs_actual_compl_dt IS NOT NULL		  
			GROUP BY ln.ln_no, rs.rs_step_cd
		) B 
		ON A.loan_number = B.loan_number
		WHERE (
				CAST(A.rs_actual_compl_dt AS DATE) = @atDate		
				OR		
				CAST(B.rs_actual_compl_dt AS DATE) = @atDate		
		)
		ORDER BY A.loan_number, A.rs_step_cd

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFHAPartB]    Script Date: 8/14/2017 11:50:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInFHAPartB]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@templateIds nvarchar(512),
	@statusCodes nvarchar(512),
	@stepCodes nvarchar(512),
	@types nvarchar(512)
AS
    BEGIN
         
		 SELECT 
			re.ln_no loan_number ,
			ud.[usr_6_pos1_xx] investor_code , 
			rs.rs_setup_dt ,
			rs.rs_no
		FROM   
			BDESime.dbo.dim_loan ln WITH (NOLOCK) 
			INNER JOIN BDESime.dbo.dim_reo re WITH (NOLOCK) ON ln.ln_no = re.ln_no
			INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON rs.ln_no = re.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
			INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes, ',') s ON s.Item = rs.rs_step_cd
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds, ',') t ON t.Item = re.reo_template_id
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes, ',') c ON c.Item = re.reo_status_cd	
			INNER JOIN BDESime.dbo.fnMultiValueSplit(@types,',') ty ON ty.Item = ln.ln_lo_ty -- '1,5' as parameter
		WHERE   1=1								
				AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date)
				AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date)
				AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date AND rs.valid_through_date OR CAST(rs.rs_actual_compl_dt AS DATE) = @atDate)
				AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date)		 

    END
	 
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFNMAFHLMCFinalDispositionClaim]    Script Date: 8/14/2017 11:50:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInFNMAFHLMCFinalDispositionClaim]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME,
	@templateCodes NVARCHAR(512),    
	@statusCodes NVARCHAR(512),
	@rsStepCodes NVARCHAR(512)
AS
    BEGIN
        				
		SELECT rs.ln_no AS loan_number, MAX([usr_6_pos1_xx]) AS investor_code, MAX(rs_step_cd) AS rs_step_cd
		FROM    BDESime.dbo.dim_reo re  WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date
				INNER JOIN BDESime.dbo.dim_loan ln WITH (NOLOCK) ON re.ln_no = ln.ln_no
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date				
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@rsStepCodes,',') s ON s.Item = rs.rs_step_cd -- 'R24,250' as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = re.reo_template_id -- 'FNMAPST,FHMPOST' as parameter
		WHERE   ln.ln_reo_status_cd = @statusCodes -- 'A' as parameter
				AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo				
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date  AND re.valid_through_date )	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date  AND ln.valid_through_date )
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date  AND rs.valid_through_date )	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date  AND ud.valid_through_date )	
							
		GROUP BY rs.ln_no
		HAVING COUNT(*) >= 2 AND MAX(CAST(rs.rs_actual_compl_dt AS DATE)) BETWEEN @atDate AND @atDateTo

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInFNMAFHLMCInterimSupplementalClaim]    Script Date: 8/14/2017 11:50:16 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInFNMAFHLMCInterimSupplementalClaim]
    @investors NVARCHAR(MAX),    
    @atDate DATETIME,
	@atDateTo DATETIME,
	@templateCodes NVARCHAR(512),    
	@statusCodes NVARCHAR(512),
	@rsStepCodes NVARCHAR(512)
AS
    BEGIN
        
		SELECT rs.ln_no AS loan_number, MAX([usr_6_pos1_xx]) AS investor_code, MAX(rs_step_cd) AS rs_step_cd
		FROM    BDESime.dbo.dim_reo re  WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date
				INNER JOIN BDESime.dbo.dim_loan ln WITH (NOLOCK) ON re.ln_no = ln.ln_no
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date AND ln.valid_through_date				
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
						AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@rsStepCodes,',') s ON s.Item = rs.rs_step_cd -- '443,250' as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateCodes,',') t ON t.Item = re.reo_template_id -- '3PSALE' as parameter
		WHERE   ln.ln_reo_status_cd = @statusCodes -- 'A' as parameter
				AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo				
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date  AND re.valid_through_date )	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ln.valid_from_date  AND ln.valid_through_date )
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date  AND rs.valid_through_date )	
				AND ( CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date  AND ud.valid_through_date )	
							
		GROUP BY rs.ln_no
		HAVING COUNT(*) >= 2 AND MAX(CAST(rs.rs_actual_compl_dt AS DATE)) BETWEEN @atDate AND @atDateTo


    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInForeclosure]    Script Date: 8/14/2017 11:50:16 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInForeclosure]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@atDateTo DATETIME,
	@statusCodes NVARCHAR(512)
AS
    BEGIN

        SELECT  *
		FROM    ( 
					SELECT    ln.ln_no loan_number ,
							ud.[usr_6_pos1_xx] investor_code
							, ROW_NUMBER() OVER ( PARTITION BY fc.ln_no ORDER BY CAST(fc.fc_setup_dt AS DATE) DESC ) AS rn
					FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
							INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ln.ln_no = ud.ln_no
							INNER JOIN BDESime.dbo.dim_foreclosure fc  WITH (NOLOCK) ON ln.ln_no = fc.ln_no
							INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
					WHERE   fc.fc_status_cd = @statusCodes -- 'A' as parameter
					
							AND ( @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date )
							AND ( @atDateTo BETWEEN fc.valid_from_date AND fc.valid_through_date )
							AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
				) AS res
		WHERE   res.rn = 1
 
    END









GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInPoolInsuranceClaim]    Script Date: 8/14/2017 11:50:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInPoolInsuranceClaim]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@stepCode1 NVARCHAR(512), -- 929
	@stepCode2 NVARCHAR(512), -- R38
	@templateCode1 NVARCHAR(512), -- FHAPOST
	@templateCode2 NVARCHAR(512) -- VAPOST
AS
    BEGIN        					 
		Declare @FinalTable TABLE  
		(
		ln_no NVARCHAR(13),
		reo_template_id NVARCHAR(7),
		investor_code NVARCHAR(6),
		s929 DATE,
		sR38 DATE
		)

		-- Dropping Temporary Tables if exist
         IF OBJECT_ID('tempdb..#max_reo') IS NOT NULL 
			DROP TABLE #max_reo
 
         IF OBJECT_ID('tempdb..#RSC') IS NOT NULL 
            DROP TABLE #RSC 		

		 IF OBJECT_ID('tempdb..#FinalTable') IS NOT NULL 
            DROP TABLE #FinalTable

         SELECT [LOAN NUMBER] ln_no,MAX([REO SETUP DATE]) as rs_setup_dt, [REO TEMPLATE ID] as  reo_template_id 
         INTO #max_reo  from REO WITH (NOLOCK) 
         WHERE [REO TEMPLATE ID] IN (@templateCode1, @templateCode2)
         GROUP BY [LOAN NUMBER],[REO TEMPLATE ID]
         
        -- Building CTE Tables
		;WITH reosteps(ln_no, rs_step_cd, reo_template_id, rs_actual_compl_dt, rs_setup_dt, investor_code)
		AS (     SELECT rs.[LOAN NUMBER] AS ln_no, [RS STEP CODE] AS rs_step_cd, reo_template_id, [RS ACTUAL COMPLETION DATE] AS rs_actual_compl_dt, [RS SETUP DATE] AS rs_setup_dt,
		         [USER 06 POSITION FIELD 1] AS investor_code           
				FROM   [reo_steps] rs WITH (NOLOCK) 
						JOIN #max_reo mf  WITH (NOLOCK) on rs.[LOAN NUMBER] = mf.ln_no  and rs.[RS SETUP DATE] = mf.rs_setup_dt
						INNER JOIN BDESime.dbo.user_defined ud  WITH (NOLOCK) ON mf.ln_no = ud.[LOAN NUMBER]
						INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [USER 06 POSITION FIELD 1]
						WHERE  [RS STEP CODE] IN (@stepCode1, @stepCode2)
						--AND CAST([RS ACTUAL COMPLETION DATE] AS DATE) BETWEEN DATEADD(DAY,1,DATEADD(MONTH,-1,EOMONTH(@atDate))) AND EOMONTH(@atDate)
						AND CAST([RS ACTUAL COMPLETION DATE] AS DATE) = @atDate
				)
		SELECT DISTINCT j.ln_no, reo_template_id, j.investor_code, [929], [R38]
		INTO #FinalTable      
		FROM reosteps AS j WITH (NOLOCK) 
				FULL JOIN
						(SELECT ln_no, CAST(rs_actual_compl_dt AS date) AS '929', rs_step_cd, rs_actual_compl_dt, investor_code 
						FROM   reosteps a WITH (NOLOCK)               
						WHERE  rs_step_cd = @stepCode1) AS a on a.ln_no = j.ln_no
				FULL JOIN
						(SELECT ln_no, CAST(rs_actual_compl_dt AS date) AS 'R38', rs_step_cd, rs_actual_compl_dt, investor_code 
						FROM reosteps WITH (NOLOCK)                    
						WHERE rs_step_cd = @stepCode2) AS b on b.ln_no = j.ln_no
						AND (929 IS NOT NULL OR R38 IS NOT NULL )

		-- Final Result Select
		INSERT INTO @FinalTable SELECT ln_no, reo_template_id, investor_code, [929], [R38] FROM #FinalTable

		-- Selecting Data
		SELECT ln_no, reo_template_id, investor_code, s929, sR38 FROM @FinalTable

    END
	 



GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInPostForeclosure]    Script Date: 8/14/2017 11:50:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInPostForeclosure]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@atDateTo DATETIME,
	@templateId NVARCHAR(512),
	@rsStepCd NVARCHAR(512),
	@statusCodes NVARCHAR(512)
AS
    BEGIN
        
        SELECT rs.ln_no AS loan_number, ud.[usr_6_pos1_xx] AS investor_code 
		FROM
		(
			SELECT ln_no,rs_setup_dt,
			rs_actual_compl_dt
			FROM BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) 
			WHERE rs.rs_step_cd = @rsStepCd -- R24 as parameter                               
			AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
		) rs
		INNER JOIN BDESime.dbo.dim_reo re WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
				AND re.reo_template_id = @templateId -- FHAPOST as parameter
				AND @atDateTo BETWEEN re.valid_from_date AND re.valid_through_date			
		INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON ud.ln_no = rs.ln_no
				AND @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date
		INNER JOIN BDESime.dbo.dim_loan ln WITH (NOLOCK) ON ln.ln_no = rs.ln_no
				AND @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date
		WHERE CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
				AND re.reo_status_cd = @statusCodes --'A' as parameter
				AND ln.co_man_cd <> 'B'
				AND ln.ln_1st_prin_ba > 0
               
    END







GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInPropertyInspectionFee]    Script Date: 8/14/2017 11:50:18 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [BILLING].[GetLoansInPropertyInspectionFee]
    @investors NVARCHAR(MAX),    
	@atDate DATETIME,
	@atDateTo DATETIME,
    @payeeCodes NVARCHAR(512)
AS
    BEGIN
        
		--SELECT 
		--		CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
		--		c.ln_no as loan_number,
		--		'Property Inspection' as Payee_Description,
		--		ud.usr_6_pos1_xx investor_code
		--FROM	BDESime.dbo.dim_corporate_adv_tran c WITH (NOLOCK) 
		--		INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON c.ln_no = ud.ln_no
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = c.adv_corp_payee_id --'77R77,77N77,77T77' as parameter
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@reasonCodes,',') rc ON rc.Item = c.adv_reason_cd -- 'PROP,INSP' as parameter
		--WHERE 
		--		 CAST(c.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
		--		 AND ( @atDateTo BETWEEN c.valid_from_date AND c.valid_through_date)
  --              AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		--		 AND c.adv_am > 0
		--GROUP BY ud.usr_6_pos1_xx,
		--		 c.ln_no, 
		--		 CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR)

		
		SELECT	
				CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
				t.ln_no as loan_number,
				'Property Inspection' as Payee_Description,
				ud.usr_6_pos1_xx investor_code
		FROM	BDESime.dbo.dim_corporate_adv_tran t WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON t.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = t.adv_corp_payee_id --'77R77,77N77,77T77' as parameter
		WHERE 1=1
				AND adv_am > 0
				
				AND (adv_trans_cd = '631')		

				AND CAST(t.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
				AND ( @atDateTo BETWEEN t.valid_from_date AND t.valid_through_date)
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		GROUP BY ud.usr_6_pos1_xx,
				 t.ln_no, 
				 CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR)

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInPropertyPreservation]    Script Date: 8/14/2017 11:50:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansInPropertyPreservation]
    @investors NVARCHAR(MAX),    
	@atDate DATETIME,
	@atDateTo DATETIME,
    @payeeCodes NVARCHAR(512)
AS
    BEGIN
        
		--SELECT 
		--		CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
		--		c.ln_no as loan_number,
		--		'Property Preservation' as Payee_Description,
		--		ud.usr_6_pos1_xx investor_code
		--FROM	BDESime.dbo.dim_corporate_adv_tran c WITH (NOLOCK) 
		--		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON c.ln_no = ud.ln_no
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = c.adv_corp_payee_id --'54R54,54N54,54T54' as parameter
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@reasonCodes,',') rc ON rc.Item = c.adv_reason_cd -- 'PRES,PROP' as parameter		
		--WHERE 
		--		 CAST(c.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
		--		 AND c.adv_am > 0
		--		 AND ( @atDateTo BETWEEN c.valid_from_date AND c.valid_through_date)
		--		 AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		--GROUP BY ud.usr_6_pos1_xx,
		--		 c.ln_no, 
		--		 CAST(MONTH(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(c.adv_trans_dt AS DATE)) AS VARCHAR)				 

		
		SELECT	
				CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
				t.ln_no as loan_number,
				'Property Preservation' as Payee_Description,
				ud.usr_6_pos1_xx investor_code
		FROM	BDESime.dbo.dim_corporate_adv_tran t WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON t.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@payeeCodes,',') pid ON pid.Item = t.adv_corp_payee_id --'54R54,54N54,54T54' as parameter
		WHERE 1=1
				AND adv_am > 0
				
				AND (adv_trans_cd = '631')		

				AND CAST(t.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
				AND ( @atDateTo BETWEEN t.valid_from_date AND t.valid_through_date)
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		GROUP BY ud.usr_6_pos1_xx,
				 t.ln_no, 
				 CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR)		

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInReoCancellation]    Script Date: 8/14/2017 11:50:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInReoCancellation]
    @investors NVARCHAR(MAX), 
    @atDate DATETIME,
	@atDateTo DATETIME,
	@statusCodes NVARCHAR(512),
	@rsStepCodes NVARCHAR(512)
AS
    BEGIN
        		
		SELECT loan_number, investor_code, rs_step_cd FROM (
			SELECT  ln.ln_no loan_number ,
					ud.[usr_6_pos1_xx] investor_code,
					rs.rs_step_cd,
					ROW_NUMBER() OVER ( PARTITION BY re.ln_no ORDER BY re.reo_setup_dt DESC ) AS rn			
			FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
					INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ln.ln_no = ud.ln_no				
					INNER JOIN BDESime.dbo.dim_reo re  WITH (NOLOCK) ON ln.ln_no = re.ln_no				
					INNER JOIN BDESime.dbo.dim_reo_steps rs  WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt				
					INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
					INNER JOIN BDESime.dbo.fnMultiValueSplit(@rsStepCodes,',') s ON s.Item = rs.rs_step_cd -- '840' as parameter
			WHERE   ln.ln_reo_status_cd = @statusCodes -- 'A' as parameter
					AND rs.rs_actual_compl_dt BETWEEN @atDate AND @atDateTo					
					AND ( @atDateTo BETWEEN ln.valid_from_date  AND ln.valid_through_date ) -- Change: "rs.rs_actual_compl_dt" by "@atDateTo" to get the snapshot at the end of the month
					AND ( @atDateTo BETWEEN re.valid_from_date  AND re.valid_through_date ) -- Change: "rs.rs_actual_compl_dt" by "@atDateTo" to get the snapshot at the end of the month
					AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )  -- Change: "rs.rs_actual_compl_dt" by "@atDateTo" to get the snapshot at the end of the month
					AND ( @atDateTo BETWEEN rs.valid_from_date AND rs.valid_through_date )	-- Change: "rs.rs_actual_compl_dt" by "@atDateTo" to get the snapshot at the end of the month							
		) AS res
		WHERE res.rn = 1

    END












GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInReoNotIncludingDirectCost]    Script Date: 8/14/2017 11:50:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInReoNotIncludingDirectCost]
    @investors NVARCHAR(MAX),    
    @templateIds NVARCHAR(512),
    @atDate DATETIME,
	@atDateTo DATETIME,
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN        		

		SELECT  *
			FROM    ( SELECT    ln.ln_no loan_number ,
								ud.[usr_6_pos1_xx] investor_code ,
								re.ln_no ,
								reo_setup_dt ,
								reo_status_cd ,
								ROW_NUMBER() OVER ( PARTITION BY re.ln_no ORDER BY re.reo_setup_dt DESC ) AS rn
						FROM    BDESime.dbo.dim_loan ln
								INNER JOIN BDESime.dbo.dim_user_defined ud WITH(NOLOCK) ON ln.ln_no = ud.ln_no
								INNER JOIN BDESime.dbo.dim_reo re WITH(NOLOCK) ON ln.ln_no = re.ln_no
								INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt									
								INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
								INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds,',') t ON t.Item = re.reo_template_id -- 'USDA, MARKET, VAMRKT' as parameter
								INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes,',') sc ON sc.Item = ln.ln_reo_status_cd -- 'A,C' as parameter
						WHERE   1=1
								AND (ISNULL(re.reo_sale_price_am, 0) = 0) -- Do we need this in current logic ???
								AND ln_1st_prin_ba > 0 -- Is this the same that business rule "UPB > 0" ???
								AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
								AND rs.rs_step_cd = @stepCodes -- M76 as parameter
								AND ( @atDateTo BETWEEN ln.valid_from_date  AND ln.valid_through_date )
								AND ( @atDateTo BETWEEN re.valid_from_date  AND re.valid_through_date )
								AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
								AND ( @atDateTo BETWEEN rs.valid_from_date AND rs.valid_through_date )
					) AS res
			WHERE   res.rn = 1

    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInReoNotIncludingDirectCostCompletion]    Script Date: 8/14/2017 11:50:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE  PROCEDURE [BILLING].[GetLoansInReoNotIncludingDirectCostCompletion]
    @investors NVARCHAR(MAX),    
    @templateIds NVARCHAR(512),
    @atDate DATETIME,
	@atDateTo DATETIME,
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN
        		
		SELECT  *
		FROM    ( SELECT    ln.ln_no loan_number ,
							ud.[usr_6_pos1_xx] investor_code ,
							re.ln_no ,
							reo_setup_dt ,
							reo_status_cd ,
							ROW_NUMBER() OVER ( PARTITION BY re.ln_no ORDER BY re.reo_setup_dt DESC ) AS rn
					FROM    BDESime.dbo.dim_loan ln
							INNER JOIN BDESime.dbo.dim_user_defined ud WITH(NOLOCK) ON ln.ln_no = ud.ln_no
							INNER JOIN BDESime.dbo.dim_reo re WITH(NOLOCK) ON ln.ln_no = re.ln_no
							INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON re.ln_no = rs.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
							INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
							INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds,',') t ON t.Item = re.reo_template_id -- 'USDA, MARKET, VAMRKT' as parameter
							INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes,',') sc ON sc.Item = ln.ln_reo_status_cd -- 'A,C' as parameter
					WHERE   1=1
							AND CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN @atDate AND @atDateTo
							AND rs.rs_step_cd = @stepCodes -- M76 as parameter
							AND (ISNULL(re.reo_sale_price_am, 0) > 0)
							AND (re.reo_actl_close_dt IS NOT NULL)
							AND ln_1st_prin_ba > 0
							AND ( @atDateTo BETWEEN ln.valid_from_date  AND ln.valid_through_date )
							AND ( @atDateTo BETWEEN re.valid_from_date  AND re.valid_through_date )
							AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
							AND ( @atDateTo BETWEEN rs.valid_from_date AND rs.valid_through_date )							

				) AS res
		WHERE   res.rn = 1


    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInServicingAdvances]    Script Date: 8/14/2017 11:50:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
CREATE PROCEDURE [BILLING].[GetLoansInServicingAdvances]
    @investors NVARCHAR(MAX) ,    
    @atDate DATETIME,
	@atDateTo DATETIME
AS
    BEGIN
       	
		--SELECT  		
		--		CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
		--		t.ln_no AS loan_number,
		--		ud.usr_6_pos1_xx AS investor_code,
		--		'Servicing Advances' AS Payee_Description,
		--		SUM(t.adv_am) AS Sum_Amount,
		--		ROUND(AVG(t.adv_am),2) AS Average_Amount		     
		--FROM    BDESime.dbo.dim_corporate_adv_tran t WITH (NOLOCK) 
		--		INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON t.ln_no = ud.ln_no
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
		--		INNER JOIN BDESime.dbo.fnMultiValueSplit(@recoverableCodes,',') rc ON rc.Item = t.adv_recover_cd -- 'R,N' as parameter
		--WHERE   		
		--		 CAST(t.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
		--		 AND t.adv_am > 0
		--		 AND ( @atDateTo BETWEEN t.valid_from_date AND t.valid_through_date)
  --               AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		--GROUP BY ud.usr_6_pos1_xx,
		--		 t.ln_no, 
		--		 CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR)


		SELECT	
				CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) AS Month_Year,
				t.ln_no AS loan_number,
				ud.usr_6_pos1_xx AS investor_code,
				'Servicing Advances' AS Payee_Description,
				SUM(t.adv_am) AS Sum_Amount,
				ROUND(AVG(t.adv_am),2) AS Average_Amount
		FROM	BDESime.dbo.dim_corporate_adv_tran t WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON t.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
		WHERE 1=1
				AND adv_am > 0
				AND adv_trans_cd IN ('630', '631', '632', '633')
		
				--Excluding Property Inspection Fee, Appraisal Fee and Property Preservation
				AND NOT (adv_trans_cd = '631' AND adv_corp_payee_id IN ('77R77', '77N77', '77T77'))
				AND NOT (adv_trans_cd = '631' AND adv_corp_payee_id IN ('54R54', '54T54', '54N54'))
				AND NOT (adv_trans_cd = '633' AND adv_corp_payee_id IN ('78N78','78T78'))	

				AND CAST(t.adv_trans_dt AS DATE) BETWEEN @atDate AND @atDateTo
				AND ( @atDateTo BETWEEN t.valid_from_date AND t.valid_through_date)
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date)
		GROUP BY ud.usr_6_pos1_xx,
				 t.ln_no, 
				 CAST(MONTH(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR) + ' ' + CAST(YEAR(CAST(t.adv_trans_dt AS DATE)) AS VARCHAR)
				         
    END 
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInSpecialForbearancePlan]    Script Date: 8/14/2017 11:50:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInSpecialForbearancePlan]
    @investors NVARCHAR(MAX),
    @atDate DATETIME, -- Current Date
	@atDateFrom DATETIME = NULL, --Date From for filtering promise_to_pay2.[PROMISE CREATION DATE]
	@atDateTo DATETIME = NULL, --Date To for filtering promise_to_pay2.[PROMISE CREATION DATE]
	@statusCodes NVARCHAR(512),
	@stepCodes NVARCHAR(512)
AS
    BEGIN			
		
		SELECT  DISTINCT lm.ln_no loan_number,        				
				ud.usr_6_pos1_xx investor_code,
				lm.lm_set_up_dt
		FROM    BDESime.dbo.dim_loss_mitigation lm WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_lossmitigation_step lms WITH (NOLOCK)  ON lm.ln_no = lms.ln_no AND lm.lm_set_up_dt = lms.ls_setup_dt
					AND CAST(lms.ls_actual_compl_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes,',') sc ON sc.Item = lms.ls_step_cd -- 331 as parameter 
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON lm.ln_no = ud.ln_no
				--INNER JOIN BDESime.dbo.promise_to_pay2 ptp WITH (NOLOCK) ON lm.ln_no = ptp.[LOAN NUMBER]
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]				
		WHERE   lm.lm_status_cd = @statusCodes -- 'A' as parameter
				--AND CAST(lm.lm_set_up_dt AS DATE) = @atDate				
				--AND CAST(ptp.[PROMISE CREATION DATE] AS DATE) BETWEEN @atDateFrom AND @atDateTo				
				AND ( CAST(lm.lm_set_up_dt AS DATE) BETWEEN lm.valid_from_date AND lm.valid_through_date) 
				AND ( CAST(lm.lm_set_up_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date)  
				AND CAST(lms.ls_actual_compl_dt AS DATE) = @atDate
    END
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInVAFinalClaim]    Script Date: 8/14/2017 11:50:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 
CREATE PROCEDURE [BILLING].[GetLoansInVAFinalClaim]
    @investors NVARCHAR(MAX) ,
    @templateIds NVARCHAR(512) ,
    @statusCodes NVARCHAR(512) ,
    @stepCodes NVARCHAR(512) ,
    @atDate DATETIME
AS
    BEGIN
       	
		SELECT 
				re.ln_no loan_number ,
				ud.[usr_6_pos1_xx] investor_code , 
				rs.rs_setup_dt ,
				rs.rs_no,
				CAST(rs.rs_actual_compl_dt AS DATE) AS rs_actual_compl_dt
		FROM    BDESime.dbo.dim_reo re WITH (NOLOCK)                               
				INNER JOIN BDESime.dbo.dim_reo_steps rs WITH (NOLOCK) ON rs.ln_no = re.ln_no AND rs.rs_setup_dt = re.reo_setup_dt
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON re.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx           
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@templateIds, ',') t ON t.Item = re.reo_template_id --'VAPOST' as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@stepCodes, ',') s ON s.Item = rs.rs_step_cd -- R38,R39 as parameter
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@statusCodes, ',') c ON c.Item = re.reo_status_cd -- 'A' as parameter
		WHERE 1=1           						
			AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN re.valid_from_date AND re.valid_through_date)
			AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN rs.valid_from_date AND rs.valid_through_date OR CAST(rs.rs_actual_compl_dt AS DATE) = @atDate)
			AND (CAST(rs.rs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date) 		
        
    END 
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInVANoticeOfElectionToConvey]    Script Date: 8/14/2017 11:50:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [BILLING].[GetLoansInVANoticeOfElectionToConvey]
    @investors NVARCHAR(MAX),    
	@atDate DATETIME,
    @step_codes NVARCHAR(512),
	@status_codes NVARCHAR(512)    
AS
    BEGIN
        												
		SELECT  fc.ln_no AS loan_number ,
				MAX(fs.fc_setup_dt) AS fc_setup_dt,
				MAX(fs.FS_STEP_SEQ_NO) AS  FS_STEP_SEQ_NO,
				MAX(fs.fs_step_cd) AS fs_step_cd,
				MAX(ud.usr_6_pos1_xx) AS investor_code
								
		FROM    BDESime.dbo.dim_foreclosure fc  WITH (NOLOCK)
				INNER JOIN BDESime.dbo.dim_foreclosure_step fs WITH (NOLOCK) ON fc.ln_no = fs.ln_no AND fc.fc_setup_dt = fs.fc_setup_dt
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON fs.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = ud.usr_6_pos1_xx
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@step_codes, ',') s ON s.Item = fs.fs_step_cd -- '921,432' values
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@status_codes, ',') c ON c.Item = fc.fc_status_cd -- 'A' as parameter
		WHERE  1=1															
				AND CAST(fs.fs_actual_compl_dt AS DATE) BETWEEN fc.valid_from_date AND fc.valid_through_date				
				AND ( CAST(fs.fs_actual_compl_dt AS DATE) BETWEEN fs.valid_from_date AND fs.valid_through_date OR CAST(fs.fs_actual_compl_dt AS DATE) = @atDate)
				AND CAST(fs.fs_actual_compl_dt AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date                                                      
		GROUP BY fc.ln_no
		HAVING COUNT(*) >= 2 AND MAX(CAST(fs.fs_actual_compl_dt AS DATE)) = @atDate					
		

    END 
GO

/****** Object:  StoredProcedure [BILLING].[GetLoansInVerificationMortgageNonFHA]    Script Date: 8/14/2017 11:50:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BILLING].[GetLoansInVerificationMortgageNonFHA]
    @investors NVARCHAR(MAX),
    @atDate DATETIME,
	@letterCode NVARCHAR(512)
AS
    BEGIN
         
		 SELECT DISTINCT lw.[LOAN NUMBER],	
				usr_6_pos1_xx investor_code        
		 FROM	BDESime.dbo.letter_writer lw WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON lw.[LOAN NUMBER] = ud.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = usr_6_pos1_xx
		 WHERE  [LETTER ID] = @letterCode -- 'GE530' as parameter
				AND CAST(lw.[LETTER PROCESSING DATE]  AS DATE) = @atDate			
				AND CAST(lw.[LETTER PROCESSING DATE]  AS DATE) BETWEEN ud.valid_from_date AND ud.valid_through_date		 

    END
	 

GO

/****** Object:  StoredProcedure [BILLING].[GetLoansPastDue]    Script Date: 8/14/2017 11:50:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [BILLING].[GetLoansPastDue]
    @investors NVARCHAR(MAX),
    @atDate DATETIME ,
	@atDateTo DATETIME ,
    @delinquencyCode NVARCHAR(512)
AS
    BEGIN

		--,	CASE WHEN d.co_delq_cd = '1' THEN '30 - 59 DAYS DELINQUENT'
        --  WHEN de.co_delq_cd = '2' THEN '60 - 89 DAYS DELINQUENT'
        --  WHEN de.co_delq_cd = '3' THEN '90 - 119 DAYS DELINQUENT'
        --  WHEN de.co_delq_cd = '4' THEN '120+ DAYS DELINQUENT'
        --  WHEN de.co_delq_cd = 'D' THEN '16 - 29 DAYS DELINQUENT'
        --  WHEN de.co_delq_cd = 'P' THEN 'PREPAID OR CURREN


		-- 14. Loans 30 to 59 Days Past Due --> 1 as Parameter
		-- 15. Loans 60 to 89 Days Past Due --> 2 as Parameter
		-- 16. Loans 90 to 119 Days Past Due --> 3 as Parameter

        SELECT  ln.ln_no loan_number ,
				ud.[usr_6_pos1_xx] investor_code ,
				CAST(co_dlq_col_days_qt AS INT) days
		FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_user_defined ud  WITH (NOLOCK) ON ln.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.dim_delinquency de  WITH (NOLOCK) ON ln.ln_no = de.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE   de.co_delq_cd = @delinquencyCode
				AND ln_1st_prin_ba > 0        
				AND ( @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date )
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
				AND ( @atDateTo BETWEEN de.valid_from_date AND de.valid_through_date )

    END










GO

/****** Object:  StoredProcedure [BILLING].[GetLoansPastDueGreater]    Script Date: 8/14/2017 11:50:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  
CREATE PROCEDURE [BILLING].[GetLoansPastDueGreater]
    @investors NVARCHAR(1024),
    @atDate DATETIME,
	@atDateTo DATETIME,
    @delinquencyCode NVARCHAR(512)
AS
    BEGIN

		SELECT  ln.ln_no loan_number ,
				ud.[usr_6_pos1_xx] investor_code ,
				CAST(co_dlq_col_days_qt AS INT) days
		FROM    BDESime.dbo.dim_loan ln WITH (NOLOCK) 
				INNER JOIN BDESime.dbo.dim_user_defined ud WITH (NOLOCK) ON ln.ln_no = ud.ln_no
				INNER JOIN BDESime.dbo.dim_delinquency de WITH (NOLOCK) ON ln.ln_no = de.ln_no
				INNER JOIN BDESime.dbo.fnMultiValueSplit(@investors,',') i ON i.Item = [usr_6_pos1_xx]
		WHERE   de.co_delq_cd = @delinquencyCode -- 4 as Parameter
				AND ln_1st_prin_ba > 0        
				AND ( @atDateTo BETWEEN ln.valid_from_date AND ln.valid_through_date )
				AND ( @atDateTo BETWEEN ud.valid_from_date AND ud.valid_through_date )
				AND ( @atDateTo BETWEEN de.valid_from_date AND de.valid_through_date )
         
    END










GO


