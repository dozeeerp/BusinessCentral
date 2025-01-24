table 52100 "EMS Setup"
{
    DataClassification = CustomerContent;
    LookupPageId = "Ems Setup";
    DrillDownPageId = "Ems Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "License Request Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'License Request Nos.';
            TableRelation = "No. Series";
        }
        field(3; "License Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'License Nos.';
            TableRelation = "No. Series";
        }
        field(4; "Base URL"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Device Activate URL';
        }
        field(5; "API Key"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'API Key';
        }
        field(6; "Enabled"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
        field(7; "Dunning Days"; DateFormula)
        {
            DataClassification = CustomerContent;
            Caption = 'Dunning Days';
        }
        field(8; "Email Notofication"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Email Notification';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

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

}