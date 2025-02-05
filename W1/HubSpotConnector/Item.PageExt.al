pageextension 51300 HS_Item extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addlast(Item)
        {
            field(HS_Item_Id; Rec.HS_Item_Id)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'HubSpot Item Id';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addlast(processing)
        {
            action(SendToHS)
            {
                ApplicationArea = All;
                Caption = 'Send to HubSpot';
                Image = Interaction;
                trigger OnAction()
                var
                    HSAPIMgt: Codeunit "Hubspot API Mgmt";
                begin
                    HSAPIMgt.UpdateItemToHubSpot(Rec);
                end;
            }
        }
    }

    var
        myInt: Integer;
}