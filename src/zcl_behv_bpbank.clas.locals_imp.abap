constants newrequest   type string value 'N'.
constants submitted type string value 'S'.
constants apprlv1   type string value 'L'.
constants apprlv2   type string value 'M'.
constants complete type string value 'C'.
constants existing type string value 'O'.
constants rejected type string value 'R'.
constants discarded type string value 'D'.
constants letters type c length 26 value 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
constants numbers type c length 10 value '1234567890'.

class lcl_singleton definition.
  public section.
    class-data emailer type ref to zcl_bpbank_approver_buffer.
    class-methods class_constructor.
endclass.

class lcl_singleton implementation.
  method class_constructor.
    emailer = new #( ).
  endmethod.
endclass.

class lcl_iban_validation definition.
  public section.
    methods mod97_check importing value(iv_iban)  type iban
                        returning value(rv_subrc) type i.

  protected section.
  private section.
    types ty_numc2 type n length 2.
    types ty_bban  type c length 60.

    methods alpha_to_num importing value(iv_alpha) type c
                         returning value(rv_num)   type ty_numc2.

    methods converse_letters changing  value(cv_string) type ty_bban
                             returning value(rv_subrc)  type i.
endclass.



class lcl_iban_validation implementation.
  method mod97_check.
    data lv_bban   type ty_bban.
    data lv_string type string.
    data lv_digit  type ty_numc2.

    check iv_iban is not initial.
    rv_subrc = 8.

    try.
        lv_string = condense( val  = iv_iban
                              from = ` `
                              to   = `` ).
        shift lv_string left by 4 places circular.
        lv_bban = lv_string.

        if converse_letters( changing cv_string = lv_bban ) is initial.
          lv_digit = lv_bban mod 97.
          if lv_digit = 1.
            clear rv_subrc.
          endif.
        endif.
      catch cx_root.
    endtry.
  endmethod.

  method converse_letters.
    data lv_string type c length 100.
    data lv_char   type c length 1.

    rv_subrc = 8.
    while cv_string is not initial.
      lv_char = cv_string(1).
      if lv_char co letters.
        lv_string = lv_string && alpha_to_num( lv_char ).
      elseif lv_char co numbers.
        lv_string = lv_string && lv_char.
      else.
        return.
      endif.
      shift cv_string.
    endwhile.

    cv_string = lv_string.
    clear rv_subrc.
  endmethod.

  method alpha_to_num.
    data lv_off type i.

    find iv_alpha in letters match offset lv_off.
    rv_num = lv_off + 10.
  endmethod.
endclass.

class lsc_zi_bpbank definition inheriting from cl_abap_behavior_saver.
  public section.

  protected section.
    methods save_modified redefinition.

endclass.


class lsc_zi_bpbank implementation.
  method save_modified.
    data lt_crt  type standard table of zst_bpbank.
    data lo_strc type ref to cl_abap_structdescr.

    lo_strc ?= cl_abap_structdescr=>describe_by_name( 'ZI_BPBANK' ).

    loop at create-zi_bpbank into data(ls_crt).
      if ls_crt-attachment is initial or ls_crt-mimetype is initial.
        clear: ls_crt-attachment,
               ls_crt-mimetype.
      endif.
      append corresponding #( ls_crt ) to lt_crt.
    endloop.

    if update-zi_bpbank is not initial.
      select bnk~* from zi_bpbank with privileged access as bnk
             join @update-zi_bpbank as upd
               on  bnk~businesspartner = upd~businesspartner
               and bnk~reqid           = upd~reqid
             into table @data(lt_exist).
      loop at update-zi_bpbank into data(ls_upd).
        read table lt_exist into data(ls_ext) with key businesspartner = ls_upd-businesspartner
                                                       reqid           = ls_upd-reqid.
        if sy-subrc = 0.
          loop at lo_strc->components into data(ls_comp).
            assign component ls_comp-name of structure ls_upd-%control to field-symbol(<ctrl>).
            if sy-subrc = 0.
              if <ctrl> is initial.
                assign component ls_comp-name of structure ls_upd to field-symbol(<upd>).
                if sy-subrc = 0.
                  assign component ls_comp-name of structure ls_ext to field-symbol(<ext>).
                  if sy-subrc = 0.
                    <upd> = <ext>.
                  endif.
                endif.
              endif.
            endif.
          endloop.
        endif.
        if ls_upd-attachment is initial or ls_upd-mimetype is initial.
          clear: ls_upd-attachment,
                 ls_upd-mimetype.
        endif.
        append corresponding #( ls_upd ) to lt_crt.
      endloop.
    endif.

    if lt_crt is not initial.
      modify zst_bpbank from table @lt_crt.
    endif.

    if delete-zi_bpbank is not initial.
      lt_crt = corresponding #( delete-zi_bpbank ).
      delete zst_bpbank from table @lt_crt.
    endif.

    if lcl_singleton=>emailer->for_approver is not initial or lcl_singleton=>emailer->for_requestor is not initial.
      if lcl_singleton=>emailer->lo_badi is bound.
        try.
            data lo_process type ref to if_bgmc_process_single_op.
            lo_process = cl_bgmc_process_factory=>get_default( )->create( ).
            lo_process->set_name( 'BANK_CHANGE_APPROVAL' )->set_operation_tx_uncontrolled( lcl_singleton=>emailer ).
            lo_process->save_for_execution( ).
          catch cx_root.
        endtry.
      endif.
    endif.
  endmethod.
endclass.


class lhc_zi_bpbank definition inheriting from cl_abap_behavior_handler.
  private section.
    types tykeys type table for key of zi_bpbank.

    methods get_instance_features for instance features
      importing keys request requested_features for zi_bpbank result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for zi_bpbank result result.

    methods approve1 for modify
      importing keys for action zi_bpbank~approve1.

    methods approve2 for modify
      importing keys for action zi_bpbank~approve2.

    methods submit for modify
      importing keys for action zi_bpbank~submit.
    methods copyto for modify
      importing keys for action zi_bpbank~copyto.
    methods getdefaultsforcreate for read
      importing keys for function zi_bpbank~getdefaultsforcreate result result.
    methods statusupdateonedit for determine on modify
      importing keys for zi_bpbank~statusupdateonedit.
    methods comment for modify
      importing keys for action zi_bpbank~comment.
    methods reject for modify
      importing keys for action zi_bpbank~reject.
    methods checkmandatory for validate on save
      importing keys for zi_bpbank~checkmandatory.
    methods datecheck for validate on save
      importing keys for zi_bpbank~datecheck.
    methods ibancheck for validate on save
      importing keys for zi_bpbank~ibancheck.
    methods earlynumbering_create for numbering
      importing entities for create zi_bpbank.
    methods get_next_number changing cv_number type clike.
    methods move_attachment importing value(iv_bp)          type clike
                                      value(iv_filename)    type if_attachment_service_api=>ts_attachment-filename
                                      value(iv_mimetype)    type if_attachment_service_api=>ty_s_media_resource-mime_type
                                      value(iv_filecontent) type if_attachment_service_api=>ty_s_media_resource-value
                            returning value(rv_attachment)  type zst_bpbank-documentlink.

    methods build_comment importing value(im_title) type clike
                                    value(im_new)   type clike optional
                                    value(im_old)   type clike optional
                          returning value(rv_str)   type string.
endclass.


class lhc_zi_bpbank implementation.
  method get_instance_features.
    data(lv_noapproval) = abap_true.
    data(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    select b~businesspartner,
           b~reqid,
           b~bankid,
           b~status,
           b~requestedby,
           b~approval1,
           b~approval2,
           b~bankcountrykey,
           case when     bankcountrykey                = obankcountrykey
                     and banknumber                    = obanknumber
                     and bankcontrolkey                = obankcontrolkey
                     and bankaccountholdername         = obankaccountholdername
                     and bankaccountname               = obankaccountname
                     and bankvaliditystartdate         = obankvaliditystartdate
                     and bankvalidityenddate           = obankvalidityenddate
                     and bankaccount                   = obankaccount
                     and bankaccountreferencetext      = obankaccountreferencetext
                     and collectionauthind             = ocollectionauthind
                     and businesspartnerexternalbankid = obusinesspartnerexternalbankid
                     and iban = oiban
                       then @abap_true end                                              as         nochanges
      from zi_bpbank with privileged access as b
      join @keys as k
      on  b~businesspartner = k~businesspartner
      and b~reqid           = k~reqid
      into table @data(lt_stats).
    if lt_stats is not initial.
      select b~businesspartner,
             b~reqid,
             b~bankid
        from zi_bpbank with privileged access as b
        join @lt_stats as k
        on  b~businesspartner  = k~BusinessPartner
        and b~bankid           = k~BankId
        and b~reqid           <> k~reqid
        where b~status <> @complete
          and b~status <> @discarded
        into table @data(lt_open).
    endif.

    loop at keys into data(ls_key).
      append initial line to result reference into data(lo_res).
      lo_res->%tky = ls_key-%tky.

      lo_res->%action-approve1 = if_abap_behv=>fc-o-disabled.
      lo_res->%action-approve2 = if_abap_behv=>fc-o-disabled.
      lo_res->%action-copyto   = if_abap_behv=>fc-o-disabled.
      lo_res->%action-reject   = if_abap_behv=>fc-o-disabled.
      lo_res->%action-submit   = if_abap_behv=>fc-o-disabled.
      lo_res->%action-comment  = if_abap_behv=>fc-o-disabled.
      lo_res->%delete = if_abap_behv=>fc-o-disabled.
      lo_res->%update = if_abap_behv=>fc-o-disabled.
      lo_res->%field-attachment = if_abap_behv=>fc-f-read_only.

      read table lt_stats into data(ls_stats) with key businesspartner = ls_key-businesspartner
                                                       reqid           = ls_key-reqid.
      if sy-subrc = 0 and ls_stats-bankid is not initial.
        read table lt_open into data(ls_open) with key BusinessPartner = ls_key-businesspartner
                                                       BankId          = ls_stats-bankid.
      endif.
      authority-check object 'F_BNKA_MAO'
                      id 'BANKS' field ls_stats-bankcountrykey
                      id 'ACTVT' field '02'.
      if sy-subrc = 0 and ls_stats-bankcountrykey is not initial.
        clear lv_noapproval.
      endif.

      case ls_stats-status.
        when newrequest or rejected.
          lo_res->%action-comment = if_abap_behv=>fc-o-enabled.
          if ls_stats-nochanges is initial.
            lo_res->%action-submit = if_abap_behv=>fc-o-enabled.
          endif.
          if ls_stats-requestedby = lv_user.
            lo_res->%delete = if_abap_behv=>fc-o-enabled.
          endif.
          lo_res->%update = if_abap_behv=>fc-o-enabled.
          lo_res->%field-attachment = if_abap_behv=>fc-f-unrestricted.
        when submitted.
          if ls_stats-requestedby <> lv_user.
            if lv_noapproval is initial.
              " lo_res->%action-approve1 = if_abap_behv=>fc-o-enabled. "Not used in current version
              lo_res->%action-approve2 = if_abap_behv=>fc-o-enabled.
            endif.
            lo_res->%action-reject = if_abap_behv=>fc-o-enabled.
          endif.
          lo_res->%update = if_abap_behv=>fc-o-enabled.
          lo_res->%action-comment = if_abap_behv=>fc-o-enabled.
        when apprlv1.
          if     ls_stats-requestedby <> lv_user
             and ls_stats-approval1   <> lv_user.
            if lv_noapproval is initial.
              lo_res->%action-approve2 = if_abap_behv=>fc-o-enabled.
            endif.
            lo_res->%action-reject = if_abap_behv=>fc-o-enabled.
          endif.
          lo_res->%update = if_abap_behv=>fc-o-enabled.
          lo_res->%action-comment = if_abap_behv=>fc-o-enabled.
        when apprlv2.
          if     ls_stats-requestedby <> lv_user
             and ls_stats-approval1   <> lv_user
             and lv_noapproval        is initial.
            lo_res->%action-approve2 = if_abap_behv=>fc-o-enabled. " In case earlier save didn't work completely
          endif.
          lo_res->%action-comment = if_abap_behv=>fc-o-enabled.
          lo_res->%update = if_abap_behv=>fc-o-enabled. " In case if data couldn't be saved and needs to be corrected
        when complete or existing.
          if ls_open-bankid is initial. " Open requests doesn't exist
            lo_res->%action-copyto = if_abap_behv=>fc-o-enabled.
          endif.
        when others.
      endcase.
      clear: ls_stats,
             ls_open.
    endloop.
  endmethod.

  method get_instance_authorizations.
  endmethod.

  method approve1.
    data lt_mod type table for update zi_bpbank.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).

    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      append initial line to lt_mod reference into data(lo_mod).
      lo_mod->%tky      = ls_key-%tky.
      lo_mod->status    = apprlv1.
      lo_mod->approval1 = cl_abap_context_info=>get_user_technical_name( ).
      lo_mod->comments  = build_comment( im_title = text-013
                                         im_old   = ls_bnk-comments ).
      lo_mod->%control-status    = if_abap_behv=>mk-on.
      lo_mod->%control-approval1 = if_abap_behv=>mk-on.
      lo_mod->%control-comments  = if_abap_behv=>mk-on.
    endloop.

    lcl_singleton=>emailer->for_requestor = corresponding #( lt_mod ).

    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           update from lt_mod
           reported reported
           failed failed.
  endmethod.

  method move_attachment.
    data lo_api                 type ref to cl_attachment_service_api.
    data lv_attachmentobjectkey type if_attachment_service_api=>objectkey.
    data lv_documentlink        type if_attachment_service_api=>ts_attachment.
    constants lc_technicalobjecttype type if_attachment_service_api=>technicalobjecttype value 'BUS1006'.

    try.
        lo_api = cl_attachment_service_api=>get_instance( ).

        lv_attachmentobjectkey = iv_bp.

        lo_api->if_attachment_service_api~create_attachment(
          exporting iv_technicalobjecttype = lc_technicalobjecttype
                    iv_attachmentobjectkey = lv_attachmentobjectkey
                    iv_filename            = iv_filename
                    is_media_resource      = value #( mime_type = iv_mimetype
                                                      value     = iv_filecontent )
          importing es_attachment          = lv_documentlink ).
        rv_attachment = |/sap/opu/odata/sap/CV_ATTACHMENT_SRV/OriginalContentSet(Documenttype='{
                          lv_documentlink-documentinforecorddoctype
                          }',Documentnumber='{
                          lv_documentlink-documentinforecorddocnumber
                          }',Documentpart='{
                          lv_documentlink-documentinforecorddocpart
                          }',Documentversion='{
                          lv_documentlink-documentinforecorddocversion
                          }',ApplicationId='{
                          lv_documentlink-logicaldocument
                          }',FileId='{
                          lv_documentlink-archivedocumentid
                          }')/$value|.
      catch cx_root.
    endtry.
  endmethod.

  method approve2.
    data lt_mod type table for update zi_bpbank.
    data lt_crt type table for create I_BusinessPartnerTP_3\_BusinessPartnerBank.
    data lt_upd type table for update I_BusinessPartnerBankTP_3.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).

    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      append initial line to lt_mod reference into data(lo_mod).

      lo_mod->%tky      = ls_key-%tky.
      lo_mod->status    = apprlv2.
      lo_mod->approval2 = cl_abap_context_info=>get_user_technical_name( ).
      lo_mod->comments  = build_comment( im_title = text-012
                                         im_old   = ls_bnk-comments ).
      lo_mod->%control-status    = if_abap_behv=>mk-on.
      lo_mod->%control-comments  = if_abap_behv=>mk-on.
      lo_mod->%control-approval2 = if_abap_behv=>mk-on.

      if ls_bnk-attachment is not initial and ls_bnk-filename is not initial and ls_bnk-mimetype is not initial.
        lo_mod->documentlink = move_attachment( iv_bp          = ls_bnk-BusinessPartner
                                                iv_filecontent = ls_bnk-Attachment
                                                iv_mimetype    = conv #( ls_bnk-MimeType )
                                                iv_filename    = conv #( ls_bnk-FileName ) ).
        lo_mod->%control-documentlink = if_abap_behv=>mk-on.
        lo_mod->%control-attachment   = if_abap_behv=>mk-on.
      endif.

      if ls_bnk-NoHistory is not initial.
        append initial line to lt_crt reference into data(lo_crt).
        lo_mod->bankid = ls_key-reqid.
        lo_mod->%control-bankid = if_abap_behv=>mk-on.
        lo_crt->BusinessPartner = |{ ls_key-businesspartner alpha = in }|.
        lo_crt->%target         = value #( ( %cid                          = 'BNK'
                                             BankIdentification            = ls_key-reqid
                                             BankCountryKey                = ls_bnk-BankCountryKey
                                             BankNumber                    = ls_bnk-BankNumber
                                             BankControlKey                = ls_bnk-BankControlKey
                                             BankAccountHolderName         = ls_bnk-BankAccountHolderName
                                             BankAccountName               = ls_bnk-BankAccountName
                                             BankValidityStartDate         = ls_bnk-BankValidityStartDate
                                             BankValidityEndDate           = ls_bnk-BankValidityEndDate
                                             Iban                          = ls_bnk-Iban
                                             BankAccount                   = ls_bnk-BankAccount
                                             BankAccountReferenceText      = ls_bnk-BankAccountReferenceText
                                             CollectionAuthInd             = ls_bnk-CollectionAuthInd
                                             BusinessPartnerExternalBankID = ls_bnk-BusinessPartnerExternalBankID
                                             %control                      = value #(
                                                 BankIdentification            = if_abap_behv=>mk-on
                                                 BankCountryKey                = if_abap_behv=>mk-on
                                                 BankNumber                    = if_abap_behv=>mk-on
                                                 BankControlKey                = if_abap_behv=>mk-on
                                                 BankAccountHolderName         = if_abap_behv=>mk-on
                                                 BankAccountName               = if_abap_behv=>mk-on
                                                 BankValidityStartDate         = if_abap_behv=>mk-on
                                                 BankValidityEndDate           = if_abap_behv=>mk-on
                                                 Iban                          = if_abap_behv=>mk-on
                                                 BankAccount                   = if_abap_behv=>mk-on
                                                 BankAccountReferenceText      = if_abap_behv=>mk-on
                                                 CollectionAuthInd             = if_abap_behv=>mk-on
                                                 BusinessPartnerExternalBankID = if_abap_behv=>mk-on ) ) ).
      else.
        append initial line to lt_upd reference into data(lo_upd).
        lo_upd->* = value #(
            BusinessPartner               = |{ ls_key-businesspartner alpha = in }|
            BankIdentification            = ls_bnk-BankId
            BankCountryKey                = ls_bnk-BankCountryKey
            BankNumber                    = ls_bnk-BankNumber
            BankControlKey                = ls_bnk-BankControlKey
            BankAccountHolderName         = ls_bnk-BankAccountHolderName
            BankAccountName               = ls_bnk-BankAccountName
            BankValidityStartDate         = ls_bnk-BankValidityStartDate
            BankValidityEndDate           = ls_bnk-BankValidityEndDate
            Iban                          = ls_bnk-Iban
            BankAccount                   = ls_bnk-BankAccount
            BankAccountReferenceText      = ls_bnk-BankAccountReferenceText
            CollectionAuthInd             = ls_bnk-CollectionAuthInd
            BusinessPartnerExternalBankID = ls_bnk-BusinessPartnerExternalBankID
            %control                      = value #(
                BankCountryKey                = cond #( when ls_bnk-BankCountryKey <> ls_bnk-oBankCountryKey
                                                        then if_abap_behv=>mk-on )
                BankNumber                    = cond #( when ls_bnk-BankNumber <> ls_bnk-oBankNumber
                                                        then if_abap_behv=>mk-on )
                BankControlKey                = cond #( when ls_bnk-BankControlKey <> ls_bnk-oBankControlKey
                                                        then if_abap_behv=>mk-on )
                BankAccountHolderName         = cond #( when ls_bnk-BankAccountHolderName <> ls_bnk-oBankAccountHolderName
                                                        then if_abap_behv=>mk-on )
                BankAccountName               = cond #( when ls_bnk-BankAccountName <> ls_bnk-oBankAccountName
                                                        then if_abap_behv=>mk-on )
                BankValidityStartDate         = cond #( when ls_bnk-BankValidityStartDate <> ls_bnk-oBankValidityStartDate
                                                        then if_abap_behv=>mk-on )
                BankValidityEndDate           = cond #( when ls_bnk-BankValidityEndDate <> ls_bnk-oBankValidityEndDate
                                                        then if_abap_behv=>mk-on )
                Iban                          = cond #( when ls_bnk-Iban <> ls_bnk-oIban
                                                        then if_abap_behv=>mk-on )
                BankAccount                   = cond #( when ls_bnk-BankAccount <> ls_bnk-oBankAccount
                                                        then if_abap_behv=>mk-on )
                BankAccountReferenceText      = cond #( when ls_bnk-BankAccountReferenceText <> ls_bnk-oBankAccountReferenceText
                                                        then if_abap_behv=>mk-on )
                CollectionAuthInd             = cond #( when ls_bnk-CollectionAuthInd <> ls_bnk-oCollectionAuthInd
                                                        then if_abap_behv=>mk-on )
                BusinessPartnerExternalBankID = cond #( when ls_bnk-BusinessPartnerExternalBankID <> ls_bnk-oBusinessPartnerExternalBankID
                                                        then if_abap_behv=>mk-on ) ) ).
      endif.
    endloop.

    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           update from lt_mod
           reported reported
           failed failed.
    if failed is initial.
      modify entities of I_BusinessPartnerTP_3 privileged
             entity BusinessPartner
             create by \_BusinessPartnerBank from lt_crt
             entity BusinessPartnerBank
             update from lt_upd
             reported data(ls_bprept)
             failed data(ls_bpfail).
      if ls_bpfail is not initial.
        loop at ls_bprept-BusinessPartnerBank into data(ls_bnrep).
          append initial line to reported-zi_bpbank reference into data(lo_Rep).
          lo_Rep->%tky = ls_key-%tky.
          lo_Rep->%msg = ls_bnrep-%msg.
          lo_Rep->%msg->m_severity = if_abap_behv_message=>severity-information.
        endloop.
        loop at ls_bprept-BusinessPartner into data(ls_bprep).
          append initial line to reported-zi_bpbank reference into lo_Rep.
          lo_Rep->%tky = ls_key-%tky.
          lo_Rep->%msg = ls_bprep-%msg.
          lo_Rep->%msg->m_severity = if_abap_behv_message=>severity-information.
        endloop.
      else.
        lo_mod->status = complete.
        lcl_singleton=>emailer->for_requestor = corresponding #( lt_mod ).

        modify entities of zi_bpbank in local mode
               entity zi_bpbank
               update from lt_mod
               reported reported
               failed failed.
      endif.
    endif.
  endmethod.

  method submit.
    data lt_mod type table for update zi_bpbank.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).

    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      append initial line to lt_mod reference into data(lo_mod).
      lo_mod->%tky        = ls_key-%tky.
      lo_mod->status      = submitted.
      lo_mod->requestedby = cl_abap_context_info=>get_user_technical_name( ).
      lo_mod->comments    = build_comment( im_title = text-014
                                           im_old   = ls_bnk-comments ).
      lo_mod->%control-status      = if_abap_behv=>mk-on.
      lo_mod->%control-requestedby = if_abap_behv=>mk-on.
      lo_mod->%control-comments    = if_abap_behv=>mk-on.
    endloop.

    lcl_singleton=>emailer->for_approver = corresponding #( lt_mod ).

    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           update from lt_mod
           reported reported
           failed failed.
  endmethod.

  method earlynumbering_create.
    select bank~BusinessPartner,
           max( bank~reqid )    as bankid
           from zi_bpbank with privileged access as bank
           join @entities as ent
            on bank~BusinessPartner = ent~BusinessPartner
           group by bank~BusinessPartner
           into table @data(lt_exist).
    loop at entities into data(ls_ent).
      if ls_ent-BusinessPartner is initial.
        append initial line to failed-zi_bpbank reference into data(lo_fail).
        append initial line to reported-zi_bpbank reference into data(lo_rept).
        lo_fail->%cid = ls_ent-%cid.
        lo_fail->%key = ls_ent-%key.
        lo_rept->%cid = ls_ent-%cid.
        lo_rept->%key = ls_ent-%key.
        lo_rept->%msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                               text     = text-001 ).
        lo_rept->%element-BusinessPartner = if_abap_behv=>mk-on.
      else.
        read table lt_exist into data(ls_ext) with key BusinessPartner = ls_ent-BusinessPartner.
        get_next_number( changing cv_number = ls_ext-bankid ).
        append initial line to mapped-zi_bpbank reference into data(lo_map).
        lo_map->%cid  = ls_ent-%cid.
        lo_map->%key  = ls_ent-%key.
        lo_map->reqid = ls_ext-bankid.
      endif.
    endloop.
  endmethod.

  method get_next_number.
    constants digits type string value '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

    data pos  type i.
    data char type c length 1.
    data off  type i.

    cv_number = to_upper( cv_number ).
    cv_number = condense( |{ cv_number alpha = in }| ).
    overlay cv_number with '0000000000'.
    cv_number = reverse( cv_number ).

    do.
      char = cv_number+pos(1).
      find char in digits match offset off.
      if off < strlen( digits ) - 1.
        off += 1.
        char = digits+off(1).
        cv_number+pos(1) = char.
        cv_number = reverse( cv_number ).
        return.
      else.
        cv_number+pos(1) = digits.
      endif.
      pos += 1.
    enddo.
  endmethod.

  method copyto.
    data lt_crt type table for create zi_bpbank.

    select bnk~* from zi_bpbank with privileged access as bnk
           join @keys as upd
             on  bnk~businesspartner = upd~businesspartner
             and bnk~reqid           = upd~reqid
           into table @data(lt_old).

    select b~BusinessPartner,
           b~BankIdentification,
           b~BankCountryKey,
           b~BankNumber,
           b~BankControlKey,
           b~BankAccountHolderName,
           b~BankAccountName,
           b~BankValidityStartDate,
           b~BankValidityEndDate,
           b~Iban,
           b~BankAccount,
           b~BankAccountReferenceText,
           b~CollectionAuthInd,
           b~BusinessPartnerExternalBankID
      from zI_BPBank_Info as b
      join @lt_old as o
      on  b~BusinessPartner    = o~BusinessPartner
      and b~BankIdentification = o~BankId
        into table @data(lt_curr).
    loop at keys into data(ls_key).
      read table lt_old into data(ls_old) with key businesspartner = ls_key-businesspartner
                                                   reqid           = ls_key-reqid.
      append initial line to lt_crt reference into data(lo_crt).
      lo_crt->BusinessPartner = ls_key-businesspartner.
      lo_crt->bankid          = ls_old-bankid.
      lo_crt->%cid            = ls_key-%cid.

      read table lt_curr into data(ls_curr) with key BusinessPartner    = ls_key-businesspartner
                                                     BankIdentification = ls_old-bankid.
      if sy-subrc = 0.
        lo_crt->obankcountrykey                = ls_curr-BankCountryKey.
        lo_crt->bankcountrykey                 = lo_crt->obankcountrykey.
        lo_crt->obanknumber                    = ls_curr-BankNumber.
        lo_crt->banknumber                     = lo_crt->obanknumber.
        lo_crt->obankcontrolkey                = ls_curr-BankControlKey.
        lo_crt->bankcontrolkey                 = lo_crt->obankcontrolkey.
        lo_crt->obankaccountholdername         = ls_curr-BankAccountHolderName.
        lo_crt->bankaccountholdername          = lo_crt->obankaccountholdername.
        lo_crt->obankaccountname               = ls_curr-BankAccountName.
        lo_crt->bankaccountname                = lo_crt->obankaccountname.
        lo_crt->obankvaliditystartdate         = ls_curr-BankValidityStartDate.
        lo_crt->bankvaliditystartdate          = lo_crt->obankvaliditystartdate.
        lo_crt->obankvalidityenddate           = ls_curr-BankValidityEndDate.
        lo_crt->bankvalidityenddate            = lo_crt->obankvalidityenddate.
        lo_crt->oiban                          = ls_curr-Iban.
        lo_crt->iban                           = lo_crt->oiban.
        lo_crt->obankaccount                   = ls_curr-BankAccount.
        lo_crt->bankaccount                    = lo_crt->obankaccount.
        lo_crt->obankaccountreferencetext      = ls_curr-BankAccountReferenceText.
        lo_crt->bankaccountreferencetext       = lo_crt->obankaccountreferencetext.
        lo_crt->ocollectionauthind             = ls_curr-CollectionAuthInd.
        lo_crt->collectionauthind              = lo_crt->ocollectionauthind.
        lo_crt->obusinesspartnerexternalbankid = ls_curr-BusinessPartnerExternalBankID.
        lo_crt->businesspartnerexternalbankid  = lo_crt->obusinesspartnerexternalbankid.
        lo_crt->status                         = newrequest.
      endif.

      lo_crt->%control = value #( businesspartner                = if_abap_behv=>mk-on
                                  bankid                         = if_abap_behv=>mk-on
                                  bankcountrykey                 = if_abap_behv=>mk-on
                                  banknumber                     = if_abap_behv=>mk-on
                                  bankcontrolkey                 = if_abap_behv=>mk-on
                                  bankaccountholdername          = if_abap_behv=>mk-on
                                  bankaccountname                = if_abap_behv=>mk-on
                                  bankvaliditystartdate          = if_abap_behv=>mk-on
                                  bankvalidityenddate            = if_abap_behv=>mk-on
                                  iban                           = if_abap_behv=>mk-on
                                  bankaccount                    = if_abap_behv=>mk-on
                                  bankaccountreferencetext       = if_abap_behv=>mk-on
                                  collectionauthind              = if_abap_behv=>mk-on
                                  businesspartnerexternalbankid  = if_abap_behv=>mk-on
                                  obankcountrykey                = if_abap_behv=>mk-on
                                  obanknumber                    = if_abap_behv=>mk-on
                                  obankcontrolkey                = if_abap_behv=>mk-on
                                  obankaccountholdername         = if_abap_behv=>mk-on
                                  obankaccountname               = if_abap_behv=>mk-on
                                  obankvaliditystartdate         = if_abap_behv=>mk-on
                                  obankvalidityenddate           = if_abap_behv=>mk-on
                                  oiban                          = if_abap_behv=>mk-on
                                  obankaccount                   = if_abap_behv=>mk-on
                                  obankaccountreferencetext      = if_abap_behv=>mk-on
                                  ocollectionauthind             = if_abap_behv=>mk-on
                                  obusinesspartnerexternalbankid = if_abap_behv=>mk-on
                                  status                         = if_abap_behv=>mk-on ).
    endloop.
    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           create from lt_crt
           reported reported
           failed failed
           mapped mapped.
  endmethod.

  method GetDefaultsForCreate.
    loop at keys into data(ls_key).
      append initial line to result reference into data(lo_res).
      lo_res->%cid = ls_key-%cid.
      lo_res->%param-status      = newrequest.
      lo_res->%param-Nohistory   = abap_True.
      lo_res->%param-NoApprovals = abap_True.
      lo_res->%param-NoComments  = abap_True.
    endloop.
  endmethod.

  method statusUpdateOnEdit.
    data lt_mod type table for update zi_bpbank.

    select b~businesspartner,
           b~reqid,
           status,
           comments
      from zi_bpbank with privileged access as b
      join @keys as k
      on  b~businesspartner = k~businesspartner
      and b~reqid           = k~reqid
      into table @data(lt_read).

    loop at keys into data(ls_key).
      read table lt_read into data(ls_read) with key businesspartner = ls_key-businesspartner
                                                     reqid           = ls_key-reqid.
      if sy-subrc <> 0 or ls_read-status = newrequest.
        continue.
      endif.

      append initial line to lt_mod reference into data(lo_mod).
      lo_mod->%tky        = ls_key-%tky.
      lo_mod->status      = newrequest.
      lo_mod->requestedby = space.
      lo_mod->approval1   = space.
      lo_mod->approval2   = space.
      lo_mod->comments    = build_comment( im_title = text-015
                                           im_old   = ls_read-comments ).
      lo_mod->%control-status      = if_abap_behv=>mk-on.
      lo_mod->%control-requestedby = if_abap_behv=>mk-on.
      lo_mod->%control-approval1   = if_abap_behv=>mk-on.
      lo_mod->%control-approval2   = if_abap_behv=>mk-on.
      lo_mod->%control-comments    = if_abap_behv=>mk-on.
    endloop.

    if lt_mod is not initial.
      modify entities of zi_bpbank in local mode
             entity zi_bpbank
             update from lt_mod.
    endif.
  endmethod.

  method comment.
    data lt_mod type table for update zi_bpbank.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).

    loop at keys into data(ls_key) where %param-corresp is not initial.
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      append initial line to lt_mod reference into data(lo_mod).
      lo_mod->%tky     = ls_key-%tky.
      lo_mod->comments = build_comment( im_title = text-002
                                        im_new   = ls_key-%param-corresp
                                        im_old   = ls_bnk-comments ).
      lo_mod->%control-comments = if_abap_behv=>mk-on.
    endloop.

    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           update from lt_mod
           reported reported
           failed failed.
  endmethod.

  method build_comment.
    data lv_date type d.
    try.
        lv_date = cl_abap_context_info=>get_system_date( ).
        rv_str = |{ im_title } { cl_abap_context_info=>get_user_description( ) } { text-003 } { zcl_get_system_id=>date_to_external( lv_date ) }|.
        if im_new is not initial.
          rv_str = rv_str && |\r\n{ im_new }|.
        endif.
        if im_old is not initial.
          rv_str = rv_str && |\r\n\r\n{ im_old }|.
        endif.
      catch cx_root.
    endtry.
  endmethod.

  method reject.
    data lt_mod type table for update zi_bpbank.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).

    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      append initial line to lt_mod reference into data(lo_mod).
      lo_mod->%tky     = ls_key-%tky.
      lo_mod->status   = rejected.
      lo_mod->comments = build_comment( im_title = text-004
                                        im_new   = ls_key-%param-corresp
                                        im_old   = ls_bnk-comments ).
      lo_mod->%control-approval1 = if_abap_behv=>mk-on.
      lo_mod->%control-approval2 = if_abap_behv=>mk-on.
      lo_mod->%control-status    = if_abap_behv=>mk-on.
      lo_mod->%control-comments  = if_abap_behv=>mk-on.
    endloop.

    lcl_singleton=>emailer->for_requestor = corresponding #( lt_mod ).

    modify entities of zi_bpbank in local mode
           entity zi_bpbank
           update from lt_mod
           reported reported
           failed failed.
  endmethod.

  method checkMandatory.
    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).
    if lt_bnk is not initial.
      select BankCountry    as BankCountryKey,
             BankInternalID as BankNumber
        from I_BankVH with privileged access
        for all entries in @lt_bnk
        where BankCountry    = @lt_bnk-BankCountryKey
          and BankInternalID = @lt_bnk-BankNumber
        into table @data(lt_valid).
    endif.
    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      if sy-subrc <> 0.
        continue.
      endif.

      if    ls_bnk-BankCountryKey is initial
         or ls_bnk-BankNumber     is initial
         or ls_bnk-BankAccount    is initial.
        append initial line to reported-zi_bpbank reference into data(lo_rep).
        lo_rep->%tky     = ls_key-%tky.
        lo_rep->%msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                              text     = text-005 ).
        lo_rep->%element = value #(
            BankCountryKey = cond #( when ls_bnk-BankCountryKey is initial then if_abap_behv=>mk-on )
            BankNumber     = cond #( when ls_bnk-BankNumber is initial then if_abap_behv=>mk-on )
            BankAccount    = cond #( when ls_bnk-BankAccount is initial then if_abap_behv=>mk-on ) ).
        append initial line to failed-zi_bpbank reference into data(lo_fail).
        lo_fail->%tky = ls_key-%tky.
      else.
        if not line_exists( lt_valid[ BankCountryKey = ls_bnk-BankCountryKey
                                      BankNumber     = ls_bnk-BankNumber ] ).
          append initial line to reported-zi_bpbank reference into lo_rep.
          lo_rep->%tky     = ls_key-%tky.
          lo_rep->%msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                text     = text-006 ).
          lo_rep->%element = value #(
              BankCountryKey = if_abap_behv=>mk-on
              BankNumber     = if_abap_behv=>mk-on ).
          append initial line to failed-zi_bpbank reference into lo_fail.
          lo_fail->%tky = ls_key-%tky.
        endif.
      endif.
    endloop.
  endmethod.

  method dateCheck.
    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).
    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      if sy-subrc <> 0.
        continue.
      endif.

      if ls_bnk-BankValidityEndDate < ls_bnk-BankValidityStartDate.
        append initial line to reported-zi_bpbank reference into data(lo_rep).
        lo_rep->%tky     = ls_key-%tky.
        lo_rep->%msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                              text     = text-007 ).
        lo_rep->%element = value #( BankValidityEndDate   = if_abap_behv=>mk-on
                                    BankValidityStartDate = if_abap_behv=>mk-on ).
        append initial line to failed-zi_bpbank reference into data(lo_fail).
        lo_fail->%tky = ls_key-%tky.
      endif.
    endloop.
  endmethod.

  method ibanCheck.
    data lv_pattern type string.

    read entities of zi_bpbank in local mode
         entity zi_bpbank
         all fields with corresponding #( keys )
         result data(lt_bnk).
    loop at keys into data(ls_key).
      read table lt_bnk into data(ls_bnk) with key %tky = ls_key-%tky ##primkey[id].
      if sy-subrc <> 0 or ls_bnk-iban is initial.
        continue.
      endif.

      lv_pattern = |{ ls_bnk-BankCountryKey }*{ ls_bnk-BankNumber }*{ ls_bnk-BankAccount }*|.

      if to_upper( ls_bnk-Iban ) <> ls_bnk-Iban.
        data(lo_msg) = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                              text     = text-009 ).
      elseif condense( val  = ls_bnk-Iban
                       from = ` `
                       to   = `` ) <> ls_bnk-Iban.
        lo_msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text     = text-010 ).
      elseif not ls_bnk-Iban co |{ numbers } { letters }|.
        lo_msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text     = text-010 ).
      elseif new lcl_iban_validation( )->mod97_check( ls_bnk-Iban ) is not initial.
        lo_msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text     = text-008 ).
*      elseif ls_bnk-Iban np lv_pattern.
*        lo_msg = new_message_with_text( severity = if_abap_behv_message=>severity-warning
*                                        text     = text-011 ).
      endif.
      if lo_msg is not initial.
        append initial line to reported-zi_bpbank reference into data(lo_rep).
        lo_rep->%tky     = ls_key-%tky.
        lo_rep->%msg     = lo_msg.
        lo_rep->%element = value #( iban = if_abap_behv=>mk-on ).
        if lo_msg->m_severity = if_abap_behv_message=>severity-error.
          append initial line to failed-zi_bpbank reference into data(lo_fail).
          lo_fail->%tky = ls_key-%tky.
        endif.
      endif.
    endloop.
  endmethod.

endclass.
