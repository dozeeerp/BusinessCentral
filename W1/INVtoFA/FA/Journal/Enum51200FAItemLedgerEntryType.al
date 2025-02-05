namespace TSTChanges.FA.Journal;

enum 51200 "FA Item Ledger Entry Type"
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Transfer") { Caption = 'Transfer'; }
    value(2; "Conversion Output") { Caption = 'Conversion Output'; }
    value(3; "Negative Adjmt.") { Caption = 'Negative Adjmt.'; }
    value(4; "Positive Adjmt.") { Caption = 'Positive Adjmt.'; }
}