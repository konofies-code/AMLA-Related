

USE [Base60_PROD2]
GO
/****** Object:  StoredProcedure [dbo].[CTR_GENERATION]    Script Date: 9/3/2025 1:45:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--BATSI NA TAYO PREEE!!
-- SGE


ALTER   PROCEDURE [dbo].[CTR_GENERATION]
(
    @sceId      NUMERIC(10),
    @NotRequired_NonMandatoryParties_Data BIT,
    @Deferred_TXN_Reporting_Enable BIT
)
AS
BEGIN

    DECLARE @TransactionValue numeric(16, 2);
    DECLARE @Period numeric(2);
    DECLARE @TransactionType varchar(max);
    DECLARE @TXNQuery varchar(max);
    DECLARE @RanDate varchar(25);

    Declare @bid [numeric](30);
    Declare @cpid [numeric](30);
    Declare @iid [numeric](30);
    Declare @opid [numeric](30);
    Declare @sid [numeric](30);
    Declare @tid [numeric](30);
    Declare @id [numeric](30);
    Declare @BRANCHCODE [varchar](50);
    Declare @TXNAMOUNT [numeric](16, 2);
    Declare @CURRENCY [varchar](5);
    Declare @FXAMOUNT [numeric](16, 2);
    Declare @TXNID [numeric](38, 0);
    Declare @EXPORTED [varchar](1);
    Declare @DETAILINDICATOR [varchar](1);
    Declare @TXNDATE [datetime];
    Declare @TXN_DATE_IDX [date]; -- Added by viShnu.K for # on 03Aug2K18 -- Modify by REMAGSINO
    Declare @TXNTYPE [varchar](6);
    Declare @TXNREFNO [varchar](50);
    Declare @INDIVIDUAL_CORPORATE [varchar](1);
    Declare @INCEPTIONDATE [datetime];
    Declare @MATUITYDATE [datetime];
    Declare @AMOUNTOFCLAIM [numeric](18, 2);
    Declare @ACCOUNTID [numeric](38, 0);
    Declare @ACCOUNTNUMBER [varchar](50);
    Declare @AccountBranchCode [varchar](10);
    Declare @StockRefNo [varchar](50);
    Declare @Purpose [varchar](255);
    Declare @NoofShares [numeric](18, 2);
    Declare @NetAssetValue [numeric](18, 2);
    Declare @CORRESPONDENTBANKNAME [varchar](100);
    Declare @CORRESBANKADDRESS1 [varchar](100);
    Declare @CORRESBANKADDRESS2 [varchar](100);
    Declare @CORRESBANKADDRESS3 [varchar](100);
    Declare @CORRESBANKCOUNTRYCODE [varchar](50);

    Declare @CPNAME1 [varchar](100);
    Declare @CPNAME2 [varchar](100);
    Declare @CPNAME3 [varchar](250);
    Declare @CPADDRESS1 [varchar](100);
    Declare @CPADDRESS2 [varchar](100);
    Declare @CPADDRESS3 [varchar](100);
    Declare @BENEFICIARYNAME1 [varchar](100);
    Declare @BENEFICIARYNAME2 [varchar](100);
    Declare @BENEFICIARYNAME3 [varchar](250);
    Declare @BENEFICIARYADDRESS1 [varchar](100);
    Declare @BENEFICIARYADDRESS2 [varchar](100);
    Declare @BENEFICIARYADDRESS3 [varchar](100);
    Declare @OPACCOUNTNO [varchar](100);
    Declare @BENEFICIARYCOUNTRY  [varchar](50);
    Declare @BENEFICIARY_CUSTOMERREFNO [varchar](30);
    Declare @BENEFICIARY_ACCOUNTNO [varchar](40);
    Declare @BENEFICIARY_DATEOFBIRTH [varchar] (110);
    Declare @BENEFICIARY_PLACEOFBIRTH [varchar](90);
    Declare @BENEFICIARY_IDType [varchar](4);
    Declare @BENEFICIARY_IDNo [varchar](30);
    Declare @BENEFICIARY_TelNo [varchar](15);
    Declare @BENEFICIARY_NatureofBusiness [varchar](35);
    Declare @TRANSACTOR_CUSTOMERREFNO [varchar](30);
    Declare @TRANSACTOR_NAME1 [varchar](100);
    Declare @TRANSACTOR_NAME2 [varchar](100);
    Declare @TRANSACTOR_NAME3 [varchar](250);
    Declare @TRANSACTOR_ADDRESS1 [varchar](100);
    Declare @TRANSACTOR_ADDRESS2 [varchar](100);
    Declare @TRANSACTOR_ADDRESS3  [varchar](100);
    Declare @TRANSACTOR_ACCOUNTNO [varchar](100);
    Declare @COUNTERPARTY_CUSTOMERREFNO [varchar](30);
    Declare @COUNTERPARTY_ACCOUNTNO [varchar](40);
    Declare @OP_CUSTOMERREFNO [varchar](30);
    Declare @OP_NAME1 [varchar](100);
    Declare @OP_NAME2 [varchar](100);
    Declare @OP_NAME3 [varchar](250);
    Declare @OP_ADDRESS1 [varchar](100);
    Declare @OP_ADDRESS2 [varchar](100);
    Declare @OP_ADDRESS3 [varchar](100);
    Declare @ISSUER_CUSTOMERREFNO [varchar](30);
    Declare @ISSUER_NAME1 [varchar](100);
    Declare @ISSUER_NAME2 [varchar](100);
    Declare @ISSUER_NAME3 [varchar](250);
    Declare @ISSUER_ADDRESS1 [varchar](100);
    Declare @ISSUER_ADDRESS2 [varchar](100);
    Declare @ISSUER_ADDRESS3 [varchar](100);
    Declare @ISSUER_ACCOUNTNO [varchar](40);
    Declare @flag [numeric] (2);
    -- Start:55737 - Base60AML has to validate only the mandatory parties as per BSP Reporting Procedures
    --Declare @NotRequired_NonMandatoryParties_Data BIT;
    Declare @AccountHolder_Data_Required BIT;
    Declare @Beneficiary_Data_Required BIT;
    Declare @CP_Data_Required BIT;
    Declare @Issuer_Data_Required BIT;
    Declare @OP_Data_Required BIT;
    Declare @Transactor_Data_Required BIT;
    Declare @Dataset_Name [varchar](30);
    Declare @Mandatory_TXNType [varchar](5);

    Declare @BENEFICIARY_NAME_FLAG [varchar](1);
    Declare @CP_NAME_FLAG [varchar](1);
    Declare @OP_NAME_FLAG [varchar](1);
    Declare @ISSUER_NAME_FLAG [varchar](1);
    Declare @TRANSACTOR_NAME_FLAG [varchar](1);
    Declare @customerSelectQuery varchar(max);
    Declare @multiPartiesExec varchar(max) = '';/* Start : iNiA #96954 multiple parties -vinothkumar.c 27-Feb-2016 */

    --set @NotRequired_NonMandatoryParties_Data = 1;
    set @Mandatory_TXNType = '';
    -- End:55737 - Base60AML has to validate only the mandatory parties as per BSP Reporting Procedures

    set @flag = 0;
    set @EXPORTED = '0';
    set @DETAILINDICATOR = 'D';

    set @customerSelectQuery = 'SELECT r1.customerno,r1.firstname,r1.middlename,r1.lastname,r1.'
        + [dbo].[CTR1_STR1_GENERATION_GET_SOURCE_ADDRESS_FIELD_NAME]('CTR1', 'CTR_ACCOUNTHOLDER_CUSTOMERDETAILS_INSERT', 'presentaddress1', 'A')
        + ',r1.' + [dbo].[CTR1_STR1_GENERATION_GET_SOURCE_ADDRESS_FIELD_NAME]('CTR1', 'CTR_ACCOUNTHOLDER_CUSTOMERDETAILS_INSERT', 'presentaddress2', 'A')
        + ',r1.' + [dbo].[CTR1_STR1_GENERATION_GET_SOURCE_ADDRESS_FIELD_NAME]('CTR1', 'CTR_ACCOUNTHOLDER_CUSTOMERDETAILS_INSERT', 'presentaddress3', 'A')
        + ',r1.dateofbirth,r1.placeofbirth, RTRIM(LTRIM(isNull(r1.NATIONALITY_NAME,''''))) as NATIONALITY_NAME,
               (SELECT TOP 1 identificationtype
                FROM   aml_customer_identification
                WHERE  customerid = r1.customerid
                and IDENTIFICATIONTYPE is not null and LTRIM(RTRIM(IDENTIFICATIONTYPE)) <> ''''
                and IDENTIFICATIONNO is not null and LTRIM(RTRIM(IDENTIFICATIONNO)) <> ''''
                order by IMPORTED_DATE desc) AS IDENTIFICATIONTYPE,
               (SELECT TOP 1 identificationno
                FROM   aml_customer_identification
                WHERE  customerid = r1.customerid
                and IDENTIFICATIONTYPE is not null and LTRIM(RTRIM(IDENTIFICATIONTYPE)) <> ''''
                and IDENTIFICATIONNO is not null and LTRIM(RTRIM(IDENTIFICATIONNO)) <> ''''
                order by IMPORTED_DATE desc) AS IDENTIFICATIONNO,
               r1.resphone,r1.natureofbusiness,r1.individual_corporate
        FROM   (SELECT c.*, ac.NATIONALITY_NAME
                FROM   aml_account a,aml_customer_account ca,aml_customer c';

    --->1
    select @id = ISNULL(MAX(ID),0)+1 from AML_CTR1
    select @bid = ISNULL(MAX(ID),0)+1 from AML_CTR1_BENEFICIARY
    select @cpid = ISNULL(MAX(ID),0)+1 from AML_CTR1_COUNTERPARTY
    select @iid = ISNULL(MAX(ID),0)+1 from AML_CTR1_ISSUER
    select @opid = ISNULL(MAX(ID),0)+1 from AML_CTR1_OTHERPARTICIPANT
    select @tid = ISNULL(MAX(ID),0)+1 from AML_CTR1_TRANSACTOR

    if exists (select 1 from sys.tables where name like '%TEMP_ID%')
    begin
        drop table TEMP_ID
    end;
    else
    begin
        create table TEMP_ID (ID numeric(20));
    end;

    -- Start: Fetching fieldLength dinamically
        BEGIN

            Declare @BRANCHCODE_LEN [numeric](3);
            Declare @CURRENCY_LEN [numeric](3);
            Declare @TXNTYPE_LEN [numeric](3);
            Declare @StockRefNo_LEN [numeric](3);
            Declare @Purpose_LEN [numeric](3);
            Declare @CORRESPONDENTBANKNAME_LEN [numeric](3);
            Declare @CORRESBANKADDRESS1_LEN [numeric](3);
            Declare @CORRESBANKADDRESS2_LEN [numeric](3);
            Declare @CORRESBANKADDRESS3_LEN [numeric](3);
            Declare @CORRESBANKCOUNTRYCODE_LEN [numeric](3);
            Declare @INTERNAL_FIELD_NAME [varchar](200);
            Declare @FIELD_LENGTH [numeric](5);
            Declare @ACCOUNTNUMBER_LEN [numeric](3);


            declare fieldLength cursor for
                SELECT INTERNAL_FIELD_NAME,FIELD_LENGTH FROM AML_INTERNAL_FIELDS_PROPERTIES
                    WHERE DATASET_NAME = 'CTR1'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'A$_%' ESCAPE '$'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'B$_%' ESCAPE '$'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'C$_%' ESCAPE '$'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'I$_%' ESCAPE '$'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'O$_%' ESCAPE '$'
                    AND INTERNAL_FIELD_NAME NOT LIKE 'T$_%' ESCAPE '$'
                    ORDER by INTERNAL_FIELD_NAME

            open fieldLength;

            fetch next from fieldLength into @INTERNAL_FIELD_NAME, @FIELD_LENGTH

            while(@@FETCH_STATUS = 0)
                begin

                    if (@INTERNAL_FIELD_NAME = 'BRANCHCODE')
                    begin
                        SET @BRANCHCODE_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CURRENCY')
                    begin
                        SET @CURRENCY_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'TXNTYPE')
                    begin
                        SET @TXNTYPE_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'STOCKREFNO')
                    begin
                        SET @StockRefNo_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'NATURE_OF_TRANSACTION')
                    begin
                        SET @Purpose_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CORRESPONDENTBANKNAME')
                    begin
                        SET @CORRESPONDENTBANKNAME_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CORRESBANKADDRESS1')
                    begin
                        SET @CORRESBANKADDRESS1_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CORRESBANKADDRESS2')
                    begin
                        SET @CORRESBANKADDRESS2_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CORRESBANKADDRESS3')
                    begin
                        SET @CORRESBANKADDRESS3_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'CORRESBANKCOUNTRYCODE')
                    begin
                        SET @CORRESBANKCOUNTRYCODE_LEN = @FIELD_LENGTH;
                    end;
                    if (@INTERNAL_FIELD_NAME = 'ACCOUNTNUMBER')
                    begin
                        SET @ACCOUNTNUMBER_LEN = @FIELD_LENGTH;
                    end;

                    fetch next from fieldLength into @INTERNAL_FIELD_NAME, @FIELD_LENGTH
                end;

                close fieldLength;
                deallocate fieldLength;

        END
    -- End: Fetching fieldLength dinamically

    --->2
    SELECT @TransactionValue = S.CTR_TRANSACTION_VALUE, @Period = S.CTR_PERIOD,
    @TransactionType = STUFF((SELECT ','+ '''' + ct.TRANSACTION_TYPE + '''' FROM AML_CTR_TRANTYPE ct WHERE  S.CTR_ID = ct.CTR_ID FOR XML PATH('')),1,1,'')
    FROM
        (
            select c.CTR_TRANSACTION_VALUE,c.CTR_PERIOD,c.CTR_ID
            from AML_REGULATORY_CTR c
            where c.CTR_ID = @sceId
            and c.ACTIVE = 1
        ) S
    WHERE 1 = 1

    --->3
    select @RanDate = ran_date from SCENARIO_RUN_STATUS where type = 'CTR1' and scenario_id = @sceId;

    --->4
    select @flag = COUNT(name) from sys.tables where name = 'temp_ctr1'

    if @flag > 0
        Drop table temp_ctr1;

    --->5

    /* Replaced by viShnu.K for #261153 on 25Jul2K18
    set @TXNQuery = 'SELECT DISTINCT t.TXNID, t.TXNDATE, t.TXNREFNO, t.TXNTYPE, t.TXNAMOUNT, t.BRANCHCODE ,t.CURRENCY, t.PURPOSE, t.CPNAME1, t.CPNAME2, t.CPNAME3, t.CPADDRESS1, */
    set @TXNQuery = 'SELECT DISTINCT t.TXNID, t.TXN_DATE_TIME, t.TXNREFNO, t.TXNTYPE, t.TXNAMOUNT, t.BRANCHCODE ,t.CURRENCY, t.PURPOSE, t.CPNAME1, t.CPNAME2, t.CPNAME3, t.CPADDRESS1,
                        t.CPADDRESS2, t.CPADDRESS3, t.CORRESPONDENTBANK, t.CORRESBANKCOUNTRYCODE, t.CORRESBANKADDRESS1, t.CORRESBANKADDRESS2, t.CORRESBANKADDRESS3,
                        t.INCEPTIONDATE, t.MATUITYDATE, t.FXAMOUNT, t.BENEFICIARYNAME1, t.BENEFICIARYNAME2, t.BENEFICIARYNAME3, t.BENEFICIARYADDRESS1,
                        t.BENEFICIARYADDRESS2, t.BENEFICIARYADDRESS3, t.ACCOUNTID, t.OPACCOUNTNO, t.BENEFICIARYCOUNTRY, t.STOCKREFNO, t.AMOUNTOFCLAIM,
                        t.NOOFSHARES, t.NETASSETVALUE, t.BENEFICIARY_CUSTOMERREFNO, t.BENEFICIARY_ACCOUNTNO, t.BENEFICIARY_DATEOFBIRTH, t.BENEFICIARY_PLACEOFBIRTH,
                        t.BENEFICIARY_IDType, t.BENEFICIARY_IDNo, t.BENEFICIARY_TelNo, t.BENEFICIARY_NatureofBusiness,
                        t.TRANSACTOR_CUSTOMERREFNO, t.TRANSACTOR_NAME1, t.TRANSACTOR_NAME2, t.TRANSACTOR_NAME3, t.TRANSACTOR_ADDRESS1, t.TRANSACTOR_ADDRESS2, t.TRANSACTOR_ADDRESS3,
                        t.TRANSACTOR_ACCOUNTNO, t.CPCUSTOMERREFNO, t.CPACCOUNTNO, t.OP_CUSTOMERREFNO, t.OP_NAME1, t.OP_NAME2, t.OP_NAME3, t.OP_ADDRESS1, t.OP_ADDRESS2,
                        t.OP_ADDRESS3, t.ISSUER_CUSTOMERREFNO, t.ISSUER_NAME1, t.ISSUER_NAME2, t.ISSUER_NAME3, t.ISSUER_ADDRESS1, t.ISSUER_ADDRESS2, t.ISSUER_ADDRESS3, t.ISSUER_ACCOUNTNO,
                        a.ACCOUNTNUMBER, a.BRANCHCODE as AccountBranchCode,' +
                        --t.BENEFICIARY_NAME_FLAG, t.CP_NAME_FLAG, t.OP_NAME_FLAG, t.ISSUER_NAME_FLAG, t.TRANSACTOR_NAME_FLAG into temp_ctr1	 Replaced by viShnu.K for # on 03Aug2K18
                        't.BENEFICIARY_NAME_FLAG, t.CP_NAME_FLAG, t.OP_NAME_FLAG, t.ISSUER_NAME_FLAG, t.TRANSACTOR_NAME_FLAG, t.TXNDATE into temp_ctr1
                    FROM AML_TRANSACTION t, AML_ACCOUNT a, AML_CUSTOMER_ACCOUNT ca
                    WHERE t.ACCOUNTID = a.ACCOUNTID
                    AND ca.ACCOUNTID = a.ACCOUNTID
                    AND t.TXNAMOUNT >= ' + cast(@TransactionValue as varchar)+
                    ' AND (t.IMPORTED_DATE BETWEEN (getdate () - ' + cast(@Period as varchar)+ ' ) AND getdate())' + ' AND (TXNSUBTYPE <> ''BB7'' OR TXNSUBTYPE IS NULL)'; -- Added by JJKumar 22Apr2K24;

    if @RanDate is not null and @RanDate <> ''
        set @TXNQuery = @TXNQuery + ' AND t.IMPORTED_DATE > ''' + cast(CONVERT (datetime, @RanDate, 103) as varchar) + '''';

    if @TransactionType is not null and @TransactionType <> ''
        set @TXNQuery = @TXNQuery + ' AND t.TXNTYPE IN (' + @TransactionType + ')';

    BEGIN TRAN
    BEGIN TRY

    --->6
    --print @TXNQuery;
    exec(@TXNQuery);
    --print '6';

    --->7
    declare txnCursor cursor for
    /* Replaced by viShnu.K for #261153 on 25Jul2K18
    SELECT t.TXNID, t.TXNDATE, t.TXNREFNO, t.TXNTYPE, t.TXNAMOUNT, t.BRANCHCODE, t.CURRENCY, t.PURPOSE, t.CPNAME1, t.CPNAME2, t.CPNAME3, t.CPADDRESS1,*/
    SELECT t.TXNID, t.TXN_DATE_TIME, t.TXNREFNO, t.TXNTYPE, t.TXNAMOUNT, t.BRANCHCODE, t.CURRENCY, t.PURPOSE, t.CPNAME1, t.CPNAME2, t.CPNAME3, t.CPADDRESS1,
        t.CPADDRESS2, t.CPADDRESS3, t.CORRESPONDENTBANK, t.CORRESBANKCOUNTRYCODE, t.CORRESBANKADDRESS1, t.CORRESBANKADDRESS2, t.CORRESBANKADDRESS3,
        t.INCEPTIONDATE, t.MATUITYDATE, t.FXAMOUNT, t.BENEFICIARYNAME1, t.BENEFICIARYNAME2, t.BENEFICIARYNAME3, t.BENEFICIARYADDRESS1,
        t.BENEFICIARYADDRESS2, t.BENEFICIARYADDRESS3, t.ACCOUNTID, t.OPACCOUNTNO, t.BENEFICIARYCOUNTRY, t.STOCKREFNO, t.AMOUNTOFCLAIM,
        t.NOOFSHARES, t.NETASSETVALUE, t.BENEFICIARY_CUSTOMERREFNO, t.BENEFICIARY_ACCOUNTNO, t.BENEFICIARY_DATEOFBIRTH, t.BENEFICIARY_PLACEOFBIRTH,
        t.BENEFICIARY_IDType, t.BENEFICIARY_IDNo, t.BENEFICIARY_TelNo, t.BENEFICIARY_NatureofBusiness,
        t.TRANSACTOR_CUSTOMERREFNO, t.TRANSACTOR_NAME1, t.TRANSACTOR_NAME2, t.TRANSACTOR_NAME3, t.TRANSACTOR_ADDRESS1, t.TRANSACTOR_ADDRESS2, t.TRANSACTOR_ADDRESS3,
        t.TRANSACTOR_ACCOUNTNO, t.CPCUSTOMERREFNO, t.CPACCOUNTNO, t.OP_CUSTOMERREFNO, t.OP_NAME1, t.OP_NAME2, t.OP_NAME3, t.OP_ADDRESS1, t.OP_ADDRESS2,
        t.OP_ADDRESS3, t.ISSUER_CUSTOMERREFNO, t.ISSUER_NAME1, t.ISSUER_NAME2, t.ISSUER_NAME3, t.ISSUER_ADDRESS1, t.ISSUER_ADDRESS2, t.ISSUER_ADDRESS3, t.ISSUER_ACCOUNTNO,
        -- t.ACCOUNTNUMBER, t.AccountBranchCode, t.BENEFICIARY_NAME_FLAG, t.CP_NAME_FLAG, t.OP_NAME_FLAG, t.ISSUER_NAME_FLAG, t.TRANSACTOR_NAME_FLAG FROM temp_ctr1 t  order by t.TXNTYPE asc;		 Replaced by viShnu.K for # on 03Aug2K18
        t.ACCOUNTNUMBER, t.AccountBranchCode, t.BENEFICIARY_NAME_FLAG, t.CP_NAME_FLAG, t.OP_NAME_FLAG, t.ISSUER_NAME_FLAG, t.TRANSACTOR_NAME_FLAG, t.TXNDATE FROM temp_ctr1 t  order by t.TXNTYPE asc;
        

    open txnCursor;

    fetch next from txnCursor into @TXNID,@TXNDATE,@TXNREFNO,@TXNTYPE,@TXNAMOUNT,@BRANCHCODE,@CURRENCY,@PURPOSE,@CPNAME1,@CPNAME2,@CPNAME3,@CPADDRESS1,
                @CPADDRESS2,@CPADDRESS3,@CORRESPONDENTBANKNAME,@CORRESBANKCOUNTRYCODE,@CORRESBANKADDRESS1,@CORRESBANKADDRESS2,
                @CORRESBANKADDRESS3,@INCEPTIONDATE,@MATUITYDATE,@FXAMOUNT,@BENEFICIARYNAME1,@BENEFICIARYNAME2,@BENEFICIARYNAME3,
                @BENEFICIARYADDRESS1,@BENEFICIARYADDRESS2,@BENEFICIARYADDRESS3,@ACCOUNTID,@OPACCOUNTNO,@BENEFICIARYCOUNTRY,
                @STOCKREFNO,@AMOUNTOFCLAIM,@NOOFSHARES,@NETASSETVALUE,@BENEFICIARY_CUSTOMERREFNO,@BENEFICIARY_ACCOUNTNO,
                @BENEFICIARY_DATEOFBIRTH,@BENEFICIARY_PLACEOFBIRTH,@BENEFICIARY_IDType,@BENEFICIARY_IDNo,@BENEFICIARY_TelNo,
                @BENEFICIARY_NatureofBusiness,
                @TRANSACTOR_CUSTOMERREFNO,@TRANSACTOR_NAME1,@TRANSACTOR_NAME2,@TRANSACTOR_NAME3,@TRANSACTOR_ADDRESS1,@TRANSACTOR_ADDRESS2,
                @TRANSACTOR_ADDRESS3,@TRANSACTOR_ACCOUNTNO,@COUNTERPARTY_CUSTOMERREFNO,@COUNTERPARTY_ACCOUNTNO,@OP_CUSTOMERREFNO,
                @OP_NAME1,@OP_NAME2,@OP_NAME3,@OP_ADDRESS1,@OP_ADDRESS2,@OP_ADDRESS3,@ISSUER_CUSTOMERREFNO,@ISSUER_NAME1,@ISSUER_NAME2,
                @ISSUER_NAME3,@ISSUER_ADDRESS1,@ISSUER_ADDRESS2,@ISSUER_ADDRESS3,@ISSUER_ACCOUNTNO,@ACCOUNTNUMBER,@AccountBranchCode,
                -- @BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG	Replaced by viShnu.K for # on 03Aug2K18
                @BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG, @TXN_DATE_IDX
                

    while(@@FETCH_STATUS = 0)
    begin

        BEGIN TRY
            --->a
            if @BRANCHCODE is not null and Ltrim(Rtrim(@BRANCHCODE)) <> ''
                set @BRANCHCODE = LEFT(@BRANCHCODE, @BRANCHCODE_LEN);
            else
            begin
                declare @causeError numeric(30);
                set @causeError = 1/0;
            end
            --->b
            if @CURRENCY is not null and @CURRENCY <> ''
                set @CURRENCY = LEFT(@CURRENCY, @CURRENCY_LEN);
            else
                set @CURRENCY = isnull(@CURRENCY,'');

            --->c
            /* if @CURRENCY is not null and @CURRENCY <> ''
                set @CURRENCY = LEFT(@CURRENCY, 3);
            else
                set @CURRENCY = isnull(@CURRENCY,''); */

            --->d
            if @TXNTYPE is not null and @TXNTYPE <> ''
                set @TXNTYPE = LEFT(@TXNTYPE, @TXNTYPE_LEN);
            else
                set @TXNTYPE = isnull(@TXNTYPE,'');

            --->e
                --set @INCEPTIONDATE = isnull(@INCEPTIONDATE,'');

            --->f
                --set @MATUITYDATE = isnull(@MATUITYDATE,'');

            --->g
            if @StockRefNo is not null and @StockRefNo <> ''
                set @StockRefNo = LEFT(@StockRefNo, @StockRefNo_LEN);
            else
                set @StockRefNo = isnull(@StockRefNo,'');

            --->h
            if @Purpose is not null and @Purpose <> ''
                set @Purpose = LEFT(@Purpose, @Purpose_LEN);
            else
                set @Purpose = isnull(@Purpose,'');

            --->i
                set @NoofShares = isnull(@NoofShares,0.00);

            --->j
                set @NetAssetValue = isnull(@NetAssetValue,0.00);

            --->k
            if @CORRESPONDENTBANKNAME is not null and @CORRESPONDENTBANKNAME <> ''
                set @CORRESPONDENTBANKNAME = LEFT(@CORRESPONDENTBANKNAME, @CORRESPONDENTBANKNAME_LEN);
            else
                set @CORRESPONDENTBANKNAME = isnull(@CORRESPONDENTBANKNAME,'');

            --->l
            if @CORRESBANKADDRESS1 is not null and @CORRESBANKADDRESS1 <> ''
                set @CORRESBANKADDRESS1 = LEFT(@CORRESBANKADDRESS1, @CORRESBANKADDRESS1_LEN);
            else
                set @CORRESBANKADDRESS1 = isnull(@CORRESBANKADDRESS1,'');

            --->m
            if @CORRESBANKADDRESS2 is not null and @CORRESBANKADDRESS2 <> ''
                set @CORRESBANKADDRESS2 = LEFT(@CORRESBANKADDRESS2, @CORRESBANKADDRESS2_LEN);
            else
                set @CORRESBANKADDRESS2 = isnull(@CORRESBANKADDRESS2,'');

            --->n
            if @CORRESBANKADDRESS3 is not null and @CORRESBANKADDRESS3 <> ''
                set @CORRESBANKADDRESS3 = LEFT(@CORRESBANKADDRESS3, @CORRESBANKADDRESS3_LEN);
            else
                set @CORRESBANKADDRESS3 = isnull(@CORRESBANKADDRESS3,'');

            --->o
            if @CORRESBANKCOUNTRYCODE is not null and @CORRESBANKCOUNTRYCODE <> ''
                set @CORRESBANKCOUNTRYCODE = LEFT(@CORRESBANKCOUNTRYCODE, @CORRESBANKCOUNTRYCODE_LEN);
            else
                set @CORRESBANKCOUNTRYCODE = isnull(@CORRESBANKCOUNTRYCODE,'');

            --->p
                set @TXNAMOUNT = isnull(@TXNAMOUNT,0.00);

            --->q
                set @FXAMOUNT = isnull(@FXAMOUNT,0.00);

            --->r
                set @AMOUNTOFCLAIM = isnull(@AMOUNTOFCLAIM,0.00);

            --->s
                set @NoofShares = isnull(@NoofShares,0.00);

            --->t
                set @NetAssetValue = isnull(@NetAssetValue,0.00);

                if @ACCOUNTNUMBER is not null and @ACCOUNTNUMBER <> ''
                set @ACCOUNTNUMBER = LEFT(@ACCOUNTNUMBER, @ACCOUNTNUMBER_LEN);
            else
                set @ACCOUNTNUMBER = isnull(@ACCOUNTNUMBER,'');

            --print 'txnid:';
            --print @TXNID;
            --->8
            INSERT INTO AML_CTR1 (ID,BRANCHCODE,TXNAMOUNT,CURRENCY,FXAMOUNT,TXNID,EXPORTED,DETAILINDICATOR,TXNDATE,
                TXNTYPE,TXNREFNO,INCEPTIONDATE,MATUITYDATE,AMOUNTOFCLAIM,ACCOUNTNUMBER,ERROR,
                STATUS,DATE_ADDED,Exported_Date,FILENAME,Created_Date,customer_id,AccountBranchCode,StockRefNo,Nature_of_Transaction,
                --NoofShares,NetAssetValue,CORRESPONDENTBANKNAME,CORRESBANKADDRESS1,CORRESBANKADDRESS2,CORRESBANKADDRESS3,CORRESBANKCOUNTRYCODE)	Replaced by viShnu.K for # on 03Aug2K18
                NoofShares,NetAssetValue,CORRESPONDENTBANKNAME,CORRESBANKADDRESS1,CORRESBANKADDRESS2,CORRESBANKADDRESS3,CORRESBANKCOUNTRYCODE, TXN_DATE_IDX)
                
            VALUES (@id,@BRANCHCODE,@TXNAMOUNT,@CURRENCY,@FXAMOUNT,@TXNID,@EXPORTED,@DETAILINDICATOR,@TXNDATE,@TXNTYPE,@TXNREFNO,
                @INCEPTIONDATE,@MATUITYDATE,@AMOUNTOFCLAIM,@ACCOUNTNUMBER,'','',null,null,'',getdate(),'',
                @AccountBranchCode,@StockRefNo,dbo.replaceall(@Purpose),@NoofShares,@NetAssetValue,dbo.replaceall(@CORRESPONDENTBANKNAME),dbo.replaceall(@CORRESBANKADDRESS1),
                -- dbo.replaceall(@CORRESBANKADDRESS2),dbo.replaceall(@CORRESBANKADDRESS3),@CORRESBANKCOUNTRYCODE);		Replaced by viShnu.K for # on 03Aug2K18
                dbo.replaceall(@CORRESBANKADDRESS2),dbo.replaceall(@CORRESBANKADDRESS3),@CORRESBANKCOUNTRYCODE, @TXN_DATE_IDX);
                

            -- Start:55737 - Base60AML has to validate only the mandatory parties as per BSP Reporting Procedures

                if (@TXNTYPE <> @Mandatory_TXNType)
                begin

                    --print 'TXNTYPE:';
                    --print @TXNTYPE;
                    --print 'Mandatory_TXNType:';
                    --print @Mandatory_TXNType;
                    set @Mandatory_TXNType = @TXNTYPE;
                    set @AccountHolder_Data_Required = 0;
                    set @Beneficiary_Data_Required = 0;
                    set @CP_Data_Required = 0;
                    set @Issuer_Data_Required = 0;
                    set @OP_Data_Required = 0;
                    set @Transactor_Data_Required = 0;

                    declare dataSetCursor cursor for
                        SELECT DISTINCT f.DATASET_NAME FROM
                                AML_REGULATORY_REPORT_MANDATORY m, AML_FIELD f
                            WHERE f.FIELD_ID = m.FIELD_ID
                            AND f.DATASET_NAME NOT LIKE '%_Body'
                            AND f.DATASET_NAME NOT LIKE 'STR1_%'
                            AND m.REPORTING_TYPE = 'CTR'
                            AND m.TRAN_CODE = @Mandatory_TXNType;

                    open dataSetCursor;
                    fetch next from dataSetCursor into @Dataset_Name

                    while(@@FETCH_STATUS = 0)
                    begin

                            if @Dataset_Name is not null and @Dataset_Name <> ''
                            begin

                                if @Dataset_Name = 'CTR1_AccountHolder'
                                    set @AccountHolder_Data_Required = 1;
                                else if @Dataset_Name = 'CTR1_Beneficiary'
                                    set @Beneficiary_Data_Required = 1;
                                else if @Dataset_Name = 'CTR1_Counterparty'
                                    set @CP_Data_Required = 1;
                                else if @Dataset_Name = 'CTR1_OtherParticipant'
                                    set @OP_Data_Required = 1;
                                else if @Dataset_Name = 'CTR1_Transactor'
                                    set @Transactor_Data_Required = 1;
                                else if @Dataset_Name = 'CTR1_Issuer'
                                    set @Issuer_Data_Required = 1;
                            end
                        fetch next from dataSetCursor into @Dataset_Name
                    end

                    close dataSetCursor;
                    deallocate dataSetCursor;
                end;
            -- End:55737 - Base60AML has to validate only the mandatory parties as per BSP Reporting Procedures

            --->9
            if (@AccountHolder_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
            begin
                EXEC CTR_ACCOUNTHOLDER_CUSTOMERDETAILS_INSERT @ACCOUNTID,@id, @customerSelectQuery;
            end;
            --->10
            if ((@BENEFICIARYNAME1 is not null and @BENEFICIARYNAME1 <> '') or
                (@BENEFICIARYNAME2 is not null and @BENEFICIARYNAME2 <> '') or
                (@BENEFICIARYNAME3 is not null and @BENEFICIARYNAME3 <> '') or
                (@BENEFICIARYADDRESS1 is not null and @BENEFICIARYADDRESS1 <> '') or-- Start, #38922 - Beneficiary Details - Dinesh1
                (@BENEFICIARYADDRESS2 is not null and @BENEFICIARYADDRESS2 <> '') or
                (@BENEFICIARYADDRESS3 is not null and @BENEFICIARYADDRESS3 <> '') or
                (@BENEFICIARYCOUNTRY is not null and @BENEFICIARYCOUNTRY <> '') or
                (@BENEFICIARY_CUSTOMERREFNO is not null and @BENEFICIARY_CUSTOMERREFNO <> '') or
                (@BENEFICIARY_ACCOUNTNO is not null and @BENEFICIARY_ACCOUNTNO <> '') or
                (@BENEFICIARY_DATEOFBIRTH is not null and @BENEFICIARY_DATEOFBIRTH <> '') or
                (@BENEFICIARY_PLACEOFBIRTH is not null and @BENEFICIARY_PLACEOFBIRTH <> '') or
                (@BENEFICIARY_IDType is not null and @BENEFICIARY_IDType <> '') or
                (@BENEFICIARY_IDNo is not null and @BENEFICIARY_IDNo <> '') or
                (@BENEFICIARY_TelNo is not null and @BENEFICIARY_TelNo <> '') or
                (@BENEFICIARY_NatureofBusiness is not null and @BENEFICIARY_NatureofBusiness <> ''))-- End, #38922 - Beneficiary Details - Dinesh1
                begin
                --print 'bene start'
                    if (@Beneficiary_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
					
                    begin
					--------Added by Kirubalakshmi S  for inia #4443 ARRG 5 dots starts
		
					if @BENEFICIARY_NAME_FLAG = 'N'					
					begin
					DECLARE @base_nationality_name varchar(50);

					SELECT @base_nationality_name = NATIONALITY_NAME from AML_BASE_COUNTRY_CODE

					if((@BENEFICIARYCOUNTRY is not null) and (@BENEFICIARYCOUNTRY <> ''))
					begin
		
					if((@base_nationality_name <> @BENEFICIARYCOUNTRY))
					begin
    
					if ((@BENEFICIARYNAME1 is null or @BENEFICIARYNAME1 = '') and (@BENEFICIARYNAME3 is not null and @BENEFICIARYNAME3 <> ''))
					begin
	 
					set @BENEFICIARYNAME1 = '.....'
					end
	  
					if((@BENEFICIARYNAME3 is null or @BENEFICIARYNAME3 = '') and (@BENEFICIARYNAME1 is not null and @BENEFICIARYNAME1 <> ''))
					begin
	
					set @BENEFICIARYNAME3 = '.....'
					end
					end
					end
					end
					
					--------Added by Kirubalakshmi S  for inia #4443 ARRG 5 dots ends
                        EXEC CTR_OTHER_PARTIES_DETAILS_INSERT @bid,@id,'AML_CTR1_BENEFICIARY','B',@BENEFICIARYNAME1,@BENEFICIARYNAME2,@BENEFICIARYNAME3,
                                        @BENEFICIARYADDRESS1,@BENEFICIARYADDRESS2,@BENEFICIARYADDRESS3,@BENEFICIARYCOUNTRY,@BENEFICIARY_CUSTOMERREFNO,
                                        @BENEFICIARY_ACCOUNTNO,@BENEFICIARY_DATEOFBIRTH,@BENEFICIARY_PLACEOFBIRTH,@BENEFICIARY_IDType,@BENEFICIARY_IDNo,
                                        @BENEFICIARY_TelNo,@BENEFICIARY_NatureofBusiness,@BENEFICIARY_NAME_FLAG;
                        set @bid = @bid + 1;

                        /*start : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        set @multiPartiesExec = '';

                        select @multiPartiesExec = @multiPartiesExec
                        + ' exec CTR_OTHER_PARTIES_DETAILS_INSERT ' + convert(varchar, ROW_NUMBER() over(order by (select null)) + @bid) + ','
                        + convert(varchar, @id) + ','
                        + '''AML_CTR1_BENEFICIARY'', ''B'',''' + BENEFICIARYNAME1 + ''',''' + BENEFICIARYNAME2 + ''''
                        + ',''' + BENEFICIARYNAME3 + ''',''' + BENEFICIARYADDRESS1 + ''',''' + BENEFICIARYADDRESS2 + ''''
                        + ',''' + BENEFICIARYADDRESS3 + ''',''' + BENEFICIARYCOUNTRY + ''',''' + BENEFICIARY_CUSTOMERREFNO + ''''
                        + ',''' + BENEFICIARY_ACCOUNTNO + ''',''' + isnull(convert(varchar,BENEFICIARY_DATEOFBIRTH,110),'') + ''''
                        + ',''' + BENEFICIARY_PLACEOFBIRTH + ''',''' + BENEFICIARY_IDType + ''''
                        + ',''' + BENEFICIARY_IDNo + ''',''' + BENEFICIARY_TelNo + ''',''' + BENEFICIARY_NatureofBusiness + ''''
                        + ',''' + BENEFICIARY_NAME_FLAG + '''; '

                        from AML_TRANSACTION_BENEFICIARY where TXNID = @TXNID;

                        exec(@multiPartiesExec);
                        select @bid = ISNULL(MAX(ID),0)+1 from AML_CTR1_BENEFICIARY
                        /*end : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        --print 'bene end'
                    end;
                end;

            --->11
            -- AML_CTR1_SUSPICION insertion removed because of not required for CTR

            --->12
            if ((@CPNAME1 is not null and @CPNAME1 <> '') or
                (@CPNAME2 is not null and @CPNAME2 <> '') or
                (@CPNAME3 is not null and @CPNAME3 <> '') or

                --- Start, #38922 - Counter Party Details - Dinesh2

                (@CPADDRESS1 is not null and @CPADDRESS1 <> '') or
                (@CPADDRESS2 is not null and @CPADDRESS2 <> '') or
                (@CPADDRESS3 is not null and @CPADDRESS3 <> '') or
                (@COUNTERPARTY_CUSTOMERREFNO is not null and @COUNTERPARTY_CUSTOMERREFNO <> '') or
                (@COUNTERPARTY_ACCOUNTNO is not null and @COUNTERPARTY_ACCOUNTNO <> ''))

                --- End, #38922 - Counter Party Details - Dinesh2
                begin
                    --print 'cp start'
                    if (@CP_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
                    begin
                        EXEC CTR_OTHER_PARTIES_DETAILS_INSERT @cpid,@id,'AML_CTR1_COUNTERPARTY','C',@CPNAME1,@CPNAME2,@CPNAME3,@CPADDRESS1,@CPADDRESS2,
                                          @CPADDRESS3,null,@COUNTERPARTY_CUSTOMERREFNO,@COUNTERPARTY_ACCOUNTNO,null,null,null,null,null,null,@CP_NAME_FLAG;
                        set @cpid = @cpid + 1;

                        /*start : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        set @multiPartiesExec = '';

                        select @multiPartiesExec = @multiPartiesExec
                        + ' exec CTR_OTHER_PARTIES_DETAILS_INSERT ' + convert(varchar, ROW_NUMBER() over(order by (select null)) + @cpid) + ','
                        + convert(varchar,@id) + ','
                        + '''AML_CTR1_COUNTERPARTY'', ''C'',''' + CPNAME1 + ''',''' + CPNAME2 + ''''
                        + ',''' + CPNAME3 + ''',''' + CPADDRESS1 + ''',''' + CPADDRESS2 + ''''
                        + ',''' + CPADDRESS3 + ''',null,''' + CPCUSTOMERREFNO + ''''
                        + ',''' + cpaccountno + ''',null,null,null,null,null,null'
                        + ',''' + CP_NAME_FLAG + '''; '

                        from AML_TRANSACTION_COUNTERPARTY where TXNID = @TXNID;

                        exec(@multiPartiesExec);
                        select @cpid = ISNULL(MAX(ID),0)+1 from AML_CTR1_COUNTERPARTY
                        /*end : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        --print 'cp end'
                    end;
                end;
            --->13
            if ((@OP_NAME1 is not null and @OP_NAME1 <> '') or
                (@OP_NAME2 is not null and @OP_NAME2 <> '') or
                (@OP_NAME3 is not null and @OP_NAME3 <> '') or

                --- Start, #38922 - Other Participant Details - Dinesh3

                (@OP_ADDRESS1 is not null and @OP_ADDRESS1 <> '') or
                (@OP_ADDRESS2 is not null and @OP_ADDRESS2 <> '') or
                (@OP_ADDRESS3 is not null and @OP_ADDRESS3 <> '') or
                (@OP_CUSTOMERREFNO is not null and @OP_CUSTOMERREFNO <> '') or
                (@OPACCOUNTNO is not null and @OPACCOUNTNO <> ''))

                --- End, #38922 - Other Participant Details - Dinesh3
                begin
                    --print 'op start'
                    if (@OP_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
                    begin
                        EXEC CTR_OTHER_PARTIES_DETAILS_INSERT @opid,@id,'AML_CTR1_OTHERPARTICIPANT','P',@OP_NAME1,@OP_NAME2,@OP_NAME3,@OP_ADDRESS1,@OP_ADDRESS2,
                                          @OP_ADDRESS3,null,@OP_CUSTOMERREFNO,@OPACCOUNTNO,null,null,null,null,null,null,@OP_NAME_FLAG;
                        set @opid = @opid + 1;

                        /*start : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        set @multiPartiesExec = '';

                        select @multiPartiesExec = @multiPartiesExec
                        + ' exec CTR_OTHER_PARTIES_DETAILS_INSERT ' + convert(varchar, ROW_NUMBER() over(order by (select null)) + @opid) + ','
                        + convert(varchar,@id) + ','
                        + '''AML_CTR1_OTHERPARTICIPANT'', ''P'',''' + OP_NAME1 + ''',''' + OP_NAME2 + ''''
                        + ',''' + OP_NAME3 + ''',''' + OP_ADDRESS1 + ''',''' + OP_ADDRESS2 + ''''
                        + ',''' + OP_ADDRESS3 + ''',null,''' + OP_CUSTOMERREFNO + ''''
                        + ',''' + OPACCOUNTNO + ''',null,null,null,null,null,null'
                        + ',''' + OP_NAME_FLAG + '''; '

                        from AML_TRANSACTION_OP where TXNID = @TXNID;

                        exec(@multiPartiesExec);
                        select @opid = ISNULL(MAX(ID),0)+1 from AML_CTR1_OTHERPARTICIPANT
                        /*end : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        --print 'op end'
                    end;
                end;
            --->14
            if ((@ISSUER_NAME1 is not null and @ISSUER_NAME1 <> '') or
                (@ISSUER_NAME2 is not null and @ISSUER_NAME2 <> '') or
                (@ISSUER_NAME3 is not null and @ISSUER_NAME3 <> '') or

                --- Start, #38922 - Issuer Details - Dinesh4

                (@ISSUER_ADDRESS1 is not null and @ISSUER_ADDRESS1 <> '') or
                (@ISSUER_ADDRESS2 is not null and @ISSUER_ADDRESS2 <> '') or
                (@ISSUER_ADDRESS3 is not null and @ISSUER_ADDRESS3 <> '') or
                (@ISSUER_CUSTOMERREFNO is not null and @ISSUER_CUSTOMERREFNO <> '') or
                (@ISSUER_ACCOUNTNO is not null and @ISSUER_ACCOUNTNO <> ''))

                --- End, #38922 - Issuer Details - Dinesh4

                begin
                --print 'issuer start'
                    if (@Issuer_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
                    begin
                        EXEC CTR_OTHER_PARTIES_DETAILS_INSERT @iid,@id,'AML_CTR1_ISSUER','I',@ISSUER_NAME1,@ISSUER_NAME2,@ISSUER_NAME3,@ISSUER_ADDRESS1,@ISSUER_ADDRESS2,
                                          @ISSUER_ADDRESS3,null,@ISSUER_CUSTOMERREFNO,@ISSUER_ACCOUNTNO,null,null,null,null,null,null,@ISSUER_NAME_FLAG;
                        set @iid = @iid + 1;

                        /*start : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        set @multiPartiesExec = '';

                        select @multiPartiesExec = @multiPartiesExec
                        + ' exec CTR_OTHER_PARTIES_DETAILS_INSERT ' + convert(varchar, ROW_NUMBER() over(order by (select null)) + @opid) + ','
                        + convert(varchar, @id) + ','
                        + '''AML_CTR1_ISSUER'', ''I'',''' + ISSUER_NAME1 + ''',''' + ISSUER_NAME2 + ''''
                        + ',''' + ISSUER_NAME3 + ''',''' + ISSUER_ADDRESS1 + ''',''' + ISSUER_ADDRESS2 + ''''
                        + ',''' + ISSUER_ADDRESS3 + ''',null,''' + ISSUER_CUSTOMERREFNO + ''''
                        + ',''' + ISSUER_ACCOUNTNO + ''',null,null,null,null,null,null'
                        + ',''' + ISSUER_NAME_FLAG + '''; '

                        from AML_TRANSACTION_ISSUER where TXNID = @TXNID;

                        exec(@multiPartiesExec);
                        select @iid = ISNULL(MAX(ID),0)+1 from AML_CTR1_ISSUER
                        /*end : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        --print 'issuer end'
                    end;
                end;
            --->15
            if ((@TRANSACTOR_NAME1 is not null and @TRANSACTOR_NAME1 <> '') or
                (@TRANSACTOR_NAME2 is not null and @TRANSACTOR_NAME2 <> '') or
                (@TRANSACTOR_NAME3 is not null and @TRANSACTOR_NAME3 <> '') or

                --- Start, #38922 - Transactor Details - Dinesh5

                (@TRANSACTOR_ADDRESS1 is not null and @TRANSACTOR_ADDRESS1 <> '') or
                (@TRANSACTOR_ADDRESS2 is not null and @TRANSACTOR_ADDRESS2 <> '') or
                (@TRANSACTOR_ADDRESS3 is not null and @TRANSACTOR_ADDRESS3 <> '') or
                (@TRANSACTOR_CUSTOMERREFNO is not null and @TRANSACTOR_CUSTOMERREFNO <> '') or
                (@TRANSACTOR_ACCOUNTNO is not null and @TRANSACTOR_ACCOUNTNO <> ''))

                --- End, #38922 - Transactor Details - Dinesh5

                begin
                    --print 'trans start'
                    if (@Transactor_Data_Required = 1 or @NotRequired_NonMandatoryParties_Data = 0)
                    begin
                        EXEC CTR_OTHER_PARTIES_DETAILS_INSERT @tid,@id,'AML_CTR1_TRANSACTOR','T',@TRANSACTOR_NAME1,@TRANSACTOR_NAME2,@TRANSACTOR_NAME3,@TRANSACTOR_ADDRESS1,@TRANSACTOR_ADDRESS2,
                                          @TRANSACTOR_ADDRESS3,null,@TRANSACTOR_CUSTOMERREFNO,@TRANSACTOR_ACCOUNTNO,null,null,null,null,null,null,@TRANSACTOR_NAME_FLAG;
                        set @tid = @tid + 1;

                        /*start : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        set @multiPartiesExec = '';

                        select @multiPartiesExec = @multiPartiesExec
                        + ' exec CTR_OTHER_PARTIES_DETAILS_INSERT ' + convert(varchar, ROW_NUMBER() over(order by (select null)) + @opid) + ','
                        + convert(varchar, @id) + ','
                        + '''AML_CTR1_TRANSACTOR'', ''T'',''' + TRANSACTOR_NAME1 + ''',''' + TRANSACTOR_NAME2 + ''''
                        + ',''' + TRANSACTOR_NAME3 + ''',''' + TRANSACTOR_ADDRESS1 + ''',''' + TRANSACTOR_ADDRESS2 + ''''
                        + ',''' + TRANSACTOR_ADDRESS3 + ''',null,''' + TRANSACTOR_CUSTOMERREFNO + ''''
                        + ',''' + TRANSACTOR_ACCOUNTNO + ''',null,null,null,null,null,null'
                        + ',''' + TRANSACTOR_NAME_FLAG + '''; '

                        from AML_TRANSACTION_TRANSACTOR where TXNID = @TXNID;

                        exec(@multiPartiesExec);
                        select @tid = ISNULL(MAX(ID),0)+1 from AML_CTR1_TRANSACTOR
                        /*end : iNiA #96954 multiple parties -vinothkumar.c 27-Jan-2016*/
                        --print 'trans end'
                    end;
                end;

            fetch next from txnCursor into @TXNID,@TXNDATE,@TXNREFNO,@TXNTYPE,@TXNAMOUNT,@BRANCHCODE,@CURRENCY,@PURPOSE,@CPNAME1,@CPNAME2,@CPNAME3,@CPADDRESS1,
                        @CPADDRESS2,@CPADDRESS3,@CORRESPONDENTBANKNAME,@CORRESBANKCOUNTRYCODE,@CORRESBANKADDRESS1,@CORRESBANKADDRESS2,
                        @CORRESBANKADDRESS3,@INCEPTIONDATE,@MATUITYDATE,@FXAMOUNT,@BENEFICIARYNAME1,@BENEFICIARYNAME2,@BENEFICIARYNAME3,
                        @BENEFICIARYADDRESS1,@BENEFICIARYADDRESS2,@BENEFICIARYADDRESS3,@ACCOUNTID,@OPACCOUNTNO,@BENEFICIARYCOUNTRY,
                        @STOCKREFNO,@AMOUNTOFCLAIM,@NOOFSHARES,@NETASSETVALUE,@BENEFICIARY_CUSTOMERREFNO,@BENEFICIARY_ACCOUNTNO,
                        @BENEFICIARY_DATEOFBIRTH,@BENEFICIARY_PLACEOFBIRTH,@BENEFICIARY_IDType,@BENEFICIARY_IDNo,@BENEFICIARY_TelNo,
                        @BENEFICIARY_NatureofBusiness,
                        @TRANSACTOR_CUSTOMERREFNO,@TRANSACTOR_NAME1,@TRANSACTOR_NAME2,@TRANSACTOR_NAME3,@TRANSACTOR_ADDRESS1,@TRANSACTOR_ADDRESS2,
                        @TRANSACTOR_ADDRESS3,@TRANSACTOR_ACCOUNTNO,@COUNTERPARTY_CUSTOMERREFNO,@COUNTERPARTY_ACCOUNTNO,@OP_CUSTOMERREFNO,
                        @OP_NAME1,@OP_NAME2,@OP_NAME3,@OP_ADDRESS1,@OP_ADDRESS2,@OP_ADDRESS3,@ISSUER_CUSTOMERREFNO,@ISSUER_NAME1,@ISSUER_NAME2,
                        @ISSUER_NAME3,@ISSUER_ADDRESS1,@ISSUER_ADDRESS2,@ISSUER_ADDRESS3,@ISSUER_ACCOUNTNO,@ACCOUNTNUMBER,@AccountBranchCode,
                        --@BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG  Replaced by viShnu.K for # on 03Aug2K18
                        @BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG, @TXN_DATE_IDX

        if(@Deferred_TXN_Reporting_Enable = 1)
        Begin
            Insert into TEMP_ID values(@id);
        End;

            set @id = @id + 1;

        END TRY
        BEGIN CATCH

            declare @errorMessage varchar(max);
            set @errorMessage = '';

            if (ERROR_NUMBER() = 8134)
            begin
                set @errorMessage = 'Transaction branch code is missing';
            end
            else
            begin
                if (CHARINDEX('String or binary data', ERROR_MESSAGE()) > 0)
                begin
                    set @errorMessage = 'Data length of some field is too large.';
                end
                else
                    -- Added By Ramakrishnan M ON 02-Jun-2015 iNia id #73343
                    begin
                        if (CHARINDEX('with unique index '+CHAR(39)+'IDX_UNIQUE_CTR1_TXNREFNO'+char(39), ERROR_MESSAGE()) > 0)
                        begin
                            set @errorMessage = 'Duplicate Trans.Reference Number for the same TxnDate.';
                        end

                        else
                        begin
                            set @errorMessage = ERROR_MESSAGE();
                        end
                    end
                    -- Ends #73343
            end

            insert into AML_CTR1_GENERATE_ERROR_LOG(ERR_TXNID, GENERATED_DATE, ERR_REMARKS)
            values (@TXNID, GETDATE(), @errorMessage);

            delete from AML_CTR1_ACCOUNTHOLDER where CTR_ID = @id
            delete from AML_CTR1_BENEFICIARY where CTR_ID = @id
            delete from AML_CTR1_COUNTERPARTY where CTR_ID = @id
            delete from AML_CTR1_ISSUER where CTR_ID = @id
            delete from AML_CTR1_OTHERPARTICIPANT where CTR_ID = @id
            delete from AML_CTR1_TRANSACTOR where CTR_ID = @id
            delete from AML_CTR1 where id = @id;

            fetch next from txnCursor into @TXNID,@TXNDATE,@TXNREFNO,@TXNTYPE,@TXNAMOUNT,@BRANCHCODE,@CURRENCY,@PURPOSE,@CPNAME1,@CPNAME2,@CPNAME3,@CPADDRESS1,
                        @CPADDRESS2,@CPADDRESS3,@CORRESPONDENTBANKNAME,@CORRESBANKCOUNTRYCODE,@CORRESBANKADDRESS1,@CORRESBANKADDRESS2,
                        @CORRESBANKADDRESS3,@INCEPTIONDATE,@MATUITYDATE,@FXAMOUNT,@BENEFICIARYNAME1,@BENEFICIARYNAME2,@BENEFICIARYNAME3,
                        @BENEFICIARYADDRESS1,@BENEFICIARYADDRESS2,@BENEFICIARYADDRESS3,@ACCOUNTID,@OPACCOUNTNO,@BENEFICIARYCOUNTRY,
                        @STOCKREFNO,@AMOUNTOFCLAIM,@NOOFSHARES,@NETASSETVALUE,@BENEFICIARY_CUSTOMERREFNO,@BENEFICIARY_ACCOUNTNO,
                        @BENEFICIARY_DATEOFBIRTH,@BENEFICIARY_PLACEOFBIRTH,@BENEFICIARY_IDType,@BENEFICIARY_IDNo,@BENEFICIARY_TelNo,
                        @BENEFICIARY_NatureofBusiness,
                        @TRANSACTOR_CUSTOMERREFNO,@TRANSACTOR_NAME1,@TRANSACTOR_NAME2,@TRANSACTOR_NAME3,@TRANSACTOR_ADDRESS1,@TRANSACTOR_ADDRESS2,
                        @TRANSACTOR_ADDRESS3,@TRANSACTOR_ACCOUNTNO,@COUNTERPARTY_CUSTOMERREFNO,@COUNTERPARTY_ACCOUNTNO,@OP_CUSTOMERREFNO,
                        @OP_NAME1,@OP_NAME2,@OP_NAME3,@OP_ADDRESS1,@OP_ADDRESS2,@OP_ADDRESS3,@ISSUER_CUSTOMERREFNO,@ISSUER_NAME1,@ISSUER_NAME2,
                        @ISSUER_NAME3,@ISSUER_ADDRESS1,@ISSUER_ADDRESS2,@ISSUER_ADDRESS3,@ISSUER_ACCOUNTNO,@ACCOUNTNUMBER,@AccountBranchCode,
                        --@BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG  Replaced by viShnu.K for # on 03Aug2K18
                        @BENEFICIARY_NAME_FLAG, @CP_NAME_FLAG, @OP_NAME_FLAG, @ISSUER_NAME_FLAG, @TRANSACTOR_NAME_FLAG, @TXN_DATE_IDX
                        
        END CATCH
    end

    close txnCursor;
    deallocate txnCursor;

    --->calling validation proc
    EXEC CTR_VALIDATION;

    --->calling Deferred_TXN proc
    if(@Deferred_TXN_Reporting_Enable = 1)
    Begin
        EXEC AML_DEFERRED_TXN;
    End;
    --->
    select @flag = COUNT(name) from sys.tables where name = 'temp_ctr1'

    if @flag > 0
        Drop table temp_ctr1;

    if exists(select 1 from sys.tables where name = 'TEMP_ID')
        Drop table TEMP_ID;

    COMMIT TRAN;
    END TRY
    BEGIN CATCH

        close txnCursor;
        deallocate txnCursor;

        select @flag = COUNT(name) from sys.tables where name = 'temp_ctr1'

        if @flag > 0
            Drop table temp_ctr1;

        if exists(select 1 from sys.tables where name = 'TEMP_ID')
            Drop table TEMP_ID;

        ROLLBACK TRAN;
        --For Error Log
        if exists(select AUDIT_TYPE from AML_AUDITCONTROL where AUDIT_TYPE = 'ctr1.generation.error' and ACTIVE = 1)
        begin
            insert into AML_ERRORLOG(TYPE, TIME, ACTOR, ENTITY, ENTITY_ID, INFO, INFO_TYPE, LEVEL, ERROR_KEY)
            values('CTR1 Generation failure', GETDATE(), 'System', 'CTR1 Generation failure' , 'CTR1', Error_message(),
            'com.objectfrontier.aml.scenario.manager.CTR1ScenarioRunTask$AuditableClass', 'major', 'CTR1_GENERATION_FAIL');
        end
        --For Error Log
        PRINT Error_message();
    END CATCH

END
