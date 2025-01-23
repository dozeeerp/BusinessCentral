// xmlport 53001 "Export ILE"
// {
//     Caption = 'Export ILE';
//     Direction = Export;
//     FieldSeparator = '<TAB>';
//     Format = VariableText;
//     TableSeparator = '<NewLine>';
//     Description = 'T37794';

//     schema
//     {
//     textelement(root)
//     {
//     XmlName = 'Root';

//     tableelement(Integer;
//     Integer)
//     {
//     XmlName = 'ItemLedgerEntryHeader';
//     SourceTableView = sorting(Number)where(Number=const(1));

//     textelement(EntryTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         EntryTitle:=ItemLedgEntry_gRec.FieldCaption("Entry No.");
//     end;
//     }
//     textelement(PostingDateTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         PostingDateTitle:=ItemLedgEntry_gRec.FieldCaption("Posting Date");
//     end;
//     }
//     textelement(DocumentNoTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         DocumentNoTitle:=ItemLedgEntry_gRec.FieldCaption("Document No.");
//     end;
//     }
//     textelement(ItemNoTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         ItemNoTitle:=ItemLedgEntry_gRec.FieldCaption("Item No.");
//     end;
//     }
//     textelement(DescriptionTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         DescriptionTitle:=ItemLedgEntry_gRec.FieldCaption(Description);
//     end;
//     }
//     textelement(SerialNoTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         SerialNoTitle:=ItemLedgEntry_gRec.FieldCaption("Serial No.");
//     end;
//     }
//     textelement(CustomerNameTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         CustomerNameTitle:='Customer Name';
//     end;
//     }
//     textelement(LocationCodeTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         LocationCodeTitle:=ItemLedgEntry_gRec.FieldCaption("Location Code");
//     end;
//     }
//     textelement(RemainingQuantityTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         RemainingQuantityTitle:=ItemLedgEntry_gRec.FieldCaption("Remaining Quantity");
//     end;
//     }
//     textelement(CostAmountActualTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         CostAmountActualTitle:='Cost Amount Actual';
//     end;
//     }
//     textelement(CostAmtTotalIncExpectedTitle)
//     {
//     trigger OnBeforePassVariable()
//     begin
//         CostAmtTotalIncExpectedTitle:='Cost Amount Total Including Expected';
//     end;
//     }
//     }
//     tableelement("Item Ledger Entry";
//     "Item Ledger Entry")
//     {
//     RequestFilterFields = "Date Filter", "Item No.";
//     XmlName = 'ItemLedgerEntry';
//     SourceTableView = sorting("Entry No.")where("Inbound Quantity"=filter(<>0));

