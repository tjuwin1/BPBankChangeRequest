@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'BP Bank Change Requests'

@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

define root view entity zi_bpbank
  as select from zP_BPBank

  association [0..1] to I_BusinessPartner    as _bp
    on $projection.businesspartner = _bp.BusinessPartner

  association [0..1] to zI_BPBank_Req_Status as _stat
    on $projection.status = _stat.Value

  association [0..1] to zI_User              as _req
    on $projection.requestedby = _req.UserID

  association [0..1] to zI_User              as _ap1
    on $projection.approval1 = _ap1.UserID

  association [0..1] to zI_User              as _ap2
    on $projection.approval2 = _ap2.UserID

  association [0..1] to zI_User              as _crt
    on $projection.local_created_by = _crt.UserID

  association [0..1] to zI_User              as _chg
    on $projection.local_last_changed_by = _chg.UserID

  association [1..1] to I_CountryVH          as _cntry
    on $projection.bankcountrykey = _cntry.Country

  association [1..1] to I_BankVH             as _Bank
    on  $projection.banknumber     = _Bank.BankInternalID
    and $projection.bankcountrykey = _Bank.BankCountry

  association [1..1] to I_CountryVH          as _ocntry
    on $projection.obankcountrykey = _ocntry.Country

  association [1..1] to I_BankVH             as _oBank
    on  $projection.obanknumber     = _oBank.BankInternalID
    and $projection.obankcountrykey = _oBank.BankCountry

{
      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'I_BusinessPartner', element: 'BusinessPartner' } } ]
  key businesspartner,

  key reqid,

      bankid,

      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'I_CountryVH', element: 'Country' } } ]
      bankcountrykey,

      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'I_BankVH', element: 'BankInternalID' },
                                            additionalBinding: [ { element: 'BankCountry',
                                                                   localElement: 'bankcountrykey',
                                                                   usage: #FILTER_AND_RESULT } ] } ]
      banknumber,

      bankcontrolkey,
      bankaccountholdername,
      bankaccountname,
      bankvaliditystartdate,
      bankvalidityenddate,
      iban,
      bankaccount,
      bankaccountreferencetext,
      collectionauthind,
      businesspartnerexternalbankid,

      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'I_CountryVH', element: 'Country' } } ]
      obankcountrykey,

      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'I_BankVH', element: 'BankInternalID' },
                                            additionalBinding: [ { element: 'BankCountry',
                                                                   localElement: 'obankcountrykey',
                                                                   usage: #FILTER_AND_RESULT } ] } ]
      obanknumber,

      obankcontrolkey,
      obankaccountholdername,
      obankaccountname,
      obankvaliditystartdate,
      obankvalidityenddate,
      oiban,
      obankaccount,
      obankaccountreferencetext,
      ocollectionauthind,
      obusinesspartnerexternalbankid,

      @Consumption.valueHelpDefinition: [ { useForValidation: true,
                                            entity: { name: 'zI_BPBank_Req_Status', element: 'Value' } } ]
      status,

      requestedby,

      approval1,

      approval2,

      @Semantics.largeObject: { mimeType: 'mimetype', fileName: 'filename', contentDispositionPreference: #ATTACHMENT }
      attachment,

      @Semantics.mimeType: true
      mimetype,

      filename,

      @Semantics.user.createdBy: true
      local_created_by,

      @Semantics.systemDateTime.createdAt: true
      local_created_at,

      @Semantics.user.lastChangedBy: true
      local_last_changed_by,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at,

      @UI.hidden: true
      NoHistory,

      @UI.hidden: true
      NoApprovals,

      @UI.hidden: true
      NoComments,

      @UI.hidden: true
      NoLog,

      @UI.hidden: true
      HideAttachs,

      @EndUserText.label: 'Comments'
      comments,
      
      @EndUserText.label: 'Attachment'
      documentlink,
      
      @UI.hidden: true
      case when documentlink is initial or documentlink is null then 'X' else ' ' end as NoLink,

      _bp,
      _stat,
      _req,
      _ap1,
      _ap2,
      _crt,
      _chg,
      _Bank,
      _cntry,
      _oBank,
      _ocntry
}
