tableextension 52109 EMSTransferReceiptHdr extends "Transfer Receipt Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Customer No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(50001; "Ship to Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ship to Code';
            TableRelation = Customer;
        }
    }
}
