table 52105 LicenseCueTable
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PrimaryKey; Code[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; "License Request - Open"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Open | "Pending Approval")));
        }
        field(3; LiceseGenerated; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Released)));
        }
        field(4; ActiveLicense; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active)));
        }
        field(5; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Due Next Two Weeks Filter"; Date)
        {
            Caption = '15 Days Filter';
            FieldClass = FlowFilter;
        }
        field(7; "License Expiring Next Week"; Integer)
        {
            Caption = 'License Expiring Next Week';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "Renewal/Ext Lic No." = Const(''),
                                                        "Old Expiry Date" = field("Due Next Week Filter")));
            Editable = false;
        }
        field(8; "Active License MillionICU"; Integer)
        {
            Caption = 'Active Licesnes MillionICU';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = filter(MillionICU)));
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer Required.';
            ObsoleteTag = 'Clean soon';
        }
        field(9; "Active License Rental"; Integer)
        {
            Caption = 'Active Licesnes Rental';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Code" = filter('Rental')));
        }
        field(10; "Active License Demo"; Integer)
        {
            Caption = 'Active Licesnes Demo';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Code" = filter('Demo')));
        }
        field(11; "Active License by Partner"; Integer)
        {
            Caption = 'Active Licesnes by Partner';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "Partner ID" = filter(<> '')));
        }
        field(12; "License Expiring Next Two Week"; Integer)
        {
            Caption = 'License Expiring Next Week';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = filter(Commercial),
                                                        "Renewal/Ext Lic No." = Const(''),
                                                        "Old Expiry Date" = field("Due Next Two Weeks Filter")));
            Editable = false;
        }
        field(13; "Active License Demo MillionICU"; Integer)
        {
            Caption = 'Active Licesnes Demo MillionICU';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Code" = filter('DEMO MILLIONICU')));
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer Required.';
            ObsoleteTag = 'Clean soon';
        }
        field(23; "Licensed Devices"; Decimal)
        {
            Caption = 'Licensed Devices';
            // FieldClass = FlowField;
            // CalcFormula = count("Device linked to License" where(Licensed = const(true)));
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
        }
        field(24; "Active Devices MillionICU"; Decimal)
        {
            Caption = 'Active Devices MillionICU';
            // FieldClass = FlowField;
            // CalcFormula = count("Device linked to License" where(Licensed = const(true)));
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer Required.';
            ObsoleteTag = 'Clean soon';
        }
        field(25; "Active License Demo CDC"; Integer)
        {
            Caption = 'Active Licenses Demo CDC';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Code" = filter('DEMO CDC')));
        }
        field(26; "Licensed Devices Rental"; Decimal)
        {
            Caption = 'Rental Devices';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
        }
        field(27; "Licensed Devices Demo"; Decimal)
        {
            Caption = 'Demo Devices';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
        }
        field(28; "Licensed Devices - DemoMICU"; Decimal)
        {
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer Required.';
            ObsoleteTag = 'Clean soon';
        }
        field(29; "Licensed Devices DemoCDC"; Decimal)
        {
            Caption = 'Demo CDC Devices';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 0;
        }
        field(30; "Commercial License"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = filter(Commercial)));
        }
        field(31; "Dunning"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        Dunning = const(true)));
        }
        field(32; "Dunning close to expiry"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        Dunning = const(true),
                                                        "Expiry Date" = field("Due Next Week Filter")));
        }
        field(33; "Com Lic Exp Next Week"; Integer)
        {
            Caption = 'License Expiring Next Week';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = filter(Commercial),
                                                        "Renewal/Ext Lic No." = Const(''),
                                                        "Old Expiry Date" = field("Due Next Week Filter")));
            Editable = false;
        }
        field(34; "Active Licenses PayPerUse"; Integer)
        {
            Caption = 'Active licenses PayPerUse';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Code" = filter('PAYPERUSE')));
        }
        field(35; "Licensed Devices PayPerUse"; Decimal)
        {
            Caption = 'PayPerUse Devices';
            DecimalPlaces = 0 : 0;
        }
        field(36; "Active Licenses Prepaid"; Integer)
        {
            Caption = 'Active Licenses Prepaid';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = const(Commercial),
                                                        "Pre-paid" = const(true),
                                                        "License Code" = filter('PRE-PAID')));
        }
        field(37; "Active Licenses Postpaid"; Integer)
        {
            Caption = 'Active Licenses Postpaid';
            FieldClass = FlowField;
            CalcFormula = count("License Request" where(Status = filter(Active),
                                                        "License Type" = const(Commercial),
                                                        "License Code" = filter('POST-PAID')));
        }
        field(38; "Licensed Devices Prepaid"; Decimal)
        {
            Caption = 'Prepaid Devices';
            DecimalPlaces = 0 : 0;
        }
        field(39; "Licensed Devices Postpaid"; Decimal)
        {
            Caption = 'Postpaid Devices';
            DecimalPlaces = 0 : 0;
        }
        field(40; "Licensed Devices Partner"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Partner Devices';
            DecimalPlaces = 0 : 0;
        }
    }

    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }

    var
        LicReq: Record "License Request";


    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure ClacActiveDevices() Devices: Decimal
    var
        DeviceList: Record "Dozee Device";
    begin
        DeviceList.Reset();
        DeviceList.SetRange(Licensed, true);
        devices := DeviceList.Count()
    end;

    // procedure CalcActiveDevicesDMICU() DMICU: Decimal
    // var
    //     LicenseRequest: Record "License Request";
    //     DeviceList: Query "Devices List";
    // begin
    //     DeviceList.SetRange(LicenseTypeFilter,
    //                         LicenseRequest."License Type"::Demo);
    //     DeviceList.SetRange(LicenseCodeFilter,
    //                         'DEMO MILLIONICU');
    //     DeviceList.Open();
    //     if DeviceList.Read() then
    //         DMICU := DeviceList.Noofdevicesassigned;
    //     DeviceList.Close();
    // end;

    // procedure CalcActiveDevicesDCDC() DCDC: Decimal
    // var
    //     LicenseRequest: Record "License Request";
    // begin
    //     DCDC := 0;
    //     LicenseRequest.Reset();
    //     LicenseRequest.SetRange(Status, LicenseRequest.Status::Active);
    //     LicenseRequest.SetRange("License Type", LicenseRequest."License Type"::Demo);
    //     LicenseRequest.SetRange("License Code", 'DEMO CDC');
    //     if LicenseRequest.FindSet() then
    //         repeat
    //             LicenseRequest.CalcFields("No of devices assigned");
    //             DCDC += LicenseRequest."No of devices assigned";
    //         Until LicenseRequest.Next() = 0;
    // end;

    procedure CalcActiveDevicesCommercial()
    var
        LicenseRequest: Record "License Request";
    begin
        Rec."Licensed Devices Prepaid" := 0;
        Rec."Licensed Devices Postpaid" := 0;
        Rec."Licensed Devices Rental" := 0;
        Rec."Licensed Devices PayPerUse" := 0;

        LicenseRequest.Reset();
        LicenseRequest.SetRange(Status, LicenseRequest.Status::Active);
        LicenseRequest.SetRange("License Type", LicenseRequest."License Type"::Commercial);
        LicenseRequest.SetRange("License Code", 'PRE-PAID');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                rec."Licensed Devices Prepaid" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;

        LicenseRequest.SetRange("License Code", 'POST-PAID');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                rec."Licensed Devices Postpaid" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;

        LicenseRequest.SetRange("License Code", 'RENTAL');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                rec."Licensed Devices Rental" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;

        LicenseRequest.SetRange("License Code", 'PAYPERUSE');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                Rec."Licensed Devices PayPerUse" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;
    end;

    procedure CalcActiveDevicesDemo()
    var
        LicenseRequest: Record "License Request";
    begin
        Rec."Licensed Devices Demo" := 0;
        Rec."Licensed Devices DemoCDC" := 0;

        LicenseRequest.Reset();
        LicenseRequest.SetRange(Status, LicenseRequest.Status::Active);
        LicenseRequest.SetRange("License Type", LicenseRequest."License Type"::Demo);
        LicenseRequest.SetRange("License Code", 'DEMO');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                Rec."Licensed Devices Demo" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;

        LicenseRequest.SetRange("License Code", 'DEMO CDC');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                Rec."Licensed Devices DemoCDC" += LicenseRequest."No of devices assigned";
            Until LicenseRequest.Next() = 0;
    end;

    procedure CalcActiveDevicePartner()
    var
        LicenseRequest: Record "License Request";
    begin
        Rec."Licensed Devices Partner" := 0;

        LicenseRequest.Reset();
        LicenseRequest.SetRange(Status, LicenseRequest.Status::Active);
        LicenseRequest.SetFilter("Partner ID", '<>%1', '');
        if LicenseRequest.FindSet() then
            repeat
                LicenseRequest.CalcFields("No of devices assigned");
                rec."Licensed Devices Partner" += LicenseRequest."No of devices assigned";
            until LicenseRequest.Next() = 0;
    end;

    procedure DrillDownActiveDevices()
    var
        DeviceList: Record "Dozee Device";
    begin
        DeviceList.SetRange(Licensed, true);
        Page.Run(page::"Dozee Devices", DeviceList);
    end;

    // procedure DrillDownActiveDevicesMICU()
    // var
    //     LicenseReq: Record "License Request";
    // begin
    //     LicenseReq.SetFilter("License Type", '%1', LicenseReq."License Type"::MillionICU);
    //     Page.Run(page::"Active Licenses", LicenseReq);
    // end;
}