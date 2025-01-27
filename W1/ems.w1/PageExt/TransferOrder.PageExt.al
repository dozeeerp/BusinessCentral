pageextension 52107 EMS_TransferOrder extends "Transfer Order"
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Customer No. field.';
            }
            field("Ship to Code"; Rec."Ship to Code")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the Ship to Code field.';
            }
        }
    }
}
