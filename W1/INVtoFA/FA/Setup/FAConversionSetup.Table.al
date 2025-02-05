namespace TSTChanges.FA.Setup;

using Microsoft.Inventory.Location;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.FAItem;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;
using Microsoft.FixedAssets.FixedAsset;

table 51206 "FA Conversion Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Conversion Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Conversion Order No.';
            TableRelation = "No. Series";
        }
        field(3; "Posted Conversion Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Posted Conversion Order No.';
            TableRelation = "No. Series";
        }
        field(4; "Default Location for Orders"; Code[10])
        {
            Caption = 'Default Location for Orders';
            TableRelation = Location;
        }
        field(5; "Inventory Adjmt. Account"; Code[20])
        {
            Caption = 'Inventory Adjmt. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Inventory Adjmt. Account");
            end;
        }
        field(6; "Inventory Capitalize Account"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Inventory Capitalize Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Inventory Capitalize Account");
            end;
        }
        field(8; "FA Transfer Order Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            AccessByPermission = TableData "FA Transfer Header" = R;
            Caption = 'FA Transfer Order Nos.';
            TableRelation = "No. Series";
        }
        field(9; "Posted Transfer Shpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "FA Transfer Header" = R;
            Caption = 'Posted Transfer Shpt. Nos.';
            TableRelation = "No. Series";
        }
        field(10; "Posted Transfer Rcpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "FA Transfer Header" = R;
            Caption = 'Posted Transfer Rcpt. Nos.';
            TableRelation = "No. Series";
        }
        field(11; "FA Item Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            AccessByPermission = TableData "FA Item" = R;
            Caption = 'FA Item Nos.';
            TableRelation = "No. Series";
        }
        field(12; "Use Diffrent No Series for FA"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Use Diffrent No Series for FA';
        }
        field(13; "FA Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Nos.';
            TableRelation = "No. Series";
        }
        field(14; "Posted Direct Trans. Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Posted Direct Trans. Nos.';
            TableRelation = "No. Series";
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

    procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;
}