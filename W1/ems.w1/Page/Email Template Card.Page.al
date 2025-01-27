Page 52112 "Email Template Card"
{
    // --------------------------------------------------------------------------------------------------
    // Intech Systems Pvt. Ltd.
    // --------------------------------------------------------------------------------------------------
    // No.                    Date        Author
    // --------------------------------------------------------------------------------------------------
    // I-A004_I-403002-01     23/01/15    Nilesh Gajjar
    //                                    Email Template Functionality
    //                                    New Page Design
    // --------------------------------------------------------------------------------------------------
    Caption = 'Email Template Card';
    PageType = Card;
    SourceTable = "Email Template";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Email)
            {
                field("Email To"; Rec."Email To")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Email CC"; Rec."Email CC")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Email BCC"; Rec."Email BCC")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Body)
            {
                field("Body 1"; Rec."Body 1")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 2"; Rec."Body 2")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 3"; Rec."Body 3")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 4"; Rec."Body 4")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 5"; Rec."Body 5")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 6"; Rec."Body 6")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 7"; Rec."Body 7")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
                field("Body 8"; Rec."Body 8")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
            }
            group("Report Email Body Layout")
            {
                field("Email Body Report ID"; Rec."Email Body Report ID")
                {
                    ToolTip = 'Specifies the value of the Email Body Report ID field.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Email Body Report Caption"; Rec."Email Body Report Caption")
                {
                    ToolTip = 'Specifies the value of the Email Body Report Caption field.';
                    ApplicationArea = All;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ToolTip = 'Specifies the value of the Email Body Layout Code field.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Email Body Layout Descr"; Rec."Email Body Layout Descr")
                {
                    ToolTip = 'Specifies the value of the Email Body Layout Description field.';
                    ApplicationArea = All;
                }
                field("Email Body Layout Type"; Rec."Email Body Layout Type")
                {
                    ToolTip = 'Specifies the value of the Email Body Layout Type field.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
