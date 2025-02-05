pageextension 51303 HS_PostedTrReceipt extends "Posted Transfer Receipt"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field(HS_ID; Rec.HS_ID)
            {
                Caption = 'Hubspot Ticker ID';
                ApplicationArea = Basic, Suite;
                ToolTip = 'specifies the ticket ID of hubspot where the information will be updated from ERP.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Send to HS';
                Image = SendTo;

                trigger OnAction()
                var
                    ILE: Record "Item Ledger Entry";
                    HSAPIMgt: Codeunit "Hubspot API Mgmt";
                    RecRef: RecordRef;
                    PipelineType: Option Demo,AddOn,Conversion;
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if Rec.HS_ID = 0 then
                        Error('This Transfer receipt is not related to HubSpot Pipeline.');
                    if not ConfirmManagement.GetResponseOrDefault('Do you wish to send item information to Hubspot.', false) then
                        exit;
                    ILE.Reset();
                    ILE.SetRange("Document No.", Rec."No.");
                    ILE.SetRange("Posting Date", Rec."Posting Date");
                    ILE.SetRange(Positive, true);
                    ILE.SetRange("Location Code", Rec."Transfer-to Code");
                    if ILE.FindSet() then
                        repeat
                            RecRef.GetTable(ILE);
                            HSAPIMgt.CheckHSTicketPipeline(Format(Rec.HS_ID), PipelineType);
                            HSAPIMgt.InsertDeviceInHS(RecRef, rec.HS_ID, PipelineType);
                        until ILE.Next() = 0;
                    Message('Devices synced with HubSpot.');
                end;
            }
        }
    }

    var
        myInt: Integer;
}