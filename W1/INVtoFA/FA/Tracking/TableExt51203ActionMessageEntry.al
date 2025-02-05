tableextension 51203 TST_ActionMessageEntry extends "Action Message Entry"
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

    procedure TransferFromFAReservEntry(var ReservEntry: Record "FA Reservation Entry")
    begin
        "Reservation Entry" := ReservEntry."Entry No.";
        SetSourceFromFAReservEntry(ReservEntry);
        "Location Code" := ReservEntry."Location Code";
        "Variant Code" := ReservEntry."Variant Code";
        "Item No." := ReservEntry."Item No.";
    end;

    procedure SetSourceFromFAReservEntry(ReservEntry: Record "FA Reservation Entry")
    begin
        "Source Type" := ReservEntry."Source Type";
        "Source Subtype" := ReservEntry."Source Subtype";
        "Source ID" := ReservEntry."Source ID";
        "Source Ref. No." := ReservEntry."Source Ref. No.";
        "Source Batch Name" := ReservEntry."Source Batch Name";
        "Source Prod. Order Line" := ReservEntry."Source Prod. Order Line";
    end;

    procedure FilterFromFAReservEntry(var ReservEntry: Record "FA Reservation Entry")
    begin
        SetSourceFilterFromFAReservEntry(ReservEntry);
        SetRange("Location Code", ReservEntry."Location Code");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Item No.", ReservEntry."Item No.");
    end;

    procedure SetSourceFilterFromFAReservEntry(ReservEntry: Record "FA Reservation Entry")
    begin
        SetRange("Source Type", ReservEntry."Source Type");
        SetRange("Source Subtype", ReservEntry."Source Subtype");
        SetRange("Source ID", ReservEntry."Source ID");
        SetRange("Source Ref. No.", ReservEntry."Source Ref. No.");
        SetRange("Source Batch Name", ReservEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ReservEntry."Source Prod. Order Line");
    end;

    procedure FilterToFAReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
        ReservEntry.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
    end;
}