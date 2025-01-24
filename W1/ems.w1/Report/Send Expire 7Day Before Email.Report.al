report 52104 "Send Expire 7Day Before Email"
{
    Caption = 'Send Expiry Email Before 7 Day of License Expiration';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem("License Request"; "License Request")
        {
            RequestFilterFields = "No.", "License No.";
            DataItemTableView = where("License No." = filter(<> ''));

            trigger OnPreDataItem()
            begin
                Setrange("Expiry Date", Today + 7);
            end;

            trigger OnAfterGetRecord()
            var
                LicEmailSend_lCdu: codeunit "License Email Sending";
            begin
                IF "Expiry Date" = 0D Then CurrReport.skip;
                // CalDay_lInt := "Expiry Date" - Today;
                // IF CalDay_lInt < 0 then
                //     CurrReport.skip;
                // IF CalDay_lInt > 7 then
                //     CurrReport.Skip();
                //T29353-NS
                Clear(LicEmailSend_lCdu);
                LicEmailSend_lCdu.SendExpiredBeforeSevenDayEmail_gFnc("License Request", false);
                //T29353-NE
            end;
        }
        //T34311-NS
        dataitem("License RequestBefore3Days"; "License Request")
        {
            RequestFilterFields = "No.", "License No.";
            DataItemTableView = where("License No." = filter(<> ''));

            trigger OnPreDataItem()
            begin
                Setrange("Expiry Date", Today + 3);
            end;

            trigger OnAfterGetRecord()
            var
                LicEmailSend_lCdu: codeunit "License Email Sending";
            begin
                IF "Expiry Date" = 0D Then CurrReport.skip;
                //T29353-NS
                Clear(LicEmailSend_lCdu);
                LicEmailSend_lCdu.SendExpiredBeforeThreeDayEmail_gFnc("License RequestBefore3Days", false);
                //T29353-NE
            end;
        }
        //T34311-NE
    }
}
