page 52100 "Ems Setup"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    Caption = 'EMS Setup';
    UsageCategory = Administration;
    SourceTable = "EMS Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Url';
                    ToolTip = 'Specified the base url for communication with Dozee Cloud.';
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'API Key';
                    ToolTip = 'Specifies the authentication key to communicate with Dozee Cloud.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies the communication in enabled with Dozee Cloud.';
                }
                field("Email Notofication"; Rec."Email Notofication")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email Notification';
                    ToolTip = 'Specifies if the email communication will be sent to customer based on license activity.';
                }
                field("Dunning Days"; Rec."Dunning Days")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dunning Days';
                    ToolTip = 'Specifies the nuymber of days license will be extended in case of expiry or no paymnet due date is passed.';
                }
            }
            group(numbers)
            {
                field("License Request Nos."; Rec."License Request Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'License Request Nos.';
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to license request.';
                }
                field("License Nos."; Rec."License Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'License Nos.';
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to licenses.';
                }
            }
        }
    }

    actions
    {
        // area(Processing)
        // {
        //     action(ActionName)
        //     {

        //         trigger OnAction()
        //         begin

        //         end;
        //     }
        // }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        myInt: Integer;
}