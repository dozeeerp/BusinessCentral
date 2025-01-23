tableextension 52106 EMS_ILE extends "Item Ledger Entry"
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
        field(53001; "Demo Location"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Location."Demo Location" where(Code = field("Location Code")));
            Editable = false;
        }
        field(50002; "Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            FieldClass = FlowField;
        }
    }
}
