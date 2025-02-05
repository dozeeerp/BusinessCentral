tableextension 51300 HB_Customer extends Customer
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS Customer ID"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'HS Customer ID';
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