table 52102 "License Type"
{
    DataClassification = ToBeClassified;
    DrillDownPageId = "License Type";
    LookupPageId = "License Type";

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; Name; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(3; Blocked; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(4; "License Type"; Enum "License Type")
        {
            Caption = 'License Type';
        }
        field(5; "Pre-paid"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(6; Dunning; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        //TestField("License Type");
    end;
}
