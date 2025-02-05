namespace TSTChanges.FA.Transfer;
using Microsoft.Inventory.Location;

page 51231 "Posted FA Transfer Ship-Update"
{
    Caption = 'Posted FA Transfer Ship-Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "FA Transfer Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                group(TransferFrom)
                {
                    Caption = 'From-Customer';
                    Visible = IsFromCustomerVisible;
                    field("Transfer-from Customer"; Rec."Transfer-from Customer")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                group(TransferTo)
                {
                    Caption = 'To-Customer';
                    Visible = IsToCustomerVisible;
                    field("Transfer-to Customer"; Rec."Transfer-to Customer")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the FA Transfer document to the customer/location.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer/location.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        XFATranShipHdr := Rec;
        ActivateCustomerFields();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                UpdateRecord();
    end;

    var
        XFATranShipHdr: Record "FA Transfer Shipment Header";

    protected Var
        IsFromCustomerVisible: Boolean;
        IsToCustomerVisible: Boolean;

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipping Agent Code" <> XFATranShipHdr."Shipping Agent Code") or
          (Rec."Package Tracking No." <> XFATranShipHdr."Package Tracking No.") or
          (Rec."Shipping Agent Service Code" <> XFATranShipHdr."Shipping Agent Service Code");
    end;

    procedure SetRec(FATransShip: Record "FA Transfer Shipment Header")
    begin
        Rec := FATransShip;
        Rec.Insert();
    end;

    local procedure UpdateRecord()
    var
        FaTranShipHdr: Record "FA Transfer Shipment Header";
    begin
        FaTranShipHdr := Rec;
        FaTranShipHdr.LockTable();
        FaTranShipHdr.Find();
        FaTranShipHdr."Shipping Agent Code" := Rec."Shipping Agent Code";
        FaTranShipHdr."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        FaTranShipHdr."Package Tracking No." := Rec."Package Tracking No.";
        FaTranShipHdr.TestField("No.", Rec."No.");
        FaTranShipHdr.Modify();
        Rec := FaTranShipHdr;
    end;

    local procedure ActivateCustomerFields()
    var
        Location: Record Location;
    begin
        if Location.Get(Rec."Transfer-from Code") then
            IsFromCustomerVisible := Location."Demo Location";

        if Location.Get(Rec."Transfer-to Code") then
            IsToCustomerVisible := Location."Demo Location";
    end;
}