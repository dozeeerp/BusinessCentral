report 52105 "Update Expiry Duning"
{
    Caption = 'Update Expiry Duning';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem("License Request"; "License Request")
        {
            DataItemTableView = where("License No." = filter(<> ''), Dunning = const(false), "Expiry Date" = filter(<> ''), Terminated = const(false));

            trigger OnPreDataItem()
            begin
            end;

            trigger OnAfterGetRecord()
            var
                DeviceLinked_lRec: Record "Dozee Device";
                ModLicReq_lRec: Record "License Request";
                LicenseType: Record "License Type";
                LiEmailSend_lCdu: Codeunit "License Email Sending";
            begin
                IF (Renewed) OR (Extended) then CurrReport.Skip();
                LicenseType.Get("License Request"."License Code");
                IF NOT LicenseType.Dunning then CurrReport.Skip();
                EMSAPISetup_gRec.Get();
                If "Expiry Date" = Today then begin
                    EMSAPISetup_gRec.TestField("Dunning Days");
                    DeviceLinked_lRec.Reset();
                    DeviceLinked_lRec.SetRange("License No.", "License No.");
                    if DeviceLinked_lRec.FindSet() then begin
                        repeat
                            DeviceLinked_lRec."Expiry Date" := CalcDate(EMSAPISetup_gRec."Dunning Days", DeviceLinked_lRec."Expiry Date");
                            DeviceLinked_lRec.Dunning := true;
                            DeviceLinked_lRec."Dunning Type" := DeviceLinked_lRec."Dunning Type"::Expiry;
                            DeviceLinked_lRec.Modify();
                        until DeviceLinked_lRec.Next() = 0;
                    end;
                    ModLicReq_lRec.Get("License Request"."No.");
                    ModLicReq_lRec."Old Expiry Date" := ModLicReq_lRec."Expiry Date";
                    ModLicReq_lRec."Expiry Date" := CalcDate(EMSAPISetup_gRec."Dunning Days", ModLicReq_lRec."Expiry Date");
                    ModLicReq_lRec."Dunning Type" := ModLicReq_lRec."Dunning Type"::Expiry;
                    ModLicReq_lRec.Dunning := true;
                    ModLicReq_lRec.Modify();
                    Clear(LiEmailSend_lCdu);
                    LiEmailSend_lCdu.SendDuningEmail_gFnc(ModLicReq_lRec, TRUE);
                    Message('Email Sent Successfully');
                end;
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                }
            }
        }
        actions
        {
            area(processing)
            {
                action(ActionName)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        EMSAPISetup_gRec: Record "EMS Setup";
}
