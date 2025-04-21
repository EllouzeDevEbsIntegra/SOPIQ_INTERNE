page 25006834 "Si Picture API"
{
    Caption = 'SIPictureAPI', Locked = true;
    DelayedInsert = true;
    EntityName = 'SIPictureAPI';
    EntitySetName = 'SIPictureAPI';
    ODataKeyFields = "No.";
    PageType = API;
    SourceTable = "Picture";
    SourceTableTemporary = true;
    Permissions = TableData Picture = RM;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(no; "No.")
                {
                    Caption = 'No.';
                }
                field(sourceType; "Source Type")
                {
                    Caption = 'Source Type';
                }
                field(sourceSubtype; "Source Subtype")
                {
                    Caption = 'Source Subtype';
                }
                field(sourceId; "Source ID")
                {
                    Caption = 'Source ID';
                }
                field(sourceRefNo; "Source Ref. No.")
                {
                    Caption = 'Source Ref. No.';
                }
                field(description; Description)
                {
                    Caption = 'Description';
                }
                field(imported; Imported)
                {
                    Caption = 'Imported';
                }
                field(isDefault; Default)
                {
                    Caption = 'Is Default';
                }
                field(blob; Blob)
                {
                    Caption = 'Blob';
                }
                field(thumbnail; Thumbnail)
                {
                    Caption = 'Thumbnail';
                }
                field(noSeries; "No. Series")
                {
                    Caption = 'No. Series';
                }
                field(date; Date)
                {
                    Caption = 'Date';
                }
                field(time; Time)
                {
                    Caption = 'Time';
                }
                field(userId; "User ID")
                {
                    Caption = 'User ID';
                }
                field(vehicleSerialNo; "Vehicle Serial No.")
                {
                    Caption = 'Vehicle Serial No.';
                }
                field(versionNo; "Version No.")
                {
                    Caption = 'Version No.';
                }
                field(docNoOccurrence; "Doc. No. Occurrence")
                {
                    Caption = 'Doc. No. Occurrence';
                }
            }
        }
    }

}

