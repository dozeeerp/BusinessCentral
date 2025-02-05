namespace TSTChanges.FA.Tracking;

using Microsoft.Inventory.Tracking;
using TSTChanges.FA.Ledger;

tableextension 51201 TST_ItemTrackinSetup extends "Item Tracking Setup"
{
    fields
    {
        // Add changes to table fields here
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    procedure CopyTrackingFromFATrackingSpec(TrackingSpecification: Record "FA Tracking Specification");
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        // OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromNewFATrackingSpec(TrackingSpecification: Record "FA Tracking Specification");
    begin
        "Serial No." := TrackingSpecification."New Serial No.";
        "Lot No." := TrackingSpecification."New Lot No.";

        // OnAfterCopyTrackingFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CheckFATrackingMismatch(TrackingSpecification: Record "FA Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        if "Serial No." <> '' then
            "Serial No. Mismatch" :=
                ItemTrackingCode."SN Specific Tracking" and (TrackingSpecification."Serial No." <> "Serial No.");
        if "Lot No." <> '' then
            "Lot No. Mismatch" :=
                ItemTrackingCode."Lot Specific Tracking" and (TrackingSpecification."Lot No." <> "Lot No.");

        // OnAfterCheckTrackingMismatch(Rec, TrackingSpecification, ItemTrackingCode);
    end;

    procedure CopyTrackingFromFAItemLedgerEntry(ItemLedgerEntry: Record "FA Item ledger Entry");
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        // OnAfterCopyTrackingFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromFAReservEntry(ReservEntry: Record "FA Reservation Entry");
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        // OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;
}