pageextension 52100 EMS_Customer extends "Customer Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Address & Contact")
        {
            group(License)
            {
                field("Organization ID"; Rec."Organization ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Organization ID';
                    ToolTip = 'Specifies the value Organization ID from Dozee SRPM Dashobard.';
                }
                field("Partner ID"; Rec."Partner ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not rec."Is Partner";
                    ToolTip = 'Specifies the partner/ distributor who is managing this customer.';

                    // trigger OnDrillDown()
                    // var
                    //     Customer: Record Customer;
                    //     CustomerList: Page "Customer List";
                    // begin
                    //     IF NOT Rec."Is Partner" then begin
                    //         Customer.Reset();
                    //         Customer.SetRange("Is Partner", True);
                    //         CustomerList.SetTableView(Customer);
                    //         CustomerList.LookupMode := true;
                    //         IF CustomerList.RunModal() = Action::LookupOK then Rec."Partner ID" := CustomerList.ReturnSchName();
                    //     end;
                    // End;
                }
                field("Is Partner"; Rec."Is Partner")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Partner ID" = '';
                    ToolTip = 'Specifies if the Customer is partner/distribotr wo will manage another customer.';
                }
                field("License Details"; Rec."License Details")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Available Licenses field.';

                    trigger OnDrillDown()
                    var
                        LicenseRequest_lPge: Page "Active Licenses";
                        LicenseRequest_lRec: Record "License Request";
                    begin
                        LicenseRequest_lRec.Reset();
                        LicenseRequest_lRec.SetRange("Customer No.", Rec."No.");
                        LicenseRequest_lRec.SetRange(Status, LicenseRequest_lRec.Status::Active);
                        LicenseRequest_lPge.SetTableView(LicenseRequest_lRec);
                        LicenseRequest_lPge.Editable(false);
                        LicenseRequest_lPge.RunModal();
                    end;
                }
                field("License Qty."; Rec."License Qty.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Active Devices field.';

                    trigger OnDrillDown()
                    var
                        DeviceLinke_lPge: Page "Dozee Devices";
                        DeviceLinked_lRec: Record "Dozee Device";
                    begin
                        DeviceLinked_lRec.Reset();
                        DeviceLinked_lRec.SetRange("Customer No.", REc."No.");
                        DeviceLinked_lRec.SetRange(Licensed, true);
                        DeviceLinke_lPge.SetTableView(DeviceLinked_lRec);
                        DeviceLinke_lPge.Editable(false);
                        DeviceLinke_lPge.RunModal();
                    end;
                }
                field("Total Devices."; Rec."Total Devices.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Total Devices field.';

                    trigger OnDrillDown()
                    var
                        DeviceLinke_lPge: Page "Dozee Devices";
                        DeviceLinked_lRec: Record "Dozee Device";
                    begin
                        DeviceLinked_lRec.Reset();
                        DeviceLinked_lRec.SetRange("Customer No.", REc."No.");
                        DeviceLinked_lRec.SetRange(Return, false);
                        DeviceLinke_lPge.SetTableView(DeviceLinked_lRec);
                        DeviceLinke_lPge.Editable(false);
                        DeviceLinke_lPge.RunModal();
                    end;
                }
                field("Partner Devices"; rec."Partner Devices")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = Partner;
                    ToolTip = 'Specifies the value of the Total Devices field.';

                    trigger OnDrillDown()
                    var
                        DeviceLinke_lPge: Page "Dozee Devices";
                        DeviceLinked_lRec: Record "Dozee Device";
                    begin
                        DeviceLinked_lRec.Reset();
                        DeviceLinked_lRec.SetRange("Source No.", Rec."No.");
                        DeviceLinked_lRec.SetRange(Return, false);
                        DeviceLinke_lPge.SetTableView(DeviceLinked_lRec);
                        DeviceLinke_lPge.Editable(false);
                        DeviceLinke_lPge.RunModal();
                    end;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        SetVisibilityControl();
    end;

    var
        Partner: Boolean;

    local procedure SetVisibilityControl()
    begin
        if rec."Is Partner" then
            Partner := true;
    end;
}