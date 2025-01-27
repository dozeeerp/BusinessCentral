tableextension 52107 EMS_TransferHeader extends "Transfer Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Customer No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                Clear(Customer);
                IF Customer.get("Customer No.") then "Ship to Code" := Customer."Ship-to Code";
            end;
        }
        field(50001; "Ship to Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ship to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
    }
}
