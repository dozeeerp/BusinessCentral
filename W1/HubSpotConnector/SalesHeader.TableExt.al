tableextension 51311 HS_SalesHeader extends "Sales Header"
{
    fields
    {
        // Add changes to table fields here
        field(51300; HS_ID; BigInteger)
        {
            DataClassification = CustomerContent;
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