pageextension 52100 EMS_Customer extends "Customer Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Address & Contact")
        {
            group(License)
            {
                field("Organization ID"; Rec."Organization ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Organization ID';
                    ToolTip = 'Specifies the value Organization ID from Dozee SRPM Dashobard.';
                }
                field("Partner ID"; Rec."Partner ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not rec."Is Partner";
                    ToolTip = 'Specifies the partner/ distributor who is managing this customer.';

                    // trigger OnDrillDown()
                    // var
                    //     Customer: Record Customer;
                    //     CustomerList: Page "Customer List";
                    // begin
                    //     IF NOT Rec."Is Partner" then begin
                    //         Customer.Reset();
                    //         Customer.SetRange("Is Partner", True);
                    //         CustomerList.SetTableView(Customer);
                    //         CustomerList.LookupMode := true;
                    //         IF CustomerList.RunModal() = Action::LookupOK then Rec."Partner ID" := CustomerList.ReturnSchName();
                    //     end;
                    // End;
                }
                field("Is Partner"; Rec."Is Partner")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Partner ID" = '';
                    ToolTip = 'Specifies if the Customer is partner/distribotr wo will manage another customer.';
                }
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