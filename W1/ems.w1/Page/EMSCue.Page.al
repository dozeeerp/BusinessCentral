page 52110 LicesneCuePage
{
    Caption = 'License';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = LicenseCueTable;

    layout
    {
        area(Content)
        {
            cuegroup("Ongoing LicenseRequest")
            {
                Caption = 'Ongoing License Requests';
                field(LicesneRequestOpen; rec."License Request - Open")
                {
                    Caption = 'License Requests - Open';
                    ApplicationArea = ALL;
                    DrillDownPageId = "License Requests";
                    ToolTip = 'Specifies license Requests that are not yet Activated.';
                }
                field(LiceseGenerated; rec.LiceseGenerated)
                {
                    Caption = 'Licenses Generated';
                    ApplicationArea = All;
                    DrillDownPageId = "License Requests";
                    ToolTip = 'Specifies license requests that are approved and not yet activated';
                }
            }
            cuegroup("Licenses Expriry")
            {
                Caption = 'Licenses Close to Expiry';
                field("License Exp. within 7 days"; rec."License Expiring Next Week")
                {
                    Caption = 'Licenses Expiring within 7 days';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the number of the licenses expiring within 7 days.';
                }
                field("Com Lic Exp Next Week"; rec."Com Lic Exp Next Week")
                {
                    Caption = 'Com Lic Exp within 7 days';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the number of the commercial licenses expiring within 7 days.';
                }
                field("License Exp. within 15 days"; rec."License Expiring Next Two Week")
                {
                    Caption = 'Com Lic Exp within 15 days';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the number of the licenses expiring within 15 days';
                }
            }
            cuegroup("License Dunning")
            {
                field(Dunning; rec.Dunning)
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                }
                field("Dunning close to expiry"; rec."Dunning close to expiry")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                }
            }
            cuegroup("Active Licenses")
            {
                Caption = 'Active Licenses';
                field(ActiveLicense; rec.ActiveLicense)
                {
                    Caption = 'Active Licenses';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies licenses those are active.';
                }
                field("Active License Rental"; rec."Active License Rental")
                {
                    Caption = 'Active Licenses Rental';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies licenses those are active and rental.';
                }
                field("Active Licenses PayPerUse"; Rec."Active Licenses PayPerUse")
                {
                    Caption = 'Active Licenses PayPerUse';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the active licenses running in Pay Per Use.';
                }
                field("Active Licenses Postpaid"; Rec."Active Licenses Postpaid")
                {
                    Caption = 'Active Licenses Postpaid';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the active licenses running in Postpaid';
                }
                field("Active Licenses Prepaid"; Rec."Active Licenses Prepaid")
                {
                    Caption = 'Active licenses Prepaid';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the active licenses running in Prepaid.';
                }
                field("Active License Demo"; rec."Active License Demo")
                {
                    Caption = 'Active Licenses Demo';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the active licenses running in Demo.';
                }
                field("Active License Demo CDC"; rec."Active License Demo CDC")
                {
                    Caption = 'Active Licenses Demo-CDC';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specified the active licenses running in Demo CDC';
                }
                // field("Active License MillionICU"; rec."Active License MillionICU")
                // {
                //     Caption = 'Active Licenses MillionICU';
                //     ApplicationArea = All;
                //     DrillDownPageId = "Active Licenses";
                //     ToolTip = 'Specifies licesnes those are active and MillionICU.';
                // }
                // field("Active License Demo MillionICU"; rec."Active License Demo MillionICU")
                // {
                //     Caption = 'Active Licenses Demo-MICU';
                //     ApplicationArea = All;
                //     DrillDownPageId = "Active Licenses";
                //     ToolTip = 'Specifies the active licenses running in Demo MillionICU.';
                // }                
                field("Active License by Partner"; rec."Active License by Partner")
                {
                    Caption = 'Active Licenses by Partner';
                    ApplicationArea = All;
                    DrillDownPageId = "Active Licenses";
                    ToolTip = 'Specifies the active licenses managed by partner.';
                }
            }
            cuegroup("L&icensed Devices")
            {
                // CuegroupLayout = Wide;
                Caption = 'Licensed Devices';
                field("Licensed Devices"; rec."Licensed Devices")
                {
                    Caption = 'Licensed Devices';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageId = "Dozee Devices";
                    ToolTip = 'Specifies the total active (Licensed) devices.';

                    trigger OnDrillDown()
                    begin
                        rec.DrillDownActiveDevices();
                    end;
                }
                field("Licensed Devices Rental"; rec."Licensed Devices Rental")
                {
                    ApplicationArea = All;
                }
                field("Licensed Devices PayPerUse"; Rec."Licensed Devices PayPerUse")
                {
                    Caption = 'PayPerUse Devices';
                    ApplicationArea = Basic, Suite;
                }
                field("Licensed Devices Postpaid"; Rec."Licensed Devices Postpaid")
                {
                    Caption = 'Postpaid Devices';
                    ApplicationArea = Basic, Suite;
                }
                field("Licensed Devices Prepaid"; Rec."Licensed Devices Prepaid")
                {
                    Caption = 'Prepaid Devices';
                    ApplicationArea = Basic, Suite;
                }
                // field("Active Devices - MillionICU"; rec."Active Devices MillionICU")
                // {
                //     Caption = 'Active Devices - MillionICU';
                //     ApplicationArea = All;
                //     // DrillDownPageId = "Device linked to License list";

                //     // trigger OnDrillDown()
                //     // begin
                //     //     rec.DrillDownActiveDevicesMICU();
                //     // end;
                // }
                // field("Active Devices - DemoMICU"; rec."Active Devices - DemoMICU")
                // {
                //     ApplicationArea = All;
                // }
                field("Licensed Devices Demo"; rec."Licensed Devices Demo")
                {
                    ApplicationArea = All;
                }
                field("Licensed Devices DemoCDC"; rec."Licensed Devices DemoCDC")
                {
                    ApplicationArea = All;
                }
                field("Licensed Devices Partner"; Rec."Licensed Devices Partner")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the licesed devices managed by partner.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = All;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        rec.Reset;
        if not rec.get then begin
            rec.Init();
            rec.Insert();
            Commit();
        end;
        rec.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<0D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        rec.SetFilter("Due Next Two Weeks Filter", '%1..%2', CalcDate('<0D>', WorkDate()), CalcDate('<2W+1D>', WorkDate()));
    end;

    trigger OnAfterGetRecord()
    begin
        rec."Licensed Devices" := rec.ClacActiveDevices();
        Rec.CalcActiveDevicesCommercial();
        Rec.CalcActiveDevicesDemo();
        Rec.CalcActiveDevicePartner();
    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
}