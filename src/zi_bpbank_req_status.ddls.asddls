@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@ObjectModel.dataCategory: #VALUE_HELP
@EndUserText.label: 'Request Status'
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@ObjectModel.resultSet.sizeCategory: #XS
define view entity zI_BPBank_Req_Status
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T(
                   p_domain_name : 'ZDO_BNK_STAT')

{
      @EndUserText.label: 'Status'
      @ObjectModel.text.element: [ 'text' ]
  key value_low as Value,

      @EndUserText.label: 'Description'
      text
}

where language = $session.system_language
