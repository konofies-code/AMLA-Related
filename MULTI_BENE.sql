USE [PSBDB]
GO
/****** Object:  StoredProcedure [dbo].[SP_MULTIPLE_BENE_CP]    Script Date: 9/3/2025 1:50:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[SP_MULTIPLE_BENE_CP] AS
BEGIN
 
/**************************GET THE BENEFICIARY INFORMATION**********************/
BEGIN
    UPDATE AML_CUSTOMER SET IDENTIFICATION_NUMBER = '' 
    WHERE IDENTIFICATION_NUMBER = '0'
END

BEGIN 
    UPDATE ATM
    SET 
        BENEFICIARY_CUSTOMERREFNO = CUST.CUSTOMERNO,
        BENEFICIARY_DATEOFBIRTH  = CUST.DATEOFBIRTH,
        BENEFICIARY_IDNo = CUST.IDENTIFICATION_NUMBER,
        BENEFICIARY_IDType = CUST.IDENTIFICATION_TYPE,
        BENEFICIARY_NatureofBusiness = left(CUST.NATUREOFBUSINESS,35),
        BENEFICIARY_PLACEOFBIRTH = CUST.PLACEOFBIRTH,
        BENEFICIARYADDRESS1 = CUST.PRESENTADDRESS1,
        BENEFICIARYADDRESS2 = CUST.PRESENTADDRESS2,
        BENEFICIARYADDRESS3 = CUST.PRESENTADDRESS3,
        BENEFICIARYNAME1 = CUST.FIRSTNAME,
        BENEFICIARYNAME2 = CUST.MIDDLENAME,
        BENEFICIARYNAME3 = CUST.LASTNAME,
        BENEFICIARY_NAME_FLAG = CASE WHEN CUST.INDIVIDUAL_CORPORATE = 1  THEN 'N' WHEN CUST.INDIVIDUAL_CORPORATE = 2 THEN 'Y' END

    FROM AML_TRANSACTION ATM
        JOIN (
            SELECT * 
            FROM (
                SELECT A.ACCOUNTID,B.TXNID,C.CUSTOMERID,ROW_NUMBER() OVER(PARTITION BY A.ACCOUNTID,B.TXNID ORDER BY A.ACCOUNTID) COUNTS 
                FROM AML_ACCOUNT A
                    JOIN (
                        select BENEFICIARY_ACCOUNTNO,TXNID 
                        from AML_TRANSACTION 
                        WHERE TRIM(BENEFICIARY_ACCOUNTNO) IN 
                            (
                                SELECT ACCOUNTNUMBER 
                                FROM AML_ACCOUNT
                            ) 
                            AND SOURCE = 'CASA' 
                            AND TXNTYPE <> 'COCKD'
                            AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())

                    ) B ON A.ACCOUNTNUMBER = TRIM(B.BENEFICIARY_ACCOUNTNO)
                    JOIN AML_CUSTOMER_ACCOUNT C ON A.ACCOUNTID = C.ACCOUNTID
                GROUP BY A.ACCOUNTID,C.CUSTOMERID,B.TXNID
            ) TBL1 WHERE COUNTS = 1 
        ) ATM2 ON ATM.TXNID = ATM2.TXNID 
        JOIN AML_ACCOUNT ACCT ON ATM2.ACCOUNTID = ACCT.ACCOUNTID
        JOIN AML_CUSTOMER CUST ON CUST.CUSTOMERID = ATM2.CUSTOMERID
END

/***********************TRANSFER BENE TO COUNTER PARTY*********************/

BEGIN
    UPDATE AML_TRANSACTION 
    SET CPNAME1 = BENEFICIARYNAME1,
        CPNAME2 = BENEFICIARYNAME2,
        CPNAME3 = BENEFICIARYNAME3
    WHERE TXNTYPE = 'COCKD' 
        AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE()) 
        AND SOURCE = 'CASA'
        AND ((LEN(BENEFICIARYNAME1) = 12 and isnumeric(BENEFICIARYNAME1) = 0) or LEN(BENEFICIARYNAME1) <> 12)
END

/**************************GET THE COUNTER PARTY INFORMATION******************/

