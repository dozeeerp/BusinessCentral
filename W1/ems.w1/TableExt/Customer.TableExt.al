tableextension 52100 "EMS Customer" extends Customer
{
    fields
    {
        // Add changes to table fields here
        field(52100; "Organization ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Organization ID';
        }
        field(52101; "Partner ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Partner ID';
        }
        field(52102; "Is Partner"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Partner';
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
}