namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Transfer;
using Microsoft.Inventory.Setup;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Transfer;

codeunit 51224 "FATransferOrder-Post (Yes/No)"
{
    TableNo = "FA Transfer Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        FATransHeader.Copy(Rec);
        Code();
        Rec := FATransHeader;
    end;

    var
        FATransHeader: Record "FA Transfer Header";
        PreviewMode: Boolean;
        PostBatch: Boolean;
        TransferOrderPost: enum "Transfer Order Post";
        Text000: Label '&Ship,&Receive';

    local procedure "Code"()
    var
        PostReceipt, PostShipment, PostTransfer : Boolean;
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
    begin
        DefaultNumber := GetDefaultNumber();

        GetPostingOptions(DefaultNumber, Selection, PostShipment, PostReceipt, PostTransfer);
        PostTransferOrder(PostShipment, PostReceipt, PostTransfer);
    end;

    local procedure GetDefaultNumber() DefaultNumber: Integer
    var
        FATransferLine: Record "FA Transfer Line";
    begin
        if PostBatch or FATransHeader."Direct Transfer" then
            exit;

        FATransferLine.Reset();
        FATransferLine.SetRange("Document No.", FATransHeader."No.");
        if FATransferLine.Find('-') then
            repeat
                if (FATransferLine."Quantity Shipped" < FATransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 1;
                if (FATransferLine."Quantity Received" < FATransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 2;
            until (FATransferLine.Next() = 0) or (DefaultNumber > 0);
    end;

    local procedure GetPostingOptions(var DefaultNumber: Integer; var Selection: Option " ",Shipment,Receipt; var PostShipment: boolean; var PostReceipt: boolean; var PostTransfer: boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();

        case true of
            (FATransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Receipt and Shipment"):
                begin
                    PostShipment := true;
                    PostReceipt := true;
                end;
            (FATransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Direct Transfer"):
                PostTransfer := true;
            PostBatch:
                begin
                    PostShipment := TransferOrderPost = TransferOrderPost::Ship;
                    PostReceipt := TransferOrderPost = TransferOrderPost::Receive;
                end;
            else begin
                if DefaultNumber = 0 then
                    DefaultNumber := 1;
                Selection := StrMenu(Text000, DefaultNumber);
                PostShipment := Selection = Selection::Shipment;
                PostReceipt := Selection = Selection::Receipt;
            end;
        end;
    end;

    local procedure PostTransferOrder(PostShipment: boolean; PostReceipt: boolean; PostTransfer: boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        TransferOrderPostReceipt: Codeunit "FATransferOrder-Post Receipt";
        FATransferOrderPostShipment: Codeunit "FATransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "FATransferOrder-Post Transfer";
    begin
        if PostShipment then begin
            FATransferOrderPostShipment.SetHideValidationDialog(PostBatch);
            FATransferOrderPostShipment.SetPreviewMode(PreviewMode);
            FATransferOrderPostShipment.Run(FATransHeader);
        end;

        if PostReceipt then begin
            TransferOrderPostReceipt.SetHideValidationDialog(PostBatch);
            TransferOrderPostReceipt.SetPreviewMode(PreviewMode);
            TransferOrderPostReceipt.Run(FATransHeader);
        end;

        if PostTransfer then begin
            TransferOrderPostTransfer.SetPreviewMode(PreviewMode);
            TransferOrderPostTransfer.Run(FATransHeader);
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    internal procedure SetParameters(SetPostBatch: Boolean; SetTransferOrderPost: enum "Transfer Order Post")
    begin
        PostBatch := SetPostBatch;
        TransferOrderPost := SetTransferOrderPost;
    end;

    procedure Preview(var FATransferHeader: Record "FA Transfer Header")
    var
        TransferOrderPostYesNo: Codeunit "FATransferOrder-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(TransferOrderPostYesNo);
        GenJnlPostPreview.Preview(TransferOrderPostYesNo, FATransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        FATransferHeader: Record "FA Transfer Header";
        TransferOrderPostYesNo: Codeunit "FATransferOrder-Post (Yes/No)";
    begin
        FATransferHeader.Copy(RecVar);
        TransferOrderPostYesNo.SetPreviewMode(true);
        Result := TransferOrderPostYesNo.Run(FATransferHeader);
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;
}