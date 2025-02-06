tableextension 51302 HS_Item extends Item
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS_Item_Id"; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'HubSpot Item Id';
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