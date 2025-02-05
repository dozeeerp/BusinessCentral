pageextension 51305 HS_FATransferOrder extends "FA Transfer Order"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field(HS_ID; Rec.HS_ID)
            {
                Caption = 'Hubspot Ticker ID';
                ApplicationArea = Basic, Suite;
                ToolTip = 'specifies the ticket ID of hubspot where the information will be updated from ERP.';
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