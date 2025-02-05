namespace TSTChanges.FA.Transfer;

using System.Environment.Configuration;
using TSTChanges.FA.Posting;
using Microsoft.Finance.Dimension;

page 51217 "FA Transfer Orders"
{
    ApplicationArea = Location;
    Caption = 'FA Transfer Orders';
    CardPageID = "FA Transfer Order";
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "FA Transfer Header";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-from Customer"; Rec."Transfer-from Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the customer that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Transfer-to Customer"; Rec."Transfer-to Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the customer that the items are transferred to.';
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies whether the transfer order is open or has been released for warehouse handling.';
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = NOT IsFoundationEnabled;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies an instruction to the warehouse that ships the items, for example, that it is acceptable to do partial shipment.';
                    Visible = false;
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the shipment.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(Processing)
        {
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action("Re&lease")
                {
                    ApplicationArea = Location;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action("Reo&pen")
                {
                    ApplicationArea = Location;
                    Caption = 'Reo&pen';
                    Image = ReOpen;
                    ToolTip = 'Reopen the transfer order after being released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseTransferDoc: Codeunit "Release FA Transfer Document";
                    begin
                        ReleaseTransferDoc.PerformManualReopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Location;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"FATransferOrder-Post (Yes/No)", Rec);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Location;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ShowAs = SplitButton;

                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("Reo&pen_Promoted"; "Reo&pen")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';
                ShowAs = SplitButton;

                actionref(Post_Promoted; Post)
                {
                }
                actionref(PreviewPosting_Promoted; PreviewPosting)
                {
                }
                // actionref(PostAndPrint_Promoted; PostAndPrint)
                // {
                // }
                // actionref(BatchPost_Promoted; BatchPost)
                // {
                // }
            }
            group(Category_Category6)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsFoundationEnabled := ApplicationAreaMgmtFacade.IsFoundationEnabled();
    end;

    var
        IsFoundationEnabled: Boolean;

    local procedure ShowPreview()
    var
        TransferOrderPostYesNo: Codeunit "FATransferOrder-Post (Yes/No)";
    begin
        TransferOrderPostYesNo.Preview(Rec);
    end;
}