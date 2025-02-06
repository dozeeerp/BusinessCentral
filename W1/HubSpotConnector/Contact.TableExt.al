tableextension 51301 HS_Contact extends Contact
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS Contact ID"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'HS Contact ID';
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