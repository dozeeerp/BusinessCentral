pageextension 52104 EMS_ItemCatogories extends "Item Categories"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("Used for License"; Rec."Used for License")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Used for License field.';
            }
        }
    }
}
