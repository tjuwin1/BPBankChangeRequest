@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'User List'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity zI_User
  as select from I_User

{
      @EndUserText.label: 'User'
      @ObjectModel.text.element: [ 'UserDescription' ]
  key UserID,

      @Semantics.text: true
      UserDescription
}
