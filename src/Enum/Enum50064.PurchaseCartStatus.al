enum 50064 "Purchase Cart Status"
{
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Verified)
    {
        Caption = 'Verified';
    }
    value(2; "Converted to Quote")
    {
        Caption = 'Converted to Quote';
    }
    value(3; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
