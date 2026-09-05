report 25006154 "Etat Art. Transf. Mg STK"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Report/RDLC/EtatArtTransfMgStk.rdl';
    Caption = 'Etat articles à transférer depuis Mg Stockage';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where("Sous Min Mg Principal" = const(true));
            RequestFilterFields = "No.", "Manufacturer Code";

            column(No_; "No.")
            {
            }
            column(Description; Description)
            {
            }
            column(MainQty; MainQty)
            {
            }
            column(Default_Bin; "Default Bin")
            {
            }
            column(StorageQty; StorageQty)
            {
            }
            column(Qte_Min_Mg_Principal; "Qte Min Mg Principal")
            {
            }
            column(CompName; CompName)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Item.setMgPrincipalFilter(Item);
                Item.CalcFields(Item."MainQty", Item."StorageQty", Item."Default Bin");
            end;
        }
    }

    trigger OnPreReport()
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then
            CompName := CompanyInfo.Name
        else
            CompName := CompanyName();
    end;

    var
        CompName: Text[100];
}
