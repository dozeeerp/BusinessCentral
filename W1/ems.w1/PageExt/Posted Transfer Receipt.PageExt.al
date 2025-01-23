pageextension 52111 Ext extends "Posted Transfer Receipt"
{
    layout
    {
        // Add changes to page layout here
        addafter("Posting Date")
        {
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the value of the Customer No. field.';
            }
            field("Ship to Code"; Rec."Ship to Code")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the value of the Ship to Code field.';
            }
        }
    }
}