BEGIN
    UPDATE ATM
    SET cpaccountno = BENEFICIARY_ACCOUNTNO,
        BENEFICIARY_ACCOUNTNO = NULL,
        CPCUSTOMERREFNO = CUST.CUSTOMERNO,
        CPADDRESS1 = CUST.PRESENTADDRESS1,
        CPADDRESS2 = CUST.PRESENTADDRESS2,
        CPADDRESS3 = CUST.PRESENTADDRESS3,
        CPNAME1 = CUST.FIRSTNAME,
        CPNAME2 = CUST.MIDDLENAME,
        CPNAME3 = CUST.LASTNAME,
        CP_NAME_FLAG = CASE WHEN CUST.INDIVIDUAL_CORPORATE = 1  THEN 'N' WHEN CUST.INDIVIDUAL_CORPORATE = 2 THEN 'Y' END
    FROM AML_TRANSACTION ATM
        JOIN (
            SELECT * 
            FROM (
                SELECT A.ACCOUNTID,B.TXNID,C.CUSTOMERID,ROW_NUMBER() OVER(PARTITION BY A.ACCOUNTID,B.TXNID ORDER BY A.ACCOUNTID) COUNTS 
                FROM AML_ACCOUNT A
                    JOIN (
                        select BENEFICIARY_ACCOUNTNO,TXNID 
                        from AML_TRANSACTION 
                        WHERE LTRIM(RTRIM(BENEFICIARY_ACCOUNTNO)) IN (
                                SELECT ACCOUNTNUMBER 
                                FROM AML_ACCOUNT
                            ) 
                            AND SOURCE = 'CASA' 
                            AND TXNTYPE = 'COCKD'
                            AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())
                    ) B ON A.ACCOUNTNUMBER = LTRIM(RTRIM(B.BENEFICIARY_ACCOUNTNO))
                JOIN AML_CUSTOMER_ACCOUNT C ON A.ACCOUNTID = C.ACCOUNTID
            GROUP BY A.ACCOUNTID,C.CUSTOMERID,B.TXNID
            ) TBL1 WHERE COUNTS = 1 ) ATM2 ON ATM.TXNID = ATM2.TXNID 
        JOIN AML_ACCOUNT ACCT ON ATM2.ACCOUNTID = ACCT.ACCOUNTID
    INNER JOIN AML_CUSTOMER CUST ON CUST.CUSTOMERID = ATM2.CUSTOMERID
    WHERE  ATM.SOURCE = 'CASA'
END

BEGIN
    UPDATE AML_TRANSACTION 
    SET cpaccountno = BENEFICIARY_ACCOUNTNO,
        BENEFICIARY_ACCOUNTNO = NULL
    WHERE TXNTYPE = 'COCKD'
        AND  BENEFICIARY_ACCOUNTNO is not NULL 
        and CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())  
        AND SOURCE = 'CASA'
END

/**************************************************************************/
----------REMOVE BENE INFO FOR THOSE WHO DO NOT REQUIRE
---------------------------------------------Code xx
----------------------------------------2019-06-29
BEGIN
    update AML_TRANSACTION 
    set BENEFICIARY_CUSTOMERREFNO = NULL,
        BENEFICIARY_DATEOFBIRTH  = NULL,
        BENEFICIARY_IDNo = NULL,
        BENEFICIARY_IDType = NULL,
        BENEFICIARY_NatureofBusiness = NULL,
        BENEFICIARY_PLACEOFBIRTH = NULL,
        BENEFICIARYADDRESS1 = NULL,
        BENEFICIARYADDRESS2 = NULL,
        BENEFICIARYADDRESS3 = NULL,
        BENEFICIARYNAME1 = NULL,
        BENEFICIARYNAME2 = NULL,
        BENEFICIARYNAME3 = NULL,
        BENEFICIARY_NAME_FLAG = NULL,
        BENEFICIARY_ACCOUNTNO = NULL
    WHERE TXNTYPE NOT IN 
        (
	        SELECT DISTINCT TRAN_CODE 
            FROM AML_REGULATORY_REPORT_MANDATORY BB
	            JOIN AML_FIELD CC ON BB.FIELD_ID = CC.FIELD_ID
	        WHERE CC.DATASET_NAME = 'CTR1_Beneficiary'
		        AND (
                    FIELD_NAME = 'B_LASTNAME' 
                    OR FIELD_NAME = 'B_ACCOUNTNO' 
                    OR FIELD_NAME = 'B_FIRSTNAME'
                   )
        ) 
        AND TXNTYPE in (
            select distinct TRANSACTION_TYPE 
            from AML_CTR_TRANTYPE
        )
        and (BENEFICIARYNAME1 is not null or BENEFICIARYNAME3 is not null or BENEFICIARY_ACCOUNTNO is not null)
        AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())  AND SOURCE = 'CASA'
