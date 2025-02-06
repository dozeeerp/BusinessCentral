namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;

table 51305 "Hubspot Company"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; BigInteger)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[500])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(4; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }

        field(5; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = CustomerContent;
        }
        field(6; "Last Updated by BC"; DateTime)
        {
            Caption = 'Last Updated by BC';
            DataClassification = SystemMetadata;
        }

        field(7; "Customer SystemId"; Guid)
        {
            Caption = 'Customer SystemId';
            DataClassification = SystemMetadata;
        }
        field(8; "Customer No."; Code[20])
        {
            CalcFormula = lookup(Customer."No." where(SystemId = field("Customer SystemId")));
            Caption = 'Customer No.';
            FieldClass = FlowField;
        }
        field(9; Address; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Address 2"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(11; City; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Country/Region"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(13; State; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(14; ZIP; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(15; "KAM Onwer"; BigInteger)
        {
            DataClassification = ToBeClassified;
        }
        field(16; "Customer Type"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(17; Domain; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(18; "Primary Contact"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(19; "Primary Contact No"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(20; "Sales Onwer"; BigInteger)
        {
            DataClassification = CustomerContent;
        }
        field(21; Phone; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(22; "Mobile Phone No"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(23; "Currency Code"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(24; "GST Registration No"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(25; "P.A.N. No"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(26; "Zone"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(27; Type; Code[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Id)
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