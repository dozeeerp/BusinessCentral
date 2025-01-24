report 52102 "License Request Email Body"
{
    ApplicationArea = All;
    Caption = 'License Request Email';
    UsageCategory = ReportsAndAnalysis;
    RDLCLayout = '.\Layout\LiceReqEmail.rdl';

    dataset
    {
        dataitem(LicenseRequest; "License Request")
        {
            RequestFilterFields = "No.";

            column(LicenseNo; "License No.")
            {
            }
            column(ExpiryDate; FORMAT("Expiry Date", 0, '<Day,2>/<Month,2>/<Year4>'))
            {
            }
            column(LicExpireInDay_gInt; LicExpireInDay_gInt)
            {
            }
            column(LicenseStatusCaption; LicStatusCaption_gTxt)
            {
            }
            column(LicenseType_LicenseRequest; "License Type")
            {
            }
            column(LICtoCustomerName_LicenseRequest; CustomName_gTxt)
            {
            }
            column(ActivationDate_LicenseRequest; FORMAT("Activation Date", 0, '<Day,2>/<Month,2>/<Year4>'))
            {
            }
            column(LICtoContact_LicenseRequest; SP_gRec.Name)
            {
            }
            column(LICtoPhoneNo_LicenseRequest; SP_gRec."Phone No.")
            {
            }
            column(LICtoEMail_LicenseRequest; SP_gRec."E-Mail")
            {
            }
            column(DeviceCoveredunderLicense; "License Qty.")
            {
            }
            column(LicenseCode_LicenseRequest; "License Code")
            {
            }
            column(OldExpiryDate_LicenseRequest; FORMAT("Old Expiry Date", 0, '<Day,2>/<Month,2>/<Year4>'))
            {
            }
            column("Duning_Days"; DuningDays_gInt)
            {
            }
            trigger OnAfterGetRecord()
            begin
                Clear(SP_gRec);
                DuningDays_gInt := 0;
                IF SP_gRec.GET(LicenseRequest."Salesperson Code") Then;
                // IF LicenseRequest."Ship-to Code" <> '' THen begin
                //     ShipToAdd_gRec.GET(LicenseRequest."LIC-to Customer No.", LicenseRequest."Ship-to Code");
                //     CustomName_gTxt := ShipToAdd_gRec.Name;
                // end
                // Else
                CustomName_gTxt := LicenseRequest."Customer Name";
                LicStatusCaption_gTxt := '';
                Case "Document Type" of
                    "Document Type"::New, "Document Type"::"Add on":
                        LicStatusCaption_gTxt := 'Activated';
                    "Document Type"::Renewal:
                        LicStatusCaption_gTxt := 'Renewed';
                    "Document Type"::Extension:
                        LicStatusCaption_gTxt := 'Extended';
                End;
                LicExpireInDay_gInt := 0;
                IF "Expiry Date" <> 0D Then LicExpireInDay_gInt := "Expiry Date" - Today;
                If "Old Expiry Date" <> 0D then DuningDays_gInt := "Expiry Date" - "Old Expiry Date";
            end;
        }
    }
    var
        LicStatusCaption_gTxt: Text;
        SP_gRec: Record "Salesperson/Purchaser";
        CustomName_gTxt: Text;
        ShipToAdd_gRec: Record "Ship-to Address";
        LicExpireInDay_gInt: Integer;
        DuningDays_gInt: Integer;
}
