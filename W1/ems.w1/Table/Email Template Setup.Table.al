Table 52107 "Email Template Setup"
{
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Editable = false;
        }
        field(21; "License Activation ET"; Code[20])
        {
            Description = 'License Activation Email Template';
            TableRelation = "Email Template";
        }
        field(30; "License Expired ET"; Code[20])
        {
            Description = 'License Expired Email Template';
            TableRelation = "Email Template";
        }
        field(40; "License Expired 7Day ET"; Code[20])
        {
            Description = 'License Expire Before 7 Day Email Template';
            TableRelation = "Email Template";
        }
        //T34311-NS
        field(41; "License Expired 3Day ET"; Code[20])
        {
            Description = 'License Expire Before 7 Day Email Template';
            TableRelation = "Email Template";
        }
        //T34311-NE
        field(50; "Duning Email"; Code[20])
        {
            Description = 'Duning Email Template';
            DataClassification = ToBeClassified;
            TableRelation = "Email Template";
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
    }
}
