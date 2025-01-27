pageextension 52108 EMS_TransferOrders extends "Transfer Orders"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the customer number to whom the Item is Trasfrred to.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}