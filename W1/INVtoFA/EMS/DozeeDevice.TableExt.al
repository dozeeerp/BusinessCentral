namespace TSTChanges.EMS;

using Microsoft.Inventory.Ledger;
using TSTChanges.FA.Ledger;

tableextension 51204 TST_DozeeDevice extends "Dozee Device"
{
    fields
    {
        // Add changes to table fields here
        field(51000; Type; Enum "Dozee Device Type")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51001; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
            Editable = false;
        }
        field(51002; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51003; "Returned ILE No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51004; "Returned Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        modify("Item Ledger Entry No.")
        {
            TableRelation = if (Type = const(Item)) "Item Ledger Entry"
            else
            if (Type = const(Asset)) "FA Item ledger Entry";
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

    trigger OnInsert()
    var
        ILE: Record "Item Ledger Entry";
    begin
        if Type = Type::" " then begin
            Type := Type::Item;
            ILE.Get("Item Ledger Entry No.");
            "Posting Date" := ILE."Posting Date";
        end;
    end;
}