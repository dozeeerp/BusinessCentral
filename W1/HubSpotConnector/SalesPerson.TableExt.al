tableextension 51304 HS_SalesPerson extends "Salesperson/Purchaser"
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS_Sales_ID"; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'Hubspot ID';
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