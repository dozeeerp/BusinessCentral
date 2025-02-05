table 51302 "Material Requsition Buffer"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(2; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(3; Type; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = Item,"GL";
        }
        field(4; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Warehouse"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(6; "Self"; Decimal)
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