tableextension 52104 PostedSalesInvoiceExt extends "Sales Invoice Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; Duration; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Duration';
        }
    }
}
