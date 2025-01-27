pageextension 52105 EMSPostedsalesInvoice extends "Posted Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field(Duration; Rec.Duration)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Duration field.';
            }
        }
    }
}
