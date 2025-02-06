tableextension 51310 TST_FATransReceipt extends "FA Transfer Receipt Header"
{
    fields
    {
        // Add changes to table fields here
        field(51300; "HS_ID"; BigInteger)
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