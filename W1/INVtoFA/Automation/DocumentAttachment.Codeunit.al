namespace TSTChanges.Automation;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Transfer;
using TSTChanges.FA.Transfer;

codeunit 51237 "TST Document Attchment"
{
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    // ConfirmManagement: Codeunit "Confirm Management";
    // DeleteAttachmentsConfirmQst: Label 'Do you want to delete the attachments for this document?';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter, '', false, false)]
    local procedure OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter(var RelatedTable: Integer; TableNo: Integer)
    begin
        case TableNo of
            Database::"Transfer Header":
                RelatedTable := Database::"Transfer Line";
            Database::"FA Transfer Header":
                RelatedTable := Database::"FA Transfer Line";
            Database::"FA Transfer Shipment Header":
                RelatedTable := Database::"FA Transfer Shipment Line";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasNumberFieldPrimaryKey, '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var FieldNo: Integer; var Result: Boolean)
    begin
        // Field referance for "No."
        If TableNo in
            [Database::"Transfer Header",
            Database::"Transfer Line",
            Database::"Transfer Shipment Header",
            Database::"Transfer Shipment Line",
            Database::"Transfer Receipt Header",
            Database::"Transfer Receipt Line",
            Database::"License Request",
            Database::"FA Transfer Header",
            Database::"FA Transfer Line",
            Database::"FA Transfer Shipment Header"]
        then begin
            FieldNo := 1;
            Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasDocTypePrimaryKey, '', false, false)]
    local procedure OnAfterTableHasDocTypePrimaryKey(TableNo: Integer; var FieldNo: Integer; var Result: Boolean)
    begin
        //Field Referance of "Docuemnt Type"
        // if TableNo in
        //     []
        // then begin
        //     FieldNo := ;
        //     Result := true;
        // end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasLineNumberPrimaryKey, '', false, false)]
    local procedure OnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var FieldNo: Integer; var Result: Boolean)
    begin
        //Field Referance of "Line No."
        if TableNo in
            [Database::"Transfer Line",
            Database::"Transfer Shipment Line",
            Database::"Transfer Receipt Line",
            Database::"FA Transfer Line",
            Database::"FA Transfer Shipment Line"]
        then begin
            FieldNo := 2;
            Result := true;
        end;
    end;

    // local procedure DeleteAttachedDocuments(RecRef: RecordRef)
    // var
    //     DocumentAttachment: Record "Document Attachment";
    // begin
    //     if RecRef.IsTemporary() then
    //         exit;
    //     if DocumentAttachment.IsEmpty() then
    //         exit;

    //     SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
    //     if AttachedDocumentsExist(RecRef) then
    //         DocumentAttachment.DeleteAll();
    // end;

    // local procedure DeleteAttachedDocumentsWithConfirm(RecRef: RecordRef)
    // begin
    //     if AttachedDocumentsExist(RecRef) then
    //         if ConfirmManagement.GetResponseOrDefault(DeleteAttachmentsConfirmQst, true) then
    //             DeleteAttachedDocuments(RecRef);
    // end;

    // local procedure AttachedDocumentsExist(RecRef: RecordRef): Boolean
    // var
    //     DocumentAttachment: Record "Document Attachment";
    // begin
    //     if RecRef.IsTemporary() then
    //         exit(false);
    //     if DocumentAttachment.IsEmpty() then
    //         exit(false);

    //     SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
    //     exit(not DocumentAttachment.IsEmpty())
    // end;

    // local procedure SetDocumentAttachmentFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    // var
    //     FieldRef: FieldRef;
    //     RecNo: Code[20];
    //     DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
    //     LineNo: Integer;
    // begin
    //     DocumentAttachment.SetRange("Table ID", RecRef.Number);
    //     case RecRef.Number() of
    //         Database::"Transfer Header",
    //         Database::"License Request",
    //         Database::"Transfer Line",
    //         Database::"Transfer Receipt Header",
    //         Database::"Transfer Receipt Line":
    //             begin
    //                 FieldRef := RecRef.Field(1);
    //                 RecNo := FieldRef.Value();
    //                 DocumentAttachment.SetRange("No.", RecNo);
    //             end;
    //     end;
    // end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", 'OnBeforeDrillDown', '', false, false)]
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        TransferHeader: Record "Transfer Header";
        TransferShipment: Record "Transfer Shipment Header";
        TransferRcpt: Record "Transfer Receipt Header";
        LicenseRequest: Record "License Request";
        FATransferHeader: Record "FA Transfer Header";
        FATransferShipment: Record "FA Transfer Shipment Header";
        FATransRcptHdr: Record "FA Transfer Receipt Header";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Transfer Header":
                begin
                    RecRef.Open(Database::"Transfer Header");
                    if TransferHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(TransferHeader);
                end;
            DataBase::"Transfer Receipt Header":
                begin
                    RecRef.Open(Database::"Transfer Receipt Header");
                    if TransferRcpt.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(TransferRcpt);
                end;
            Database::"Transfer Shipment Header":
                begin
                    RecRef.Open(Database::"Transfer Shipment Header");
                    if TransferShipment.get(DocumentAttachment."No.") then
                        RecRef.GetTable(TransferShipment);
                end;
            Database::"License Request":
                begin
                    RecRef.Open(Database::"License Request");
                    If LicenseRequest.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(LicenseRequest);
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.Open(Database::"FA Transfer Header");
                    if FATransferHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(FATransferHeader);
                end;
            Database::"FA Transfer Shipment Header":
                begin
                    RecRef.Open(Database::"FA Transfer Shipment Header");
                    if FATransferShipment.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(FATransferShipment);
                end;
            Database::"FA Transfer Receipt Header":
                begin
                    RecRef.Open(Database::"FA Transfer Receipt Header");
                    if FATransRcptHdr.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(FATransRcptHdr);
                end;
        end;
    end;

    // [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    // local procedure InitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    // var
    //     FieldRef: FieldRef;
    //     RecNo: Code[20];
    // begin
    //     case RecRef.Number of
    //         DATABASE::"Transfer Header",
    //         DATABASE::"Transfer Line",
    //         DataBase::"Transfer Receipt Header",
    //         Database::"Transfer Shipment Header":
    //             begin
    //                 FieldRef := RecRef.Field(1);
    //                 RecNo := FieldRef.Value;
    //                 DocumentAttachment.Validate("No.", RecNo);
    //             end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', false, false)]
    // local procedure OnafterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FlowFieldsEditable: Boolean)
    // var
    //     FieldRef: FieldRef;
    //     RecNo: Code[20];
    // begin
    //     case RecRef.Number of
    //         DATABASE::"Transfer Header",
    //         DATABASE::"Transfer Line",
    //         Database::"Transfer Receipt Header",
    //         Database::"Transfer Shipment Header":
    //             begin
    //                 FieldRef := RecRef.Field(1);
    //                 RecNo := FieldRef.Value;
    //                 DocumentAttachment.SetRange(DocumentAttachment."No.", RecNo);
    //                 FlowFieldsEditable := false;
    //             end;
    //     end;
    // end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterDeleteEvent', '', false, false)]
    Local procedure DeleteAttachedDocumentsOnAfterDeleteTransferHeader(var Rec: Record "Transfer Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", OnAfterDeleteEvent, '', false, false)]
    local procedure DeleterAttachedDocumentsOnAfterDeleteTranShptHdr(var Rec: Record "Transfer Shipment Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteTransferReceiptHeader(var Rec: Record "Transfer Receipt Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DelereAttchedDocuementsonAfterDeleteLicenseRequest(var Rec: Record "License Request"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Header", OnAfterDeleteEvent, '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteFATransferHeader(var Rec: Record "FA Transfer Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, DataBase::"FA Transfer Shipment Header", OnAfterDeleteEvent, '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteFATransShptHdr(var Rec: Record "FA Transfer Shipment Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Receipt Header", OnAfterDeleteEvent, '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteFATransRcptHeader(var Rec: Record "FA Transfer Receipt Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DocumentAttachmentMgmt.DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Customer No.', false, false)]
    local procedure DocAttachFlowForTransferHeaderCustomerChg(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        RecRef: RecordRef;
    begin
        if Rec."No." = '' then
            exit;
        if rec.IsTemporary then
            exit;

        RecRef.GetTable(Rec);
        if (Rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocumentsWithConfirm(RecRef);

        // DocAttachFlowForSalesHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnBeforeValidateEvent', 'Customer No.', false, false)]
    local procedure DocAttchFlowForLicenseRequestCustomerChg(var Rec: Record "License Request"; var xRec: Record "License Request"; CurrFieldNo: Integer)
    var
        RecRef: RecordRef;
    begin
        if rec."No." = '' then
            exit;
        if Rec.IsTemporary then
            exit;

        RecRef.GetTable(Rec);
        if (rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocumentsWithConfirm(RecRef);

        // DocAttachFlowForSalesHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeDeleteOneTransferHeader', '', false, false)]
    local procedure DocAttchForPostedTtransferRcpt(TransferHeader: Record "Transfer Header"; TransferReceiptHeader: Record "Transfer Receipt Header"; var DeleteOne: Boolean)
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        if TransferHeader.IsTemporary then
            exit;

        if TransferReceiptHeader.IsTemporary then
            exit;

        FromRecRef.GetTable(TransferHeader);

        if TransferReceiptHeader."No." <> '' then
            ToRecRef.GetTable(TransferReceiptHeader);

        if ToRecRef.Number > 0 then
            CopyAttachmentsForPostedDocs(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeInsertTransShptHeader', '', false, false)]
    local procedure DocAttchForPostedTransferShip(TransHeader: Record "Transfer Header"; var TransShptHeader: Record "Transfer Shipment Header"; CommitIsSuppressed: Boolean)
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        if TransHeader.IsTemporary then
            exit;

        if TransShptHeader.IsTemporary then
            exit;

        FromRecRef.GetTable(TransHeader);

        if TransShptHeader."No." <> '' then
            ToRecRef.GetTable(TransShptHeader);

        if ToRecRef.Number > 0 then
            CopyAttachmentsForPostedDocs(FromRecRef, ToRecRef);
    end;

    procedure CopyAttachmentsForPostedDocs(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromDocumentAttachment: Record "Document Attachment";
        ToDocumentAttachment: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        FromDocumentAttachment.SetRange("Table ID", FromRecRef.Number);

        FromFieldRef := FromRecRef.Field(1);
        FromNo := FromFieldRef.Value;
        FromDocumentAttachment.SetRange("No.", FromNo);

        if FromDocumentAttachment.FindSet() then begin
            repeat
                Clear(ToDocumentAttachment);
                ToDocumentAttachment.Init();
                ToDocumentAttachment.TransferFields(FromDocumentAttachment);
                ToDocumentAttachment.Validate("Table ID", ToRecRef.Number);

                ToFieldRef := ToRecRef.Field(1);
                ToNo := ToFieldRef.Value;
                ToDocumentAttachment.Validate("No.", ToNo);
                Clear(ToDocumentAttachment."Document Type");
                ToDocumentAttachment.Insert(true);
            until FromDocumentAttachment.Next() = 0;
        end;
        CopyAttachmentsForPostedDocsLines(FromRecRef, ToRecRef);
    end;

    local procedure CopyAttachmentsForPostedDocsLines(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromDocumentAttachmentLines: Record "Document Attachment";
        ToDocumentAttachmentLines: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromDocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        FromFieldRef := FromRecRef.Field(1);
        FromNo := FromFieldRef.Value();
        FromDocumentAttachmentLines.Reset();

        ToFieldRef := ToRecRef.Field(1);
        ToNo := ToFieldRef.Value();

        case FromRecRef.Number() of
            DATABASE::"Transfer Header":
                FromDocumentAttachmentLines.SetRange("Table ID", DATABASE::"Transfer Line");
            Database::"FA Transfer Header":
                FromDocumentAttachmentLines.SetRange("Table ID", Database::"FA Transfer Line");
        end;
        FromDocumentAttachmentLines.SetRange("No.", FromNo);
        // FromDocumentAttachmentLines.SetRange("Document Type", FromDocumentType);
        if FromDocumentAttachmentLines.FindSet() then
            repeat
                ToDocumentAttachmentLines.TransferFields(FromDocumentAttachmentLines);
                case ToRecRef.Number of
                    DATABASE::"Transfer Receipt Header":
                        ToDocumentAttachmentLines.Validate("Table ID", DATABASE::"Transfer Receipt Line");
                // Database::"Posted Conversion Header":
                //     ToDocumentAttachmentLines.Validate("Table ID", Database::"Posted Conversion Line");
                end;
                Clear(ToDocumentAttachmentLines."Document Type");
                ToDocumentAttachmentLines.Validate("No.", ToNo);

                ToDocumentAttachmentLines.Insert(true);
            until FromDocumentAttachmentLines.Next() = 0;
    end;
}