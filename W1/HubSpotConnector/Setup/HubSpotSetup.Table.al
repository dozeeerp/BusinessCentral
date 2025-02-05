namespace TST.Hubspot.Setup;

using Microsoft.Inventory.Location;
using TST.Hubspot.Company;

table 51300 "Hubspot Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Primary Key';
        }
        field(2; "Access Token"; Text[500])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Base Url"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Default Warehouse"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Demo Location"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(6; "Rental Location"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(7; "Employee Location"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Location";
        }
        field(8; "AssociationID Ticket to Device"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'AssociationId Ticket to Device';
        }
        field(9; "Last Sync Time"; DateTime)
        {
            Caption = 'Last Sync Time';
            DataClassification = SystemMetadata;
        }
        field(10; "Company Import From Hubspot"; Enum "Hubspot Company Import Range")
        {
            Caption = 'Company Import from Hubspot';
            DataClassification = CustomerContent;
            InitValue = WithOrderImport;
        }
        field(11; "Can Update Hubspot Companies"; Boolean)
        {
            Caption = 'Can Update Hubspot Companies';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Can Update Hubspot Companies" then
                    "Hubspot Can Update Companies" := false;
            end;
        }
        field(12; "Hubspot Can Update Companies"; Boolean)
        {
            Caption = 'Hubspot Can Update Companies';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Hubspot Can Update Companies" then
                    "Can Update Hubspot Companies" := false;
            end;
        }
        field(13; "Create Cutomer"; Enum "Hubspot Company Import Range")
        {
            Caption = 'Create Customer';
            DataClassification = CustomerContent;
        }
        field(14; "Business Unit"; Text[50])
        {
            DataClassification = ToBeClassified;
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

    // internal procedure SetLastSyncTime()//Type: Enum "Shpfy Synchronization Type")
    // begin
    //     SetLastSyncTime(Type, CurrentDateTime);
    // end;

    internal procedure SetLastSyncTime(//Type: Enum "Shpfy Synchronization Type"; 
        ToDateTime: DateTime)
    var
    // SynchronizationInfo: Record "Shpfy Synchronization Info";
    // ShopCode: Code[20];
    begin
        // if Type = "Shpfy Synchronization Type"::Orders then
        //     ShopCode := Format(Rec."Shop Id")
        // else
        //     ShopCode := Rec.Code;
        // if SynchronizationInfo.Get(ShopCode, Type) then begin
        //     SynchronizationInfo."Last Sync Time" := ToDateTime;
        //     SynchronizationInfo.Modify();
        // end else begin
        //     Clear(SynchronizationInfo);
        //     SynchronizationInfo."Shop Code" := ShopCode;
        //     SynchronizationInfo."Synchronization Type" := Type;
        //     SynchronizationInfo."Last Sync Time" := ToDateTime;
        //     SynchronizationInfo.Insert();
        // end;
        "Last Sync Time" := ToDateTime;
    end;
}