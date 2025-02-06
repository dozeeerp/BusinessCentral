table 51306 "HubSpot Contact"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; BigInteger)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "First Name"; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'First Name';
        }
        field(3; "Last Name"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
        }
        field(5; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }
        field(6; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = CustomerContent;
        }
        field(7; "Last Updated by BC"; DateTime)
        {
            Caption = 'Last Updated by BC';
            DataClassification = SystemMetadata;
        }
        field(8; "Contact SystemId"; Guid)
        {
            Caption = 'Contact SystemId';
            DataClassification = SystemMetadata;
        }
        field(9; "Contact No."; Code[20])
        {
            CalcFormula = lookup(Contact."No." where(SystemId = field("Contact SystemId")));
            Caption = 'Contact No.';
            FieldClass = FlowField;
        }
        field(10; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(11; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(12; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(13; City; Text[30])
        {
            Caption = 'City';
        }
        field(14; "Country/Region Code"; Text[20])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(15; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
        }
        field(16; "Salutation Code"; Code[10])
        {
            Caption = 'Salutation Code';
            TableRelation = Salutation;
        }
        field(17; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        field(18; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(19; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(20; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(21; "Financial Comm"; Boolean)
        {
            Caption = 'Finanacial Communication';
            DataClassification = CustomerContent;
        }
        field(22; "Company Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(contact.Name where("No." = field("Company No.")));
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