table 51303 "Device Buffer"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;

        }
        field(2; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Variant Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Lot No."; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Serial No."; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(7; "To Location"; Text[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
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

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}