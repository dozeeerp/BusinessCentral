table 52104 "Archive Device Led. Entry"
{
    DataClassification = ToBeClassified;
    Caption = 'Archive Device Ledger Entry';
    LookupPageId = "Archive Device Ledger Entry";
    DrillDownPageId = "Archive Device Ledger Entry";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(4; "Customer No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(5; "Customer Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(6; "Partner No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(7; "Org ID"; Guid)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(8; "License No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(9; "Item No"; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(10; "Item Description"; Text[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; Variant; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(12; "Serial No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(13; "Installation Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(14; "Warranty Start Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(15; "Warranty End Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(16; "Activation Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(17; "Expiry Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(18; "Licensed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(19; Return; Boolean)
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(20; "API Data Sent"; Boolean)
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(21; "Item Ledger Entry No."; Integer)
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(22; "Transaction No."; Code[20])
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(23; "Transaction Type"; Code[20])
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(24; "Device ID"; Guid)
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(25; "Expired"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(26; "Terminated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(27; "Source Entry No."; Integer)
        {
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(50000; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
    var
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