END


BEGIN
/***********SET THE DEFAULT BENEACCOUNTNUMBER FROM Transaction From/To Bank GL Account TO 240180104 ******************/

    UPDATE AML_TRANSACTION 
    SET BENEFICIARY_ACCOUNTNO = '240180104'
    WHERE CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE()) 
        AND TXNTYPE = 'CTRIA'
        AND LTRIM(RTRIM(BENEFICIARYNAME1)) = 'Transaction From/To Bank GL Account'  
        AND SOURCE = 'CASA'

/***********SET THE DEFAULT BENEACCOUNTNUMBER FROM Transaction From/To Bank GL Account TO 240180104 ******************/
END

Begin

    UPDATE AML_TRANSACTION 
    SET TXN_DATE_TIME=  TXNDATE   
    WHERE CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE()) 

    UPDATE AML_TRANSACTION 
    SET txndate = CONVERT(DATE,TXNDATE) 
    WHERE CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE()) 
END

begin

    UPDATE A 
    SET TXNTYPE = ( CASE WHEN ACCOUNTTYPE IN ('901','902','903','904','906','907','908','909','911','912','913','914') THEN 'DTDYK' ELSE'CTRIA'END )
    from aml_transaction a
        left join aml_account b on a.accountnumber = b.ACCOUNTNUMBER
    where PRODUCTTYPE = 'FTRQ' 
        AND TXNMODE = 'DR'
        and convert(date,A.IMPORTED_DATE) = CONVERT(DATE,GETDATE())

end


BEGIN
    update a 
    set txntype = 'DTDPM' 
    FROM AML_TRANSACTION a 
        left join ref_treasury_accounts b on a.ACCOUNTNUMBER =b.ACCOUNTNO
    WHERE --ACCOUNTNUMBER = '111120240242'
        b.accountno is not null and producttype = 'ftrq' 
    AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())

END



BEGIN
    update a 
    set txntype = 'DTDPD' 
    FROM AML_TRANSACTION a 
        left join ref_treasury_accounts b on a.ACCOUNTNUMBER =b.ACCOUNTNO
    WHERE --ACCOUNTNUMBER = '111120240242'
        b.accountno is not null and producttype = 'DEBK' 
        AND CONVERT(DATE,IMPORTED_DATE) = CONVERT(DATE,GETDATE())
END

begin
    delete a 
    from aml_transaction a
        left join aml_account b on a.AccountNumber = b.ACCOUNTNUMBER
    where a.txntype IN ('DTDPD','DTDYK' )
        and ACCOUNTTYPE NOT IN ('901','902','903','904','906','907','908','909','911','912','913','914')
end

BEGIN
    UPDATE AML_TRANSACTION 
    SET TXNTYPE = 'DTDYM'
    WHERE TXNTYPE = 'DTDPM'
END

begin
    insert into AML_CUSTOMER_ACCOUNT ( CUSTOMERID, ACCOUNTID, JOINTID, IMPORTED_DATE)
    select a.CUSTOMERID, 
        a.ACCOUNTID ,
        (select max(jointid) from AML_CUSTOMER_ACCOUNT) + ROW_NUMBER() over (order by a.accountid) as JointID,
        getdate()
    from aml_account a
        left join Aml_customer_account ca on a.ACCOUNTID = ca.ACCOUNTID and a.CUSTOMERID = ca.CUSTOMERID
    where ca.JOINTID is null
end


BEGIN
    UPDATE  A 
    SET TXNTYPE = 'DTDYW'
    FROM AML_TRANSACTION A
        LEFT JOIN AML_ACCOUNT B ON A.AccountNumber = B.ACCOUNTNUMBER
    WHERE PRODUCTTYPE = 'FTRQ'
        AND B.OFF_EMP_ID = 4
END

BEGIN
/*********** HAS BENEFICIARY ACCOUNT FOR CPMD/CTRIA ******************/
    UPDATE ATM 
    SET BENEFICIARY_CUSTOMERREFNO = '', 
        BENEFICIARY_DATEOFBIRTH = '', 
        BENEFICIARY_IDNo = '', 
        BENEFICIARY_IDType = '', 
        BENEFICIARY_NatureofBusiness = '', 
        BENEFICIARY_PLACEOFBIRTH = '', 
        BENEFICIARYADDRESS1 = '', 
        BENEFICIARYADDRESS2 = '', 
        BENEFICIARYADDRESS3 = '', 
        BENEFICIARYNAME1 = CUST.FIRSTNAME, 
        BENEFICIARYNAME2 = CUST.MIDDLENAME, 
        BENEFICIARYNAME3 = CUST.LASTNAME, 
        BENEFICIARY_NAME_FLAG = CASE WHEN CUST.INDIVIDUAL_CORPORATE = 1 THEN 'N' WHEN CUST.INDIVIDUAL_CORPORATE = 2 THEN 'Y' END
    FROM AML_TRANSACTION ATM 
        JOIN (
            SELECT * 
            FROM 
                (
                SELECT 
                    A.ACCOUNTID, 
                    B.TXNID, 
                    C.CUSTOMERID, 
                    ROW_NUMBER() OVER( PARTITION BY A.ACCOUNTID, B.TXNID  ORDER BY A.ACCOUNTID) COUNTS 
                FROM AML_ACCOUNT A 
                    JOIN (
                        select BENEFICIARY_ACCOUNTNO, 
                            TXNID 
                        from AML_TRANSACTION 
                        WHERE LTRIM( RTRIM(BENEFICIARY_ACCOUNTNO)) IN (
                                SELECT ACCOUNTNUMBER FROM  AML_ACCOUNT
                            ) 
                            AND SOURCE = 'CASA' 
                            AND TXNTYPE IN ('CPMD', 'CTRIA') 
                            AND CONVERT(DATE, IMPORTED_DATE) = CONVERT(DATE, GETDATE() )
                    ) B ON A.ACCOUNTNUMBER = LTRIM(RTRIM(B.BENEFICIARY_ACCOUNTNO)) 
            JOIN AML_CUSTOMER_ACCOUNT C ON A.ACCOUNTID = C.ACCOUNTID 
            GROUP BY 
              A.ACCOUNTID, 
              C.CUSTOMERID, 
              B.TXNID
          ) TBL1 
        WHERE 
          COUNTS = 1
      ) ATM2 ON ATM.TXNID = ATM2.TXNID 
      INNER JOIN AML_ACCOUNT ACCT ON ATM2.ACCOUNTID = ACCT.ACCOUNTID
      INNER JOIN AML_CUSTOMER CUST ON CUST.CUSTOMERID = ATM2.CUSTOMERID
/********************************************************************/
END

BEGIN
/***************************** HAS NO BENEFICIARY ACCOUNT ***************************************/
    Update AML_TRANSACTION       
    Set BENEFICIARY_NAME_FLAG = CASE WHEN BENEFICIARY_ACCOUNTNO IS NULL THEN 'Y' ELSE BENEFICIARY_NAME_FLAG END
    Where SOURCE = 'CASA' 
        AND TXNTYPE IN ('CPMD', 'CTRIA', 'CCMC') 
        AND CONVERT(DATE, IMPORTED_DATE) = CONVERT(DATE, GETDATE())
END
/********************************************************************/

BEGIN
/******************************** Remove BENEFICIARY_ACOUNTNO in CPMD ************************************/
    Update AML_TRANSACTION
    Set BENEFICIARY_ACCOUNTNO = NULL
    Where SOURCE = 'CASA' 
    AND TXNTYPE = 'CPMD'
    AND CONVERT(DATE, IMPORTED_DATE) = CONVERT(DATE, GETDATE())
END

END



