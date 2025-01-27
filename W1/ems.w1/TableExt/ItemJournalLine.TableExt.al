tableextension 52110 ItemJournalLine extends "Item Journal Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Customer No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Customer No.';
        }
    }
}
