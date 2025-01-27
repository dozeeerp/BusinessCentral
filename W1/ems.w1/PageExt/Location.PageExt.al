pageextension 52102 ExtLocation extends "Location Card"
{
    layout
    {
        addafter("Use As In-Transit")
        {
            field("Demo Location"; Rec."Demo Location")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Demo Location field.';
            }
        }
    }
}
