namespace TSTChanges.FA.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using TSTChanges.FA.Tracking;
using TSTChanges.FA.Ledger;
using Microsoft.Finance.TaxBase;
using Microsoft.Foundation.Company;
using System.Utilities;
using Microsoft.Finance.TaxEngine.TaxTypeHandler;
using TSTChanges.FA.FAItem;
using Microsoft.Foundation.Shipping;

report 51200 "FA Transfer Shipment"
{
    UsageCategory = ReportsAndAnalysis;
    // ApplicationArea = All;
    DefaultRenderingLayout = RDLC;
    Caption = 'FA Transfer Shipment';

    dataset
    {
        dataitem("FA Transfer Shipment Header"; "FA Transfer Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Transfer-from Code", "Transfer-to Code";
            RequestFilterHeading = 'Posted FA Transfer Shipment';
            column(No_TransShptHeader; "No.")
            {
            }
            dataitem(CopyLoop; Integer)
            {
                DataItemTableView = sorting(Number);
                column(ReportTitleText; ReportTitleText[CopyLoop.Number])
                {
                }
                column(Copyloop_Number; CopyLoop.Number)
                {
                }

                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompInfo_Picture; CompInfo.Picture)
                    {
                    }
                    column(CompInfo_PAN_No; CompInfo."P.A.N. No.")
                    {
                    }
                    column(CompInfo_GSTIN; CompInfo."GST Registration No.")
                    {
                    }
                    column(CompInfo_CIN_No; CompInfo."CIN No.")
                    {
                    }
                    column(CompInfo_Name; CompInfo.Name)
                    {
                    }
                    column(ComAddreText; ComAddreText)
                    {
                    }
                    column(TransferToaddTxt; TransferToaddTxt)
                    {
                    }
                    column(TransferFromAddTxt; TransferFromAddTxt)
                    {
                    }
                    column(InTransit_TransShptHeader; "FA Transfer Shipment Header"."In-Transit Code")
                    {
                        IncludeCaption = true;
                    }
                    column(PostDate_TransShptHeader; Format("FA Transfer Shipment Header"."Posting Date"))
                    {
                    }
                    column(No2_TransShptHeader; "FA Transfer Shipment Header"."No.")
                    {
                    }
                    column(ShiptDate_TransShptHeader; Format("FA Transfer Shipment Header"."Shipment Date"))
                    {
                    }
                    column(ReceiptDate_TransShptHeader; Format("FA Transfer Shipment Header"."Receipt Date"))
                    {
                    }
                    column(TransOrderNo; "FA Transfer Shipment Header"."Transfer Order No.")
                    {
                    }
                    column(ExternalDocNo; "FA Transfer Shipment Header"."External Document No.")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(CurrSymbol; CurrSymbol)
                    {
                    }
                    dataitem("FA Transfer Shipment Line"; "FA Transfer Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "FA Transfer Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(i; i)
                        {
                        }
                        column(LotNoSrNoTxt; LotNoSrNoTxt)
                        {
                        }
                        column(ItemNo_TransShptLine; "FA Item No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Desc_TransShptLine; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(Qty_TransShptLine; Quantity)
                        {
                            IncludeCaption = true;
                        }
                        column(UOM_TransShptLine; "Unit of Measure")
                        {
                            IncludeCaption = true;
                        }
                        column(LineNo_TransShptLine; "Line No.")
                        {
                        }
                        column(DocNo_TransShptLine; "Document No.")
                        {
                        }
                        column(FAItem_HSNSACCode; FAItem."HSN/SAC Code")
                        {
                        }
                        column(FAItem_MRP; FAItem.MRP)
                        {
                        }
                        column(IGSTAmt; IGSTAmt)
                        {
                        }
                        column(CGSTAmt; CGSTAmt)
                        {
                        }
                        column(SGSTAmt; SGSTAmt)
                        {
                        }
                        column(IGSTPer; IGSTPer)
                        {
                        }
                        column(CGSTPer; CGSTPer)
                        {
                        }
                        column(SGSTPer; SGSTPer)
                        {
                        }
                        column(BaseAmount; BaseAmount)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            TempFAItemLegEntry: Record "FA Item ledger Entry" temporary;
                            ItemTrackingDocMgt: Codeunit "FA Item Tracking Doc. Mgmt";
                            LotNo: Text;
                            SerialNo: Text;
                            TaxRateId: Text;
                            IsSameState: Boolean;
                            TaxSetup: Text;
                        begin
                            i := i + 1;
                            ResetGSTComp();
                            FAItem.Get("FA Item No.");
                            TaxRateId := FAItem."GST Group Code" + '|' + "FA Transfer Shipment Header"."Transfer-to State Code" +
                                '|' + "FA Transfer Shipment Header"."Transfer-from State Code" + '|No|No|';
                            TaxSetup := FAItem."GST Group Code" + '|' + FAItem."HSN/SAC Code" + '|' + "FA Transfer Shipment Header"."Transfer-to State Code" +
                                '|' + "FA Transfer Shipment Header"."Transfer-from State Code" + '|2000-01-01|No|No|';

                            IsSameState := "FA Transfer Shipment Header"."Transfer-to State Code" = "FA Transfer Shipment Header"."Transfer-from State Code";

                            BaseAmount := Round((Quantity * FAItem.MRP), GetRoundingPrecisionUnitPrice());
                            CalculateTaxValues(TaxSetup, FAItem."HSN/SAC Code", BaseAmount, IsSameState, IGSTAmt, CGSTAmt, SGSTAmt);
                            TotalAmount := Round(
                                (BaseAmount + IGSTAmt + CGSTAmt + SGSTAmt),
                                GetRoundingPrecisionUnitPrice()
                            );

                            LotNoSrNoTxt := '';
                            LotNo := '';
                            SerialNo := '';
                            LotNo1_gCod := '';
                            ItemTrackingDocMgt.RetrieveEntriesFromShptRcpt(TempFAItemLegEntry, Database::"FA Transfer Shipment Line", 0, "Document No.", '', 0, "Line No.");
                            if TempFAItemLegEntry.FindSet() then begin
                                repeat
                                    if TempFAItemLegEntry."Lot No." <> '' then
                                        if LotNo = '' then
                                            LotNo := '<B>Lot No. - </B>' + TempFAItemLegEntry."Lot No."
                                        else
                                            LotNo += ', ' + TempFAItemLegEntry."Lot No.";
                                    if TempFAItemLegEntry."Serial No." <> '' then
                                        if SerialNo = '' then
                                            SerialNo := '<b>Serial No. - </b>' + TempFAItemLegEntry."Serial No."
                                        else
                                            SerialNo := ', ' + TempFAItemLegEntry."Serial No.";

                                    if (SerialNo <> '') and (LotNo <> '') then begin
                                        if LotNo1_gCod = TempFAItemLegEntry."Lot No." then begin
                                            if LotNoSrNoTxt = '' then
                                                LotNoSrNoTxt := ' ' + TempFAItemLegEntry."Lot No." + ' - ' + TempFAItemLegEntry."Serial No."
                                            else
                                                LotNoSrNoTxt += ', ' + TempFAItemLegEntry."Serial No.";
                                        end else begin
                                            if LotNoSrNoTxt = '' then
                                                LotNoSrNoTxt := '<b>Lot No. - Serial No. : </b>' + TempFAItemLegEntry."Lot No." + ' - ' + TempFAItemLegEntry."Serial No."
                                            else
                                                LotNoSrNoTxt += '<br/>' + TempFAItemLegEntry."Lot No." + ' - ' + TempFAItemLegEntry."Serial No.";
                                            LotNo1_gCod := TempFAItemLegEntry."Lot No.";
                                        end;
                                    end;
                                until TempFAItemLegEntry.Next() = 0;

                                if LotNoSrNoTxt <> '' then begin
                                    SerialNo := '';
                                    LotNo := '';
                                end else
                                    if Lotno <> '' then begin
                                        LotNoSrNoTxt := LotNo;
                                    end else
                                        if SerialNo <> '' then begin
                                            LotNoSrNoTxt := SerialNo
                                        end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("FA Item No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text000;
                        OutputNo += 1;
                    end;

                    InitVariables();
                end;

                trigger OnPreDataItem()
                begin
                    if ReportTitleBol[1] then begin
                        ReportTitleText[1] := Text001;
                        NoOfCopies += 1;
                    end;
                    if ReportTitleBol[2] then begin
                        ReportTitleText[2] := Text002;
                        NoOfCopies += 1;
                    end;
                    if ReportTitleBol[3] then begin
                        ReportTitleText[3] := Text003;
                        NoOfCopies += 1;
                    end;
                    if ReportTitleBol[4] then begin
                        ReportTitleText[4] := Text004;
                        NoOfCopies += 1;
                    end;
                    CompressArray(ReportTitleText);
                    NoOfLoops := Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                CountryInfo: Record "Country/Region";
                State1: Record State;
                Cust: Record Customer;
                Location: Record Location;
                DynaEquipSetup_lRec: Record "Report Date Stnd Setup";
            begin
                CurrSymbol := DynaEquipSetup_lRec.GetCurrencySign_gFnc('');

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.FormatAddr(
                    TransferFromAddr, "Transfer-from Name", "Transfer-from Name 2", "Transfer-from Contact", "Transfer-from Address", "Transfer-from Address 2",
                    "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
                FormatAddr.FormatAddr(
                    TransferToAddr, "Transfer-to Name", "Transfer-to Name 2", "Transfer-to Contact", "Transfer-to Address", "Transfer-to Address 2",
                    "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");

                if not ShipmentMethod.Get("Shipment Method Code") then
                    ShipmentMethod.Init();

                ComAddreText := '';
                if CompInfo.Name <> '' then ComAddreText += '<b>' + CompInfo.Name + '</b>' + '<br/>';
                if CompInfo.Address <> '' then ComAddreText += CompInfo.Address;
                if CompInfo."Address 2" <> '' then ComAddreText += '<br/>' + CompInfo."Address 2";
                if CompInfo.City <> '' then ComAddreText += '<br/>' + CompInfo.City;
                if CompInfo."Post Code" <> '' then ComAddreText += '-' + CompInfo."Post Code";
                if CompInfo."Country/Region Code" <> '' then
                    if CountryInfo.Get(CompInfo."Country/Region Code") then ComAddreText += '<br/>' + CountryInfo.Name;
#pragma warning disable AL0432
                if CompInfo."Home Page" <> '' then ComAddreText += '<br/>Website : ' + CompInfo."Home Page";
#pragma warning restore AL0432
                if CompInfo."State Code" <> '' then
                    if State1.Get(CompInfo."State Code") then ComAddreText += '<br/>State Code : ' + State1.Description + '-' + State1.Code;

                CompressArray(TransferFromAddr);
                TransferFromAddTxt := '';
                if TransferFromAddr[1] <> '' then TransferFromAddTxt += '<b>' + 'Transfer From :' + '</b>' + '<br/>' + Format(TransferFromAddr[1]);
                if TransferFromAddr[2] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[2]);
                if TransferFromAddr[3] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[3]);
                if TransferFromAddr[4] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[4]);
                if TransferFromAddr[5] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[5]);
                if TransferFromAddr[6] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[6]);
                if TransferFromAddr[7] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[7]);
                if TransferFromAddr[8] <> '' then TransferFromAddTxt += '<br/>' + Format(TransferFromAddr[8]);
                if "Transfer-from Customer" <> '' then begin
                    if Cust.Get("Transfer-from Customer") then
                        TransferFromAddTxt += '<br/>GST No.: ' + Cust."GST Registration No."
                end else
                    if Location.Get("Transfer-from Code") then
                        TransferFromAddTxt += '<br/>GST No.: ' + Location."GST Registration No.";

                CompressArray(TransferToAddr);
                TransferToaddTxt := '';
                if TransferToAddr[1] <> '' then TransferToaddTxt += '<b>' + 'Transfer To :' + '</b>' + '<br/>' + Format(TransferToAddr[1]);
                if TransferToAddr[2] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[2]);
                if TransferToAddr[3] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[3]);
                if TransferToAddr[4] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[4]);
                if TransferToAddr[5] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[5]);
                if TransferToAddr[6] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[6]);
                if TransferToAddr[7] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[7]);
                if TransferToAddr[8] <> '' then TransferToaddTxt += '<br/>' + Format(TransferToAddr[8]);
                if "Transfer-to Customer" <> '' then begin
                    if Cust.Get("Transfer-to Customer") then
                        TransferToaddTxt += '<br/>GST No.: ' + Cust."GST Registration No."
                end else
                    if Location.Get("Transfer-to Code") then
                        TransferToaddTxt += '<br/>GST No.: ' + Location."GST Registration No.";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("ReportTitleBol[1]"; ReportTitleBol[1])
                    {
                        ApplicationArea = All;
                        Caption = 'Original for Buyer';
                    }
                    field("ReportTitleBol[2]"; ReportTitleBol[2])
                    {
                        ApplicationArea = All;
                        Caption = 'Duplicate For Transporter';
                    }
                    field("ReportTitleBol[3]"; ReportTitleBol[3])
                    {
                        ApplicationArea = All;
                        Caption = 'Triplicate For Supplier';
                    }
                    field("ReportTitleBol[4]"; ReportTitleBol[4])
                    {
                        ApplicationArea = All;
                        Caption = 'Extra';
                    }
                }
            }
        }

        actions
        {
            // area(processing)
            // {
            //     action(ActionName)
            //     {
            //         ApplicationArea = All;

            //     }
            // }
        }
    }

    rendering
    {
        layout(RDLC)
        {
            Type = RDLC;
            LayoutFile = './FA/Transfer/TransferShipment.rdlc';
        }
    }

    labels
    {
        TransferShipmentLbl = 'DELIVERY CHALLAN';
        PAN_NoLbl = 'P.A.N No.';
        SRNo_lbl = 'SR. No.';
        Quantity_lbl = 'Qty';
        UOM_lbl = 'UOM';
        ReceiverSignatory_Lbl = 'Receiver''s Signature';
        AuthorisedSignatory_lbl = 'Authorised Signatory';
        CINNo_lbl = 'CIN No';
        InvoiceNo_lbl = 'Transfer Shipment No.';
        TransferOrderNo_lbl = 'Transfer Order No.';
        ExternalDocumentNo_lbl = 'External Document No.';
        PricePerUnit_lbl = 'Unit Price';
    }

    trigger OnInitReport()
    begin
        ReportTitleBol[1] := true;
        ReportTitleBol[2] := true;
        ReportTitleBol[3] := true;
        ReportTitleBol[4] := true;
        NoOfCopies := 0;
    end;

    trigger OnPreReport()
    begin
        CompInfo.Get();
        CompInfo.CalcFields(Picture);
        Clear(ReportTitleText);
    end;

    var
        ShipmentMethod: Record "Shipment Method";
        DimSetEntry1: Record "Dimension Set Entry";
        CompInfo: Record "Company Information";
        FAItem: Record "FA Item";
        TransferFromAddr: array[8] of Text[100];
        TransferFromAddTxt: Text;
        TransferToAddr: array[8] of Text[100];
        TransferToaddTxt: Text;
        ReportTitleBol: array[4] of Boolean;
        ReportTitleText: array[4] of Text;
        CopyText: Text[30];
        MoreLines: Boolean;
        ComAddreText: Text;
        i: Integer;
        LotNoSrNoTxt: Text;
        CurrSymbol: Text;
        IGSTPer: Decimal;
        CGSTPer: Decimal;
        SGSTPer: Decimal;
        IGSTAmt: Decimal;
        CGSTAmt: Decimal;
        SGSTAmt: Decimal;
        BaseAmount: Decimal;
        TotalAmount: Decimal;
        LotNo1_gCod: Code[50];

        Text000: Label 'COPY';
        Text001: label 'ORIGINAL FOR RECIPIENT';
        Text002: label 'DUPLICATE FOR TRANSPORTER';
        Text003: label 'TRIPLICATE FOR SUPPLIER';
        Text004: label 'EXTRA';

    protected var
        FormatAddr: Codeunit "Format Address";
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;

    local procedure InitVariables()
    begin
        i := 0;
    end;

    local procedure ResetGSTComp()
    begin
        IGSTPer := 0;
        CGSTPer := 0;
        SGSTPer := 0;
        IGSTAmt := 0;
        CGSTAmt := 0;
        SGSTAmt := 0;
        BaseAmount := 0;
        TotalAmount := 0;
    end;

    local procedure CalculateTaxValues(TaxSetupId: Text; HSNCode: Code[10]; Amount: Decimal; IsSameState: Boolean;
        var IGSTAmt: Decimal; var CGSTAmt: Decimal; var SGSTAmt: Decimal)
    var
        Currency: Record Currency;
    begin
        GetTaxRates(TaxSetupId, FAItem."HSN/SAC Code", IGSTPer, CGSTPer, SGSTPer);


        SGSTAmt := Round((Amount * (SGSTPer / 100)), GetRoundingPrecisionUnitPrice());
        IGSTAmt := Round((Amount * (IGSTPer / 100)), GetRoundingPrecisionUnitPrice());
        CGSTAmt := Round((Amount * (CGSTPer / 100)), GetRoundingPrecisionUnitPrice());
    end;

    local procedure GetTaxRates(TaxSetupId: Text; HSNCode: Code[10]; Var "IGST%": Decimal; var "CGST%": Decimal; var "SGST%": Decimal)
    var
        TaxRate: Record "Tax Rate";
        TaxRateValue: Record "Tax Rate Value";
        TaxRateValue2: Record "Tax Rate Value";
        TaxSetupMatrixMgmt: Codeunit "Tax Setup Matrix Mgmt.";
        TaxRateColumnSetup: Record "Tax Rate Column Setup";
        RangeAttribute: array[1000] of Boolean;
        AttributeValue: array[1000] of Text;
        AttributeCaption: array[1000] of Text;
        AttributeID: array[1000] of Integer;
        GlobalTaxType: Code[20];
        ColumnCount: Integer;
        i: Integer;
        j: Integer;
        id: Guid;
        BalnkGuid: guid;
    begin
        if GlobalTaxType = '' then
            GlobalTaxType := 'GST';
        TaxSetupMatrixMgmt.FillColumnArray(GlobalTaxType, AttributeCaption, AttributeValue, RangeAttribute, AttributeID, ColumnCount);

        TaxRate.Reset();
        TaxRate.SetFilter("Tax Type", GlobalTaxType);
        TaxRate.SetFilter("Tax Setup ID", '%1', TaxSetupId);
        if TaxRate.FindFirst() then
            id := TaxRate.ID;

        // TaxRateValue.Reset();
        // TaxRateValue.SetFilter("Tax Type", '%1', GlobalTaxType);
        // TaxRateValue.SetFilter("Tax Rate ID", '%1', TaxRateId);

        // TaxRateColumnSetup.Reset();
        // TaxRateColumnSetup.SetFilter("Tax Type", GlobalTaxType);
        // TaxRateColumnSetup.SetFilter("Column Name", '%1', 'HSN/SAC');
        // if TaxRateColumnSetup.FindFirst() then
        //     TaxRateValue.SetFilter("Column ID", '%1', TaxRateColumnSetup."Column ID");

        // TaxRateValue.SetFilter(Value, '%1', HSNCode);
        // if TaxRateValue.FindFirst() then
        //     id := TaxRateValue."Config ID";

        if id <> BalnkGuid then begin
            TaxSetupMatrixMgmt.FillColumnValue(id, AttributeValue, RangeAttribute, AttributeID);

            for i := 1 to ColumnCount do begin
                if AttributeCaption[i] = 'IGST %' then begin
                    Evaluate("IGST%", AttributeValue[i]);
                end;
                if AttributeCaption[i] = 'CGST %' then begin
                    Evaluate("CGST%", AttributeValue[i]);
                end;
                if AttributeCaption[i] = 'SGST %' then begin
                    Evaluate("SGST%", AttributeValue[i]);
                end;
            end;
        end;
    end;

    local procedure GetRoundingPrecisionUnitPrice() Precision: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LoopCount: Integer;
    begin
        // if FATrShipLine."Currency Code" = '' then begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Unit-Amount Rounding Precision" <> 0 then
            Precision := GeneralLedgerSetup."Unit-Amount Rounding Precision"
        else begin
            Evaluate(LoopCount, CopyStr(GeneralLedgerSetup."Unit-Amount Decimal Places", StrPos(GeneralLedgerSetup."Unit-Amount Decimal Places", ':') + 1));
            Precision := 1;
            repeat
                LoopCount -= 1;
                Precision := (1 * Precision) / 10
            until LoopCount = 0;
        end;
        // end else begin
        //     Currency.Get(FATrShipLine."Currency Code");
        //     if Currency."Unit-Amount Rounding Precision" <> 0 then
        //         Precision := Currency."Unit-Amount Rounding Precision"
        //     else begin
        //         Evaluate(LoopCount, CopyStr(Currency."Unit-Amount Decimal Places", StrPos(Currency."Unit-Amount Decimal Places", ':') + 1));
        //         Precision := 1;
        //         repeat
        //             LoopCount -= 1;
        //             Precision := (1 * Precision) / 10;
        //         until LoopCount = 0;
        //     end;
        // end;
    end;
}