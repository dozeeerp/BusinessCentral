pageextension 52101 ExtItemCard extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Inventory)
        {
            field("Devices Item"; Rec."Devices Item")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Devices Item field.';
            }
        }
    }
}