//     fieldelement(EntryNo;
//     "Item Ledger Entry"."Entry No.")
//     {
//     }
//     fieldelement(PostingDate;
//     "Item Ledger Entry"."Posting Date")
//     {
//     }
//     fieldelement("DocumentNo.";
//     "Item Ledger Entry"."Document No.")
//     {
//     }
//     fieldelement("ItemNo.";
//     "Item Ledger Entry"."Item No.")
//     {
//     }
//     textelement(ItemNo_gTxt)
//     {
//     }
//     fieldelement("SerialNo.";
//     "Item Ledger Entry"."Serial No.")
//     {
//     }
//     textelement(CustName_gTxt)
//     {
//     }
//     fieldelement(LocationCode;
//     "Item Ledger Entry"."Location Code")
//     {
//     }
//     fieldelement(RemainingQuantity;
//     "Item Ledger Entry"."Inbound Quantity")
//     {
//     }
//     textelement(CostAmountAct_gTxt)
//     {
//     }
//     textelement(CostAmtExpected_gTxt)
//     {
//     }
//     trigger OnAfterGetRecord()
//     var
//         Customer_lRec: Record Customer;
//         Item_lRec: Record Item;
//         ValEntry_lRec: Record "Value Entry";
//         CostAmountAct_lDec: Decimal;
//         CostAmountExpected_lDec: Decimal;
//         TotalCostAmt_lDec: Decimal;
//         UnitRate1_lDec: Decimal;
//         UnitRate2_lDec: Decimal;
//         TotalActAmt_lDec: Decimal;
//         TotalExpAmt_lDec: Decimal;
//         TransferShipmentHeader_lRec: Record "Transfer Shipment Header";
//         TransferReceiptHeader_lRec: Record "Transfer Receipt Header";
//     begin
//         Curr_gIn+=1;
//         Window_gDlg.Update(2, Curr_gIn);
//         "Item Ledger Entry".CalcFields("Inbound Quantity");
//         if "Item Ledger Entry"."Inbound Quantity" = 0 then currXMLport.Skip();
//         CustName_gTxt:='';
//         if "Item Ledger Entry"."Entry Type" = "Item Ledger Entry"."Entry Type"::Transfer then begin
//             if "Item Ledger Entry"."Customer No." <> '' then begin
//                 if Customer_lRec.Get("Item Ledger Entry"."Customer No.")then CustName_gTxt:=Customer_lRec.Name;
//             end;
//         end
//         else
//         begin
//             if "Item Ledger Entry"."Source Type" = "Item Ledger Entry"."Source Type"::Customer then begin
//                 if Customer_lRec.Get("Item Ledger Entry"."Source No.")then CustName_gTxt:=Customer_lRec.Name;
//             end;
//         end;
//         if Item_lRec.get("Item Ledger Entry"."Item No.")then ItemNo_gTxt:=Item_lRec.Description
//         else
//             ItemNo_gTxt:='';
//         CostAmountAct_gTxt:='';
//         CostAmtExpected_gTxt:='';
//         CostAmountAct_lDec:=0;
//         CostAmountExpected_lDec:=0;
//         TotalCostAmt_lDec:=0;
//         ValEntry_lRec.Reset();
//         ValEntry_lRec.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
//         if "Item Ledger Entry"."Posting Date" <= "Item Ledger Entry".GetRangeMax("Date Filter")then ValEntry_lRec.SetFilter("Posting Date", '%1..%2', 0D, "Item Ledger Entry".GetRangeMax("Date Filter"));
//         if ValEntry_lRec.FindSet()then begin
//             repeat CostAmountAct_lDec+=ValEntry_lRec."Cost Amount (Actual)";
//                 CostAmountExpected_lDec+=ValEntry_lRec."Cost Amount (Expected)";
//             until ValEntry_lRec.Next() = 0;
//         end;
//         UnitRate1_lDec:=0;
//         if CostAmountAct_lDec <> 0 then UnitRate1_lDec:=CostAmountAct_lDec / "Item Ledger Entry".Quantity;
//         UnitRate2_lDec:=0;
//         If CostAmountExpected_lDec <> 0 then UnitRate2_lDec:=CostAmountExpected_lDec / "Item Ledger Entry".Quantity;
//         TotalActAmt_lDec:=0;
//         TotalActAmt_lDec:=(UnitRate1_lDec * "Item Ledger Entry"."Inbound Quantity");
//         TotalExpAmt_lDec:=0;
//         TotalExpAmt_lDec:=(UnitRate1_lDec * "Item Ledger Entry"."Inbound Quantity") + (UnitRate2_lDec * "Item Ledger Entry"."Inbound Quantity");
//         TotalCostAmt_lDec:=CostAmountAct_lDec + CostAmountExpected_lDec;
//         CostAmountAct_gTxt:=format(TotalActAmt_lDec, 0, '<Precision,2:2><Standard Format,0>');
//         CostAmtExpected_gTxt:=format(TotalExpAmt_lDec, 0, '<Precision,2:2><Standard Format,0>');
//         CleanCRLFTAB_gFnc(ItemNo_gTxt);
//     end;
//     trigger OnPreXmlItem()
//     begin
//         Window_gDlg.Update(1, "Item Ledger Entry".Count);
//         CustName_gTxt:='';
//     end;
//     }
//     }
//     }
//     requestpage
//     {
//         layout
//         {
//         }
//         actions
//         {
//         }
//     }
//     trigger OnPostXmlPort()
//     begin
//         Window_gDlg.Close;
//     end;
//     trigger OnPreXmlPort()
//     begin
//         Window_gDlg.Open('Total Lines #1###########\Current Line #2##########');
//     end;
//     procedure CleanCRLFTAB_gFnc(var InputTxt_vTxt: Text[250])
//     var
//         Ch: Text[3];
//     begin
//         //DELETE TAB Char
//         Ch[1]:=9; // TAB
//         Ch[2]:=13; // CR - Carriage Return
//         Ch[3]:=10; // LF - Line Feed
//         InputTxt_vTxt:=DelChr(InputTxt_vTxt, '=', Ch);
//     end;
//     var ItemLedgEntry_gRec: Record "Item Ledger Entry";
//     Window_gDlg: Dialog;
//     Curr_gIn: Integer;
//     Text000: label 'Total #1##############\';
//     Text001: label 'Current #2##############';
// }
