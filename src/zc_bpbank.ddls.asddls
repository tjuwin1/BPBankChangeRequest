@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'BP Bank Change Requests'

@Metadata.allowExtensions: true

define root view entity zc_bpbank
  provider contract transactional_query
  as projection on zi_bpbank

{
      @ObjectModel.text.element: [ 'BPName' ]
  key businesspartner,

      @EndUserText.label: 'Request ID'
  key reqid,

      bankid,

      @ObjectModel.text.element: [ 'cntryDesc' ]
      bankcountrykey,

      @ObjectModel.text.element: [ 'BankName' ]
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

      @ObjectModel.text.element: [ 'ocntryDesc' ]
      obankcountrykey,

      @ObjectModel.text.element: [ 'oBankName' ]
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

      @ObjectModel.text.element: [ 'statDesc' ]
      status,

      @ObjectModel.text.element: [ 'reqDesc' ]
      requestedby,

      @ObjectModel.text.element: [ 'ap1Desc' ]
      //Not used in current version
      @UI.hidden: true
      @Consumption.hidden: true
      approval1,

      @ObjectModel.text.element: [ 'ap2Desc' ]
      approval2,

      @Semantics.largeObject: { mimeType: 'mimetype',
                                fileName: 'filename',
                                contentDispositionPreference: #ATTACHMENT,
                                acceptableMimeTypes: [ 'application/pdf', 'image/png', 'image/jpeg', 'text/plain' ] }
      attachment,

      @Semantics.mimeType: true
      mimetype,

      filename,

      @ObjectModel.text.element: [ 'crtDesc' ]
      local_created_by,

      local_created_at,

      @ObjectModel.text.element: [ 'chgDesc' ]
      local_last_changed_by,

      local_last_changed_at,
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

      @EndUserText.label: 'Attachment'
      documentlink,

      @UI.hidden: true
      NoLink,

      @EndUserText.label: 'Comments'
      comments,

      //Not used in current version
      @UI.hidden: true
      @Consumption.hidden: true
      _ap1.UserDescription            as ap1Desc,
      _ap2.UserDescription            as ap2Desc,
      _Bank.BankName                  as BankName,
      _bp.BusinessPartnerFullName     as BPName,
      _chg.UserDescription            as chgDesc,
      _cntry.Description              as cntryDesc,
      _crt.UserDescription            as crtDesc,
      _req.UserDescription            as reqDesc,
      _stat.text                      as statDesc,
      _ocntry.Description             as ocntryDesc,
      _oBank.BankName                 as oBankName
}
