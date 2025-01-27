tableextension 52100 "EMS Customer" extends Customer
{
    fields
    {
        // Add changes to table fields here
        field(52100; "Organization ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Organization ID';
        }
        field(52101; "Partner ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Partner ID';
        }
        field(52102; "Is Partner"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Partner';
        }
        field(52103; "License Details"; Integer)
        {
            FieldClass = FlowField;
            Caption = 'Available Licenses';
            CalcFormula = sum("License Request"."License Qty." where("Customer No." = field("No."), Status = const(Active)));
            //Editable = false;
        }
        field(52104; "License Qty."; Integer)
        {
            FieldClass = FlowField;
            Caption = 'Active Devices';
            CalcFormula = count("Dozee Device" where("Customer No." = field("No."), Licensed = const(true)));
            //Editable = false;
        }
        field(52105; "Total Devices."; Integer)
        {
            FieldClass = FlowField;
            Caption = 'Total Devices';
            CalcFormula = count("Dozee Device" where("Customer No." = field("No."), Return = const(false)));
            //Editable = false;
        }
        field(52106; "Partner Devices"; Integer)
        {
            Caption = 'Partner Devices';
            FieldClass = FlowField;
            CalcFormula = count("Dozee Device" where("Source No." = field("No."), Return = const(false)));
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}