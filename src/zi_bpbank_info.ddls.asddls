@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP Existing Bank Details'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity zI_BPBank_Info
  as select from I_BusinessPartnerBank

{
  key BusinessPartner,
  key BankIdentification,

      BankCountryKey,
      BankName,
      BankNumber,
      SWIFTCode,
      BankControlKey,
      BankAccountHolderName,
      BankAccountName,
      tstmp_to_dats(ValidityStartDate, 'UTC', $session.client, 'INITIAL') as bankvaliditystartdate,
      tstmp_to_dats(ValidityEndDate, 'UTC', $session.client, 'INITIAL')   as bankvalidityenddate,
      IsActualDate,
      BPIsActualDate,
      IBAN,
      BankAccount,
      BankAccountReferenceText,
      CollectionAuthInd,
      BusinessPartnerExternalBankID,
      BPBankDetailsChangeDate
}
