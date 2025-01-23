pageextension 52103 SalesInvSubform extends "Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {
            field(Duration; Rec.Duration)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Duration field.';
            }
        }
    }
}
