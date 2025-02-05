tableextension 51202 TST_EntrySummery extends "Entry Summary"
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

    procedure SetTrackingFilterFromFAReservEntry(ReservationEntry: Record "FA Reservation Entry")
    begin
        SetRange("Serial No.", ReservationEntry."Serial No.");
        SetRange("Lot No.", ReservationEntry."Lot No.");

        // OnAfterSetTrackingFilterFromReservEntry(Rec, ReservationEntry);
    end;

    procedure SetNonSerialTrackingFilterFromFAReservEntry(ReservEntry: Record "FA Reservation Entry")
    begin
        SetRange("Lot No.", ReservEntry."Lot No.");

        // OnAfterSetNonSerialTrackingFilterFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetTrackingFilterFromFASpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        // OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromFASpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        // OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromFAReservEntry(ReservEntry: Record "FA Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        // OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;
}