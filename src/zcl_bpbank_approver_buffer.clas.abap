class zcl_bpbank_approver_buffer definition
  public create public.

  public section.
    interfaces if_bgmc_op_single_tx_uncontr.

    class-data lo_badi type ref to srf_report_run_on_delete.

    class-methods class_constructor.

    data for_approver  type table for key of zi_bpbank.
    data for_requestor type table for key of zi_bpbank.

    types: begin of ty_input,
             country type i_countryvh-country,
           end of ty_input,
           tyt_input type standard table of ty_input with default key.

    types: begin of ty_output,
             country type i_countryvh-country,
             member  type I_BusinessPartner-BusinessPartner,
             email   type I_WorkplaceAddress-DefaultEmailAddress,
           end of ty_output,
           tyt_output type standard table of ty_output with default key.

    class-data country_list type tyt_input.
    class-data users_list   type tyt_output.
  protected section.
  private section.
    class-methods find_users.
endclass.



class zcl_bpbank_approver_buffer implementation.
  method class_constructor.
    get badi lo_Badi
        filters
          report_id = 'BP_BANK_CHANGE'.
  endmethod.

  method if_bgmc_op_single_tx_uncontr~execute.
    data lv_link type string.

    if for_approver is not initial.
      select b~businesspartner,
             s~reqid,
             BankCountryKey,
             b~\_bp-BusinessPartnerFullName,
             b~\_stat-text                  as Status,
             b~\_req-UserDescription
           from zi_bpbank as b
           join @for_approver as s
             on  b~businesspartner = s~businesspartner
             and b~reqid           = s~reqid
           into table @data(lt_readresult).
    elseif for_requestor is not initial.
      select b~businesspartner,
             s~reqid,
             BankCountryKey,
             b~\_bp-BusinessPartnerFullName,
             b~\_stat-text                  as Status,
             b~\_req-UserDescription
           from zi_bpbank as b
           join @for_requestor as s
             on  b~businesspartner = s~businesspartner
             and b~reqid           = s~reqid
           into table @lt_readresult.
    endif.

    country_list = corresponding #( lt_readresult mapping country = BankCountryKey ).
    sort country_list.
    delete adjacent duplicates from country_list comparing all fields.
    find_users( ).

    if users_list is initial.
      return.
    endif.

    loop at lt_readresult into data(ls_bnk).
      try.
          data(lo_mail) = cl_bcs_mail_message=>create_instance( ).

          " TODO: variable is assigned but never used (ABAP cleaner)
          loop at users_list into data(ls_user) where country = ls_bnk-BankCountryKey.
            " lo_mail->add_recipient( iv_address = conv #( ls_user-email ) ).
          endloop.
          lo_mail->add_recipient( iv_address = conv #( 'thomas.juwin@bcg.com' ) ).

          lo_mail->set_subject( text-e01 ).

          lv_link = condense( val = |https://{ cl_abap_context_info=>get_system_url( ) }/ui#zbpbankchng-Request&/zc_bpbank(businesspartner='{ ls_bnk-businesspartner alpha = out }',reqid='{ ls_bnk-reqid }')|
                              from = ` ` to = '' ).

          lo_mail->set_main(
              cl_bcs_mail_textpart=>create_instance(
                  iv_content      = replace(
                      val  = zcl_email_format=>get_format( )
                      sub  = zcl_email_format=>replace_tag
                      with = |<p>{ text-e02 } <a href='{ lv_link }'>{ text-e03 }</a></p><p>{ text-e04 } { ls_bnk-Status }</p><p>{ text-e05 } { ls_bnk-UserDescription }</p>| )
                  iv_content_type = 'text/html' ) ).
          lo_mail->send( ).
        catch cx_root.
      endtry.
    endloop.
  endmethod.

  method find_users.
    data lt_msg type symsg_tab.

    if lo_badi is bound.
      try.
          call badi lo_badi->execute
            exporting iv_force_delete   = ``
                      iv_report_run_key = ``
                      iv_test_run       = ``
            changing  ct_message        = lt_msg.
        catch cx_root.
      endtry.
    endif.
  endmethod.
endclass.
