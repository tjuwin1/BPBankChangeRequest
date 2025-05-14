@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP Bank Change Requests'

@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

define root view entity zP_BPBank
  as select from    zst_bpbank            as b

    left outer join I_BusinessPartnerBank as t
      on  b.businesspartner = t.BusinessPartner
      and b.bankid          = t.BankIdentification

{
  key b.businesspartner,
  key b.reqid,

      b.bankid,

      b.bankcountrykey,
      b.banknumber,
      b.bankcontrolkey,
      b.bankaccountholdername,
      b.bankaccountname,
      b.bankvaliditystartdate,
      b.bankvalidityenddate,
      b.iban,
      b.bankaccount,
      b.bankaccountreferencetext,
      b.collectionauthind,
      b.businesspartnerexternalbankid,

      b.obankcountrykey,
      b.obanknumber,
      b.obankcontrolkey,
      b.obankaccountholdername,
      b.obankaccountname,
      b.obankvaliditystartdate,
      b.obankvalidityenddate,
      b.oiban,
      b.obankaccount,
      b.obankaccountreferencetext,
      b.ocollectionauthind,
      b.obusinesspartnerexternalbankid,

      b.status,
      b.requestedby,
      b.approval1,
      b.approval2,

      @Semantics.largeObject: { mimeType: 'mimetype', fileName: 'filename', contentDispositionPreference: #ATTACHMENT }
      b.attachment,

      @Semantics.mimeType: true
      b.mimetype,

      b.filename,

      @Semantics.user.createdBy: true
      b.local_created_by,

      @Semantics.systemDateTime.createdAt: true
      b.local_created_at,

      @Semantics.user.lastChangedBy: true
      b.local_last_changed_by,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      b.local_last_changed_at,

      @Semantics.systemDateTime.lastChangedAt: true
      b.last_changed_at,

      @UI.hidden: true
      case when t.BusinessPartner is null then 'X' else ' ' end as NoHistory,

      @UI.hidden: true
      ' '                                                       as NoApprovals,

      @UI.hidden: true
      ' '                                                       as NoComments,

      @UI.hidden: true
      ' '                                                       as NoLog,

      @UI.hidden: true
      case when b.status = 'C' then 'X' else ' ' end            as HideAttachs,

      @EndUserText.label: 'Comments'
      b.comments,

      b.documentlink
}

union all
  select from        zst_bpbank     as b

    right outer join zI_BPBank_Info as t
      on  b.businesspartner = t.BusinessPartner
      and b.bankid          = t.BankIdentification

{
  key t.BusinessPartner,
  key t.BankIdentification             as reqid,

      t.BankIdentification             as bankid,

      t.BankCountryKey,
      t.BankNumber,
      t.BankControlKey,
      t.BankAccountHolderName,
      t.BankAccountName,
      t.bankvaliditystartdate,
      t.bankvalidityenddate,
      t.IBAN,
      t.BankAccount,
      t.BankAccountReferenceText,
      t.CollectionAuthInd,
      t.BusinessPartnerExternalBankID,

      t.BankCountryKey                 as oBankCountryKey,
      t.BankNumber                     as oBankNumber,
      t.BankControlKey                 as oBankControlKey,
      t.BankAccountHolderName          as oBankAccountHolderName,
      t.BankAccountName                as oBankAccountName,
      t.bankvaliditystartdate          as obankvaliditystartdate,
      t.bankvalidityenddate            as obankvalidityenddate,
      t.IBAN                           as oIBAN,
      t.BankAccount                    as oBankAccount,
      t.BankAccountReferenceText       as oBankAccountReferenceText,
      t.CollectionAuthInd              as oCollectionAuthInd,
      t.BusinessPartnerExternalBankID  as oBusinessPartnerExternalBankID,

      'O'                              as status,
      ' '                              as requestedby,
      ' '                              as approval1,
      ' '                              as approval2,
      b.attachment,
      ''                               as mimetype,
      ''                               as filename,

      ' '                              as local_created_by,
      t.BPBankDetailsChangeDate        as local_created_at,
      ' '                              as local_last_changed_by,
      t.BPBankDetailsChangeDate        as local_last_changed_at,
      t.BPBankDetailsChangeDate        as last_changed_at,

      'X'                              as NoHistory,
      'X'                              as NoApprovals,
      'X'                              as NoComments,
      'X'                              as NoLog,
      'X'                              as HideAttachs,
      b.comments,

      b.documentlink
}

where b.businesspartner is null
