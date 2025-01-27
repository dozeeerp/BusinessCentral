page 52104 "Dozee Devices"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Dozee Device";
    SourceTableView = where(Return = const(false));
    CardPageId = "Dozee Device";
    DataCaptionFields = "Serial No.";
    RefreshOnActivate = true;
    Editable = false;
    Caption = 'Dozee Device';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Serial No. of the device.';
                }
                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Item No of the device.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Item Description of the device.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant field.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Source No. field.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Customer Name field.';
                }
                field("Partner No."; Rec."Partner No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Partner No. field.';
                }
                field("Org ID"; Rec."Org ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Org ID field.';
                }

                field("Device ID"; Rec."Device ID")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the ID used by sanes.';
                }
                field(Return; Rec.Return)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Return field.';
                }
                field(Licensed; Rec.Licensed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Licensed field.';
                    Editable = false;
                    // trigger OnValidate()
                    // var
                    //     LicenseRequest: record "License Request";
                    //     DeviceLinkedToLicense_lRec: Record "Dozee Device";
                    //     DeviceAttachError: Label 'No. of device attached(%1) exceeds %2(%3) defined on %4';
                    //     EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
                    //     Cnt_lInt: Integer;
                    // begin
                    //     IF Rec.Licensed then begin
                    //         LicenseRequest.Reset();
                    //         LicenseRequest.SetRange("No.", SinCodeeunit.ReturnSchName());
                    //         IF LicenseRequest.FindFirst() then begin
                    //             IF LicenseRequest."Expiry Date" < Today then
                    //                 Error('You cannot link License: %1 to device as it is already expired', LicenseRequest."License No.");
                    //             DeviceLinkedToLicense_lRec.Reset();
                    //             DeviceLinkedToLicense_lRec.SetRange("License No.", LicenseRequest."License No.");
                    //             DeviceLinkedToLicense_lRec.SetFilter("Entry No.", '<>%1', Rec."Entry No.");
                    //             IF DeviceLinkedToLicense_lRec.FindFirst() then
                    //                 Cnt_lInt := DeviceLinkedToLicense_lRec.Count;
                    //             IF (Cnt_lInt + 1) > LicenseRequest."License Qty." then
                    //                 Error(DeviceAttachError, (Cnt_lInt + 1),
                    //                                 LicenseRequest.FieldCaption("License Qty."), LicenseRequest."License Qty.", LicenseRequest."License No.");
                    //             Rec.Validate("License No.", LicenseRequest."License No.");
                    //             EMSAPIMgt_lCdu.SendDeviceLicenseStatus(Rec);
                    //         end;
                    //     end else begin
                    //         Rec."License No." := '';
                    //         Rec."Activation Date" := 0D;
                    //         Rec."Expiry Date" := 0D;
                    //         EMSAPIMgt_lCdu.SendDeviceLicenseStatus(Rec);
                    //     end;
                    // end;
                }
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License No. field.';
                }
                field("Activation Date"; Rec."Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Activation Date field.';
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiry Date field.';
                }
                field(Expired; Rec.Expired)
                {
                    ApplicationArea = All;
                }
                field(Terminated; Rec.Terminated)
                {
                    ApplicationArea = All;
                }
                field(Dunning; Rec.Dunning)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning field.';
                }
                field("Dunning Type"; Rec."Dunning Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning Type field.';
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Installation Date field.';
                }
                field("Warranty Start Date"; Rec."Warranty Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warranty Start Date field.';
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warranty End Date field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Attach License to Device")
            {
                ToolTip = 'Executes the ActionName action.';
                Caption = 'Attach License to Device';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Apply;
                Enabled = Licensed_gBln;
                ApplicationArea = All;

                trigger OnAction();
                var
                    DeviceLinkedToLicense: Record "Dozee Device";
                    LicenseRequest_lRec: Record "License Request";
                    AlreadyDeviceLinkedToLicense: Record "Dozee Device";
                    ModDeviceLinkedToLicense: Record "Dozee Device";
                    EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
                    Cnt_lInt: Integer;
                    DeviceAttachError: Label 'No. of device attached(%1) exceeds %2(%3) defined on %4';
                    ExpiredLicensErr: Label 'You cannot link License: %1 to device as it is already expired';
                    BlankGUID: Guid;
                    ParameterBody: JsonArray;
                begin
                    Clear(ParameterBody);
                    CurrPage.SetSelectionFilter(DeviceLinkedToLicense);
                    DeviceLinkedToLicense.SetRange(Licensed, false);
                    IF DeviceLinkedToLicense.IsEmpty then Error('No entries selected to License.');
                    LicenseRequest_lRec.Reset();
                    LicenseRequest_lRec.SetRange("No.", SinCodeeunit.ReturnSchName());
                    LicenseRequest_lRec.FindFirst();
                    IF LicenseRequest_lRec."Expiry Date" < Today then Error(ExpiredLicensErr, LicenseRequest_lRec."License No.");
                    Cnt_lInt := 0;
                    AlreadyDeviceLinkedToLicense.Reset();
                    AlreadyDeviceLinkedToLicense.SetRange(Licensed, true);
                    AlreadyDeviceLinkedToLicense.SetRange("License No.", LicenseRequest_lRec."License No.");
                    Cnt_lInt := AlreadyDeviceLinkedToLicense.Count;
                    IF DeviceLinkedToLicense.FindSet() then begin
                        Cnt_lInt += DeviceLinkedToLicense.Count;
                        repeat
                            IF Cnt_lInt > LicenseRequest_lRec."License Qty." then Error(DeviceAttachError, (Cnt_lInt), LicenseRequest_lRec.FieldCaption("License Qty."), LicenseRequest_lRec."License Qty.", LicenseRequest_lRec."License No.");
                            ModDeviceLinkedToLicense.Get(DeviceLinkedToLicense."Entry No.");
                            IF ModDeviceLinkedToLicense."Org ID" = BlankGUID then ModDeviceLinkedToLicense."Org ID" := LicenseRequest_lRec."Organization ID";
                            EMSAPIMgt_lCdu.GetDeviceLicenseId(ModDeviceLinkedToLicense);
                            ModDeviceLinkedToLicense.Validate(Licensed, true);
                            ModDeviceLinkedToLicense.Validate("License No.", LicenseRequest_lRec."License No.");
                            ModDeviceLinkedToLicense.Dunning := LicenseRequest_lRec.Dunning;
                            ModDeviceLinkedToLicense."Dunning Type" := LicenseRequest_lRec."Dunning Type";
                            //T34311-NS
                            IF LicenseRequest_lRec."Organization ID" <> ModDeviceLinkedToLicense."Org ID" then ModDeviceLinkedToLicense."Org ID" := LicenseRequest_lRec."Organization ID";
                            //T34311-NE
                            ModDeviceLinkedToLicense.Modify();
                            ActiveLicMgt.InsertArchiveDeviceLedgEntry(ModDeviceLinkedToLicense);
                            EMSAPIMgt_lCdu.SendDeviceLicenseStatusBody(ParameterBody, ModDeviceLinkedToLicense);
                        until DeviceLinkedToLicense.Next() = 0;
                        EMSAPIMgt_lCdu.SendDeviceLicenseStatusReq(ParameterBody);
                    end;
                    OnAfterAttacheLicense();
                end;
            }
            action("Detach License from Device")
            {
                ToolTip = 'Executes the ActionName action.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Apply;
                Enabled = Licensed_gBln;
                ApplicationArea = All;

                trigger OnAction()
                var
                    DeviceLinkedToLicense: Record "Dozee Device";
                    ModDeviceLinkedToLicense: Record "Dozee Device";
                    EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
                    ParameterBodyArray: JsonArray;
                begin
                    Clear(ParameterBodyArray);
                    CurrPage.SetSelectionFilter(DeviceLinkedToLicense);
                    DeviceLinkedToLicense.SetRange(Licensed, true);
                    IF DeviceLinkedToLicense.IsEmpty then Error('No entries selected.');
                    IF DeviceLinkedToLicense.FindSet() then begin
                        repeat
                            ModDeviceLinkedToLicense.Get(DeviceLinkedToLicense."Entry No.");
                            ModDeviceLinkedToLicense."License No." := '';
                            ModDeviceLinkedToLicense.Licensed := false;
                            ModDeviceLinkedToLicense."Activation Date" := 0D;
                            ModDeviceLinkedToLicense."Expiry Date" := 0D;
                            IF ModDeviceLinkedToLicense.Dunning then begin
                                ModDeviceLinkedToLicense.Dunning := false;
                                ModDeviceLinkedToLicense."Dunning Type" := ModDeviceLinkedToLicense."Dunning Type"::" ";
                            end;
                            ModDeviceLinkedToLicense.Modify();
                            ActiveLicMgt.InsertArchiveDeviceLedgEntry(ModDeviceLinkedToLicense);
                            EMSAPIMgt_lCdu.ExpireTerminateDeviceLicenseBody(DeviceLinkedToLicense, ParameterBodyArray, 0);
                        until DeviceLinkedToLicense.Next() = 0;
                        EMSAPIMgt_lCdu.ExpireTerminateDeviceLicenseReq(ParameterBodyArray);
                    end;
                end;
            }
            action("Change Customer")
            {
                ToolTip = 'Changes the Customer on the Device';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Customer;
                Enabled = not Licensed_gBln;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Customer: Record Customer;
                    DeviceLinkedToLicense: Record "Dozee Device";
                    PartnerNo: Code[20];
                    LicensedDevicesErr: Label 'Licensed Devices are not allowed for Change Customer action.';
                    CustomerNoEmptyErr: Label 'Customer No. should not be empty for Change Customer action.';
                    DifferentCustomerNoErr: Label 'Customer No. should be same on all the selected devices';
                    CustomerChangedLbl: Label 'Customer is changed for selected devices to %1 - %2', Comment = '%1 = New Customer No., %2 = New Customer Name';
                    IsPartnerErr: Label 'Change of Customer is only allowed from Partner to Customer. %1 is not a Partner.', Comment = '%1 = Customer No.';
                begin
                    DeviceLinkedToLicense.Reset();
                    CurrPage.SetSelectionFilter(DeviceLinkedToLicense);
                    DeviceLinkedToLicense.SetRange(Licensed, true);
                    if not DeviceLinkedToLicense.IsEmpty then Error(LicensedDevicesErr);
                    DeviceLinkedToLicense.SetRange(Licensed);
                    DeviceLinkedToLicense.SetRange("Customer No.", '');
                    if not DeviceLinkedToLicense.IsEmpty then Error(CustomerNoEmptyErr);
                    DeviceLinkedToLicense.SetFilter("Customer No.", '<>%1', Rec."Customer No.");
                    if not DeviceLinkedToLicense.IsEmpty() then Error(DifferentCustomerNoErr);
                    DeviceLinkedToLicense.SetRange("Customer No.");
                    Customer.Reset();
                    if Customer.Get(Rec."Customer No.") then if not Customer."Is Partner" then Error(IsPartnerErr, Customer."No.");
                    PartnerNo := Customer."No.";
                    Clear(Customer);
                    Customer.SetRange("Partner ID", PartnerNo);
                    if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then begin
                        DeviceLinkedToLicense.ModifyAll("Customer No.", Customer."No.");
                        DeviceLinkedToLicense.ModifyAll("Customer Name", Customer.Name);
                        DeviceLinkedToLicense.ModifyAll("Partner No.", PartnerNo);
                        Message(CustomerChangedLbl, Customer."No.", Customer.Name);
                    end;
                    CurrPage.Update();
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Licensed_gBln := false;
    end;

    trigger OnAfterGetRecord()
    begin
        Licensed_gBln := (SinCodeeunit.ReturnSchName() <> '');
    end;

    trigger OnClosePage()
    begin
        SinCodeeunit.ClearSchName();
    end;

    var
        Licensed_gBln: Boolean;
        SinCodeeunit: Codeunit EMS_SinCodeeunit;
        ActiveLicMgt: Codeunit "Active License Mgt.";

    [IntegrationEvent(false, false)]
    local procedure OnAfterAttacheLicense()
    begin
    end;
}
