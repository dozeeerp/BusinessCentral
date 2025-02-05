namespace TSTChanges.FA.History;

using TSTChanges.FA.FAItem;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.AuditCodes;
using System.Security.AccessControl;
using TSTChanges.FA.Tracking;
using Microsoft.Inventory.Location;

table 51207 "Posted Conversion Header"
{
    DataClassification = CustomerContent;
    Caption = 'Posted Conversion Header';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "FA Item No."; Code[20])
        {
            Caption = 'FA Item No.';
            DataClassification = CustomerContent;
            TableRelation = "FA Item";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(5; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(7; "Due Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Due Date';
        }
        field(8; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';
        }
        field(9; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(10; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(11; "Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Remaining Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(13; "Remaining Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(14; "Converted Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Converted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; "Converted Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Converted Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Quantity to Convert"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity to Convert';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(17; "Quantity to Convert (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity to Convert (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Posting No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Posting No.';
            Editable = false;
        }
        field(20; "Qty. per Unit of Measure"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(23; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(24; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(25; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(28; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "FA Item Variant".Code where("Item No." = field("FA Item No."),
                                                       Code = field("Variant Code"));
        }
        field(100; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(101; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(102; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(103; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
        }
        field(104; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.")
        {
        }
        key(Key3; "Posting Date")
        {
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

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "FA Item Tracking Doc. Mgmt";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Posted Conversion Header", 0, "No.", '', 0, 0);
    end;

    procedure Navigate()
    var
        Navigate: Page Navigate;
    begin
        Navigate.SetDoc("Posting Date", "No.");
        Navigate.Run();
    end;
}