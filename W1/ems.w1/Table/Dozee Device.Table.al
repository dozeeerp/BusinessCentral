table 52103 "Dozee Device"
{
    DataClassification = CustomerContent;
    Caption = 'Dozee Device';
    DrillDownPageId = "Dozee Devices";
    LookupPageId = "Dozee Devices";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Customer;
        }
        field(5; "Customer Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Customer.Name;
        }
        field(6; "Partner No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Customer;
        }
        field(7; "Org ID"; Guid)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; "License No."; Code[20])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                LicenseRequest: Record "License Request";
            begin
                IF Rec."License No." <> '' then begin
                    LicenseRequest.Reset();
                    LicenseRequest.SetRange("License No.", Rec."License No.");
                    IF LicenseRequest.FindFirst() then begin
                        Rec."Activation Date" := LicenseRequest."Activation Date";
                        Rec."Expiry Date" := LicenseRequest."Expiry Date";
                    end;
                end
                else begin
                    Rec."Activation Date" := 0D;
                    Rec."Expiry Date" := 0D;
                end;
            end;
        }
        field(9; "Item No"; Code[20])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                // ServiceItem.Reset();
                // ServiceItem.SetRange("Item No.", Rec."Item No");
                // IF ServiceItem.FindFirst() Then begin
                //     Rec."Warranty Start Date" := ServiceItem."Warranty Starting Date (Labor)";
                //     Rec."Warranty End Date" := ServiceItem."Warranty Ending Date (Labor)";
                //     rec."Installation Date" := ServiceItem."Installation Date";
                // end;
            end;
        }
        field(10; "Item Description"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(11; Variant; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Serial No."; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(13; "Installation Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "Warranty Start Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "Warranty End Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "Activation Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; "Expiry Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "Licensed"; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF Licensed Then begin
                    Expired := false;
                    Terminated := false;
                End;
            end;
        }
        field(19; Return; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(20; "API Data Sent"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(21; "Item Ledger Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(22; "Transaction No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(23; "Transaction Type"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(24; "Device ID"; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(25; "Expired"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "Terminated"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(100; Dunning; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(101; "Dunning Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = " ",Expiry,"Invoice Due Date";
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
