Page 52113 "Email Template Setup"
{
    PageType = Card;
    SourceTable = "Email Template Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("License Activation ET"; Rec."License Activation ET")
                {
                    ToolTip = 'Specifies the value of the License Activation ET field.';
                    ApplicationArea = All;
                }
                field("License Expired ET"; Rec."License Expired ET")
                {
                    ToolTip = 'Specifies the value of the License Expired ET field.';
                    ApplicationArea = All;
                }
                field("License Expired 7Day ET"; Rec."License Expired 7Day ET")
                {
                    ToolTip = 'Specifies the value of the License Expired 7Day ET field.';
                    ApplicationArea = All;
                }
                //T34311-NS
                field("License Expired 3Day ET"; Rec."License Expired 3Day ET")
                {
                    ToolTip = 'Specifies the value of the License Expired 7Day ET field.';
                    ApplicationArea = All;
                }
                //T34311-NE
                field("Duning Email"; Rec."Duning Email")
                {
                    ToolTip = 'Specifies the value of the Duning Email.';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
    }
    trigger OnOpenPage()
    begin
        Rec.Reset;
        if not Rec.Get then begin
            Rec.Init;
            Rec.Insert;
        end;
    end;
}
