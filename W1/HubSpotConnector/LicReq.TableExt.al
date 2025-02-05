tableextension 51305 HS_LicReq extends "License Request"
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS_ID"; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'HubSpot ID';
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