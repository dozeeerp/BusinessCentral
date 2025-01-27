codeunit 52105 "Document Attachment"
{
    trigger OnRun()
    begin

    end;


    // [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", 'OnBeforeDrillDown', '', false, false)]
    // local procedure LicenseDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    // var
    //     LicenseRequest: Record "License Request";
    // begin
    //     case DocumentAttachment."Table ID" of
    //         0:
    //             exit;
    //         Database::"License Request":
    //             begin
    //                 RecRef.Open(Database::"License Request");
    //                 if LicenseRequest.Get(DocumentAttachment."No.") then
    //                     RecRef.GetTable(LicenseRequest);
    //             end;
    //     end;
    // end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure InitFieldsFromLicense(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        case RecRef.Number of
            Database::"License Request":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment."No." := RecNo;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', false, false)]
    local procedure OpenForLicense(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        case RecRef.Number of
            Database::"License Request":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
        end;
    end;
}