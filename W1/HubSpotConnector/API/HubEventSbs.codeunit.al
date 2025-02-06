codeunit 51304 "HS Event Subscriber"
{
    trigger OnRun()
    begin

    end;

    var
        HSAPIMgmt: Codeunit "Hubspot API Mgmt";
        HSSetup: Record "Hubspot Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnBeforeTransRcptHeaderInsert, '', false, false)]
    local procedure CopyHSIDOnBeforeTransRcptHeaderInsert(TransferHeader: Record "Transfer Header"; var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
        TransferReceiptHeader.HS_ID := TransferHeader.HS_ID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnAfterTransferOrderPostReceipt, '', false, false)]
    procedure UpdateDeviceReceivedOnHS(var TransferHeader: Record "Transfer Header"; var TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        JObject: JsonObject;
        Location: Record Location;
        HSIntLog: Record "HubSpot Int. Log";
        ILE: Record "Item Ledger Entry";
        RecRef: RecordRef;
        PipelineType: Option Demo,AddOn,Conversion;
        HSSetup: Record "Hubspot Setup";
        LastTicketStage: BigInteger;
    begin
        //yet to consider partial shipments from ERP
        if TransferHeader.HS_ID = 0 then
            exit;

        HSSetup.Get();
        if (HSSetup."Demo Location" = TransferHeader."Transfer-to Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-to Code") then begin
            HSAPIMgmt.CheckHSTicketPipeline(Format(TransferHeader.HS_ID), PipelineType);
            HSAPIMgmt.CheckHSTicketLastStatus(Format(TransferHeader.HS_ID), LastTicketStage);
            if LastTicketStage in [176793090, 180948364, 209275253, 212658553] then begin
                case PipelineType of
                    PipelineType::Demo:
                        JObject.Add('hs_pipeline_stage', '176793091');
                    PipelineType::Conversion:
                        JObject.Add('hs_pipeline_stage', '180948365');
                    PipelineType::AddOn:
                        begin
                            HSIntLog.Reset();
                            HSIntLog.SetRange(objectId, TransferHeader.HS_ID);
                            if HSIntLog.FindLast() then begin
                                if HSIntLog.propertyName = 'hs_pipeline_stage' then begin
                                    case HSIntLog.propertyValue of
                                        '209275252':    //Add On Material Sandbox
                                            begin
                                                JObject.Add('hs_pipeline_stage', '209275254');
                                            end;
                                        '212658552':    //Add On Material Production
                                            begin
                                                JObject.Add('hs_pipeline_stage', '212658554');
                                            end;
                                    end;
                                end;
                            end;
                        end;
                end;
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end;
            ILE.Reset();
            ILE.SetRange("Document No.", TransferReceiptHeader."No.");
            ILE.SetRange(Positive, true);
            ILE.SetRange("Location Code", TransferReceiptHeader."Transfer-to Code");
            ILE.SetRange("Posting Date", TransferReceiptHeader."Posting Date");
            if ILE.FindSet() then
                repeat
                    RecRef.GetTable(ILE);
                    HSAPIMgmt.InsertDeviceInHS(RecRef, TransferHeader.HS_ID, PipelineType);
                until ILE.Next() = 0;
        end;

        if (HSSetup."Demo Location" = TransferHeader."Transfer-from Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-from Code") then begin
            ILE.Reset();
            ILE.SetFilter("Remaining Quantity", '<>%1', 0);
            ILE.SetFilter("Customer No.", TransferHeader."Customer No.");
            ILE.SetFilter("Location Code", HSSetup."Demo Location");
            if not ILE.FindSet() then begin
                JObject.Add('hs_pipeline_stage', '176793098');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end else begin
                JObject.Add('current_status', 'Partial Device Returned');
                JObject.Add('submit_device_return_request', '');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FATransferOrder-Post Receipt", OnBeforeFATransRcptHeaderInsert, '', false, false)]
    local procedure CopyHSIDOnBeforeFATransRcptHeaderInsert(FATransferHeader: Record "FA Transfer Header"; var FATransferReceiptHeader: Record "FA Transfer Receipt Header")
    begin
        FATransferReceiptHeader.HS_ID := FATransferHeader.HS_ID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FATransferOrder-Post Receipt", OnAfterTransferOrderPostReceipt, '', false, false)]
    local procedure UpdateFADeviceReceivedOnHS(var TransferHeader: Record "FA Transfer Header"; var TransferReceiptHeader: Record "FA Transfer Receipt Header")
    var
        JObject: JsonObject;
        Location: Record Location;
        HSIntLog: Record "HubSpot Int. Log";
        ILE: Record "FA Item Ledger Entry";
        RecRef: RecordRef;
        PipelineType: Option Demo,AddOn,Conversion;
        LastTicketStage: BigInteger;
    begin
        if TransferReceiptHeader.HS_ID = 0 then
            exit;
        HSSetup.Get();
        if (HSSetup."Demo Location" = TransferHeader."Transfer-to Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-to Code") then begin
            HSAPIMgmt.CheckHSTicketPipeline(Format(TransferHeader.HS_ID), PipelineType);
            HSAPIMgmt.CheckHSTicketLastStatus(Format(TransferHeader.HS_ID), LastTicketStage);
            if LastTicketStage in [176793090, 180948364, 209275253, 212658553] then begin
                case PipelineType of
                    PipelineType::Demo:
                        JObject.Add('hs_pipeline_stage', '176793091');
                    PipelineType::Conversion:
                        JObject.Add('hs_pipeline_stage', '180948365');
                    PipelineType::AddOn:
                        begin
                            HSIntLog.Reset();
                            HSIntLog.SetRange(objectId, TransferHeader.HS_ID);
                            if HSIntLog.FindLast() then begin
                                if HSIntLog.propertyName = 'hs_pipeline_stage' then begin
                                    case HSIntLog.propertyValue of
                                        '209275252':    //Add On Material Sandbox
                                            begin
                                                JObject.Add('hs_pipeline_stage', '209275254');
                                            end;
                                        '212658552':    //Add On Material Production
                                            begin
                                                JObject.Add('hs_pipeline_stage', '212658554');
                                            end;
                                    end;
                                end;
                            end;
                        end;
                end;
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end;
            ILE.Reset();
            ILE.SetRange("Document No.", TransferReceiptHeader."No.");
            ILE.SetRange(Positive, true);
            ILE.SetRange("Location Code", TransferReceiptHeader."Transfer-to Code");
            ILE.SetRange("Posting Date", TransferReceiptHeader."Posting Date");
            if ILE.FindSet() then
                repeat
                    RecRef.GetTable(ILE);
                    HSAPIMgmt.InsertDeviceInHS(RecRef, TransferHeader.HS_ID, PipelineType);
                until ILE.Next() = 0;
        end;

        if (HSSetup."Demo Location" = TransferHeader."Transfer-from Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-from Code") then begin
            ILE.Reset();
            ILE.SetFilter("Remaining Quantity", '<>%1', 0);
            ILE.SetFilter("Customer No.", TransferHeader."Transfer-from Customer");
            ILE.SetFilter("Location Code", HSSetup."Demo Location");
            if not ILE.FindSet() then begin
                JObject.Add('hs_pipeline_stage', '176793098');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end else begin
                JObject.Add('current_status', 'Partial Device Returned');
                JObject.Add('submit_device_return_request', '');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end;
        end;
    end;
}