codeunit 52111 "License Email Sending"
{
    procedure SendActivationEmail_gFnc(LicReq_iRec: Record "License Request"; ShowError_iBln: Boolean)
    var
        Recipient_lTxt: Text;
    begin
        // IF LicReq_iRec."Ship-to Code" <> '' Then begin
        //     ShipToAdd_lRec.GET(LicReq_iRec."Customer No.", LicReq_iRec."Ship-to Code");
        //     IF ShowError_iBln THen
        //         ShipToAdd_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := ShipToAdd_lRec."E-Mail";
        // end Else begin
        //     Clear(Customer_lRec);
        //     Customer_lRec.Get(LicReq_iRec."Customer No.");
        //     IF ShowError_iBln THen
        //         Customer_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := Customer_lRec."E-Mail";
        // End;
        IF ShowError_iBln then LicReq_iRec.Testfield("E-Mail");
        IF LicReq_iRec."E-Mail" <> '' then Recipient_lTxt := LicReq_iRec."E-Mail";
        IF Recipient_lTxt = '' then Exit;
        VerifyAddEmail_lFnc(RecipientsList, Recipient_lTxt);
        EmailTempSetup_gRec.GET;
        EmailTempSetup_gRec.Testfield("License Activation ET");
        EmailTem_gRec.GET(EmailTempSetup_gRec."License Activation ET");
        EmailTem_gRec.Testfield(Subject);
        EmailTem_gRec.Testfield("Email Body Report ID");
        EmailTem_gRec.Testfield("Email Body Layout Code");
        LicStatusCaption_gTxt := '';
        Case LicReq_iRec."Document Type" of
            LicReq_iRec."Document Type"::New, LicReq_iRec."Document Type"::"Add on":
                LicStatusCaption_gTxt := 'Activated';
            LicReq_iRec."Document Type"::Renewal:
                LicStatusCaption_gTxt := 'Renewed';
            LicReq_iRec."Document Type"::Extension:
                LicStatusCaption_gTxt := 'Extended';
        End;
        Subject := StrSubstNo(EmailTem_gRec.Subject, LicStatusCaption_gTxt);
        SendEmail_lFnc(LicReq_iRec);
    end;

    procedure SendExpiredEmail_gFnc(LicReq_iRec: Record "License Request"; ShowError_iBln: Boolean)
    var
        Recipient_lTxt: Text;
    begin
        // IF LicReq_iRec."Ship-to Code" <> '' Then begin
        //     ShipToAdd_lRec.GET(LicReq_iRec."Customer No.", LicReq_iRec."Ship-to Code");
        //     IF ShowError_iBln THen
        //         ShipToAdd_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := ShipToAdd_lRec."E-Mail";
        // end Else begin
        //     Clear(Customer_lRec);
        //     Customer_lRec.Get(LicReq_iRec."Customer No.");
        //     IF ShowError_iBln THen
        //         Customer_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := Customer_lRec."E-Mail";
        // End;
        IF ShowError_iBln then LicReq_iRec.Testfield("E-Mail");
        IF LicReq_iRec."E-Mail" <> '' then Recipient_lTxt := LicReq_iRec."E-Mail";
        IF Recipient_lTxt = '' then Exit;
        VerifyAddEmail_lFnc(RecipientsList, Recipient_lTxt);
        EmailTempSetup_gRec.GET;
        EmailTempSetup_gRec.Testfield("License Expired ET");
        EmailTem_gRec.GET(EmailTempSetup_gRec."License Expired ET");
        EmailTem_gRec.Testfield(Subject);
        EmailTem_gRec.Testfield("Email Body Report ID");
        EmailTem_gRec.Testfield("Email Body Layout Code");
        LicStatusCaption_gTxt := '';
        IF LicReq_iRec.Terminated then
            LicStatusCaption_gTxt := 'Terminated'
        Else
            LicStatusCaption_gTxt := 'Expired';
        Subject := StrSubstNo(EmailTem_gRec.Subject, LicStatusCaption_gTxt);
        SendEmail_lFnc(LicReq_iRec);
    end;

    procedure SendExpiredBeforeSevenDayEmail_gFnc(LicReq_iRec: Record "License Request"; ShowError_iBln: Boolean)
    var
        Recipient_lTxt: Text;
    begin
        // IF LicReq_iRec."Ship-to Code" <> '' Then begin
        //     ShipToAdd_lRec.GET(LicReq_iRec."Customer No.", LicReq_iRec."Ship-to Code");
        //     IF ShowError_iBln THen
        //         ShipToAdd_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := ShipToAdd_lRec."E-Mail";
        // end Else begin
        //     Clear(Customer_lRec);
        //     Customer_lRec.Get(LicReq_iRec."Customer No.");
        //     IF ShowError_iBln THen
        //         Customer_lRec.Testfield("E-Mail");
        //     Recipient_lTxt := Customer_lRec."E-Mail";
        // End;
        IF ShowError_iBln then LicReq_iRec.Testfield("E-Mail");
        IF LicReq_iRec."E-Mail" <> '' then Recipient_lTxt := LicReq_iRec."E-Mail";
        IF Recipient_lTxt = '' then Exit;
        VerifyAddEmail_lFnc(RecipientsList, Recipient_lTxt);
        EmailTempSetup_gRec.GET;
        EmailTempSetup_gRec.Testfield("License Expired 7Day ET");
        EmailTem_gRec.GET(EmailTempSetup_gRec."License Expired 7Day ET");
        EmailTem_gRec.Testfield(Subject);
        EmailTem_gRec.Testfield("Email Body Report ID");
        EmailTem_gRec.Testfield("Email Body Layout Code");
        LicStatusCaption_gTxt := '';
        Case LicReq_iRec."Document Type" of
            LicReq_iRec."Document Type"::New, LicReq_iRec."Document Type"::"Add on":
                LicStatusCaption_gTxt := 'Activated';
            LicReq_iRec."Document Type"::Renewal:
                LicStatusCaption_gTxt := 'Renewed';
            LicReq_iRec."Document Type"::Extension:
                LicStatusCaption_gTxt := 'Extended';
        End;
        Subject := EmailTem_gRec.Subject;
        SendEmail_lFnc(LicReq_iRec);
    end;
    //T34311-NS
    procedure SendExpiredBeforeThreeDayEmail_gFnc(LicReq_iRec: Record "License Request"; ShowError_iBln: Boolean)
    var
        Recipient_lTxt: Text;
    begin
        IF ShowError_iBln then LicReq_iRec.Testfield("E-Mail");
        IF LicReq_iRec."E-Mail" <> '' then Recipient_lTxt := LicReq_iRec."E-Mail";
        IF Recipient_lTxt = '' then Exit;
        VerifyAddEmail_lFnc(RecipientsList, Recipient_lTxt);
        EmailTempSetup_gRec.GET;
        EmailTempSetup_gRec.Testfield("License Expired 3Day ET");
        EmailTem_gRec.GET(EmailTempSetup_gRec."License Expired 3Day ET");
        EmailTem_gRec.Testfield(Subject);
        EmailTem_gRec.Testfield("Email Body Report ID");
        EmailTem_gRec.Testfield("Email Body Layout Code");
        LicStatusCaption_gTxt := '';
        Case LicReq_iRec."Document Type" of
            LicReq_iRec."Document Type"::New, LicReq_iRec."Document Type"::"Add on":
                LicStatusCaption_gTxt := 'Activated';
            LicReq_iRec."Document Type"::Renewal:
                LicStatusCaption_gTxt := 'Renewed';
            LicReq_iRec."Document Type"::Extension:
                LicStatusCaption_gTxt := 'Extended';
        End;
        Subject := EmailTem_gRec.Subject;
        SendEmail_lFnc(LicReq_iRec);
    end;
    //T34311-NE
    procedure SendDuningEmail_gFnc(LicReq_iRec: Record "License Request"; ShowError_iBln: Boolean)
    var
        Recipient_lTxt: Text;
    begin
        IF ShowError_iBln then LicReq_iRec.Testfield("E-Mail");
        IF LicReq_iRec."E-Mail" <> '' then Recipient_lTxt := LicReq_iRec."E-Mail";
        IF Recipient_lTxt = '' then Exit;
        VerifyAddEmail_lFnc(RecipientsList, Recipient_lTxt);
        EmailTempSetup_gRec.GET;
        EmailTempSetup_gRec.Testfield("Duning Email");
        EmailTem_gRec.GET(EmailTempSetup_gRec."Duning Email");
        EmailTem_gRec.Testfield(Subject);
        EmailTem_gRec.Testfield("Email Body Report ID");
        EmailTem_gRec.Testfield("Email Body Layout Code");
        LicStatusCaption_gTxt := '';
        Case LicReq_iRec."Document Type" of
            LicReq_iRec."Document Type"::New, LicReq_iRec."Document Type"::"Add on":
                LicStatusCaption_gTxt := 'Activated';
            LicReq_iRec."Document Type"::Renewal:
                LicStatusCaption_gTxt := 'Renewed';
            LicReq_iRec."Document Type"::Extension:
                LicStatusCaption_gTxt := 'Extended';
        End;
        Subject := EmailTem_gRec.Subject;
        SendEmail_lFnc(LicReq_iRec);
    end;

    local procedure VerifyAddEmail_lFnc(Var InputRecipients: List of [Text]; EmailText_lTxt: Text)
    var
        LastChr: Text;
        TmpRecipients: Text;
    begin
        IF EmailText_lTxt = '' then Exit;
        IF STRPOS(EmailText_lTxt, ';') <> 0 THEN BEGIN //System doesn't work if the email address end with semi colon  /ex: xyz@abc.com;
            LastChr := COPYSTR(EmailText_lTxt, STRLEN(EmailText_lTxt));
            IF LastChr = ';' THEN EmailText_lTxt := COPYSTR(EmailText_lTxt, 1, STRPOS(EmailText_lTxt, ';') - 1);
        END;
        IF STRPOS(EmailText_lTxt, ',') <> 0 THEN BEGIN //System doesn't work if the email address end with Comma  /ex: xyz@abc.com,
            LastChr := COPYSTR(EmailText_lTxt, STRLEN(EmailText_lTxt));
            IF LastChr = ',' THEN EmailText_lTxt := COPYSTR(EmailText_lTxt, 1, STRPOS(EmailText_lTxt, ',') - 1);
        END;
        TmpRecipients := DELCHR(EmailText_lTxt, '<>', ';');
        WHILE STRPOS(TmpRecipients, ';') > 1 DO BEGIN
            InputRecipients.Add((COPYSTR(TmpRecipients, 1, STRPOS(TmpRecipients, ';') - 1)));
            TmpRecipients := COPYSTR(TmpRecipients, STRPOS(TmpRecipients, ';') + 1);
        END;
        InputRecipients.Add(TmpRecipients);
    end;

    Local procedure GetHTMLBody(LicReq_iRec: Record "License Request")
    var
        FilterLR_lRec: Record "License Request";
        ReportLayoutSelection: Record "Report Layout Selection";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        BlobOutStream: OutStream;
        InOutStream: InStream;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(InOutStream);
        FilterLR_lRec.RESET;
        FilterLR_lRec.Setrange("No.", LicReq_iRec."No.");
        RecRef.GetTable(FilterLR_lRec);
        ReportLayoutSelection.SetTempLayoutSelected(EmailTem_gRec."Email Body Layout Code");
        REPORT.SAVEAS(EmailTem_gRec."Email Body Report ID", '', REPORTFORMAT::Html, BlobOutStream, RecRef);
        ReportLayoutSelection.SetTempLayoutSelected('');
        InOutStream.ReadText(HTMLBodyText);
    end;

    local procedure SendEmail_lFnc(LicReq_iRec: Record "License Request")
    var
        Body: Text;
        Email: Codeunit Email;
        SP_lRec: Record "Salesperson/Purchaser";
        Employee_lRec: Record Employee;
    begin
        VerifyAddEmail_lFnc(CCList, EmailTem_gRec."Email CC");
        VerifyAddEmail_lFnc(BCCList, EmailTem_gRec."Email BCC");
        IF LicReq_iRec."Salesperson Code" <> '' Then begin
            IF SP_lRec.GET(LicReq_iRec."Salesperson Code") Then
                IF SP_lRec."E-Mail" <> '' THen begin
                    VerifyAddEmail_lFnc(CCList, SP_lRec."E-Mail");
                end;
            IF SP_lRec."E-Mail 2" <> '' THen begin
                VerifyAddEmail_lFnc(CCList, SP_lRec."E-Mail 2");
            end;
        end;
        IF LicReq_iRec."Requested By" <> '' THen begin
            IF Employee_lRec.GET(LicReq_iRec."Requested By") Then IF Employee_lRec."Company E-Mail" <> '' then VerifyAddEmail_lFnc(CCList, Employee_lRec."Company E-Mail");
        end;
        GetHTMLBody(LicReq_iRec);
        Body := HTMLBodyText;
        //T34311-NS
        OnBeforeCreateEmailMessage(LicReq_iRec, RecipientsListNew_gTxt, CCListNew_gTxt, BCCListNew_gTxt);
        IF RecipientsListNew_gTxt <> '' then begin
            WHILE STRPOS(RecipientsListNew_gTxt, ';') > 1 DO BEGIN
                RecipientsList.Add((COPYSTR(RecipientsListNew_gTxt, 1, STRPOS(RecipientsListNew_gTxt, ';') - 1)));
                RecipientsListNew_gTxt := COPYSTR(RecipientsListNew_gTxt, STRPOS(RecipientsListNew_gTxt, ';') + 1);
            END;
            RecipientsList.Add(RecipientsListNew_gTxt);
        End;
        IF CCListNew_gTxt <> '' then begin
            WHILE STRPOS(CCListNew_gTxt, ';') > 1 DO BEGIN
                CCList.Add((COPYSTR(CCListNew_gTxt, 1, STRPOS(CCListNew_gTxt, ';') - 1)));
                CCListNew_gTxt := COPYSTR(CCListNew_gTxt, STRPOS(CCListNew_gTxt, ';') + 1);
            END;
            CCList.Add(CCListNew_gTxt);
        end;
        IF BCCListNew_gTxt <> '' then begin
            WHILE STRPOS(BCCListNew_gTxt, ';') > 1 DO BEGIN
                BCCList.Add((COPYSTR(BCCListNew_gTxt, 1, STRPOS(BCCListNew_gTxt, ';') - 1)));
                BCCListNew_gTxt := COPYSTR(BCCListNew_gTxt, STRPOS(BCCListNew_gTxt, ';') + 1);
            END;
            BCCList.Add(BCCListNew_gTxt);
        end;
        //T34311-NE
        EmailMessage.Create(RecipientsList, Subject, Body, true, CCList, BCCList);
        Email.Send(EmailMessage, Enum::"Email Scenario"::Default);
    end;

    var
        EmailMessage: Codeunit "Email Message";
        HTMLBodyText: Text;
        EmailTem_gRec: Record "Email Template";
        EmailTempSetup_gRec: Record "Email Template Setup";
        LicStatusCaption_gTxt: Text;
        RecipientsList: List of [Text];
        CCList: List of [Text];
        BCCList: List of [Text];
        Subject: Text;
        //T34311-NS
        RecipientsListNew_gTxt: Text[1024];
        CCListNew_gTxt: Text[1024];
        BCCListNew_gTxt: Text[1024];
    //T34311-NE
    //T34331-NS
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateEmailMessage(var LicReq_iRec: Record "License Request"; var RecipientsListNew_iTxt: Text[1024]; var CCListNew_iTxt: Text[1024]; var BCCListNew_iTxt: Text[1024])
    begin
    end;
    //T34311-NE
}
