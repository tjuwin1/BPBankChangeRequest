@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Country List for Responsibility'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity zi_country
  as select from I_CountryVH

{
      @ObjectModel.text.element: [ 'Description' ]
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    @Search.ranking: #HIGH
  key Country,

      Description
}
