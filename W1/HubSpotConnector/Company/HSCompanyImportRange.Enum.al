namespace TST.Hubspot.Company;

enum 51300 "Hubspot Company Import Range"
{
    Caption = 'Shopify Company Import Range';
    Extensible = false;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; WithOrderImport)
    {
        Caption = 'With Order Import';
    }
    value(2; AllCompanies)
    {
        Caption = 'All Companies';
    }
}