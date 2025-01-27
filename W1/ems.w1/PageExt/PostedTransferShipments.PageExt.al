pageextension 52110 PostedTransferShipmentsExt extends "Posted Transfer Shipments"
{
    layout
    {
        addafter("Posting Date")
        {
            //T37592-NS
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = all;
                Editable = false;
            }
            //T37592-NE
        }
    }
    var
        myInt: Integer;
}
