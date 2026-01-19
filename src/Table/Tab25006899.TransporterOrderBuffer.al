table 25006899 "Transporter Order Buffer"
{
    Caption = 'Transporter Order Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Order ID"; Code[20])
        {
            Caption = 'Order ID';
            DataClassification = CustomerContent;
        }
        field(3; "Delivery Name"; Text[100])
        {
            Caption = 'Delivery Name';
            DataClassification = CustomerContent;
        }
        field(4; "Delivery Address"; Text[250])
        {
            Caption = 'Delivery Address';
            DataClassification = CustomerContent;
        }
        field(5; "Delivery City"; Text[50])
        {
            Caption = 'Delivery City';
            DataClassification = CustomerContent;
        }
        field(6; "Delivery Post Code"; Code[20])
        {
            Caption = 'Delivery Post Code';
            DataClassification = CustomerContent;
        }
        field(7; "Delivery Governorate"; Text[50])
        {
            Caption = 'Delivery Governorate';
            DataClassification = CustomerContent;
        }
        field(8; "Delivery Phone"; Text[50])
        {
            Caption = 'Delivery Phone';
            DataClassification = CustomerContent;
        }
        field(9; "Delivery Email"; Text[80])
        {
            Caption = 'Delivery Email';
            DataClassification = CustomerContent;
        }
        field(10; "Total Colis"; Integer)
        {
            Caption = 'Total Colis';
            DataClassification = CustomerContent;
        }
        field(11; "Type Colis"; Enum "Type Colis")
        {
            Caption = 'Type Colis';
            DataClassification = CustomerContent;
            InitValue = Colis;
        }
        field(12; "Total CR"; Decimal)
        {
            Caption = 'Total CR';
            DataClassification = CustomerContent;
        }
        field(13; "Payment Method"; Text[50])
        {
            Caption = 'Payment Method';
            DataClassification = CustomerContent;
        }
        field(14; "Delivery Status"; Text[50])
        {
            Caption = 'Delivery Status';
            DataClassification = CustomerContent;
        }
        field(15; "Payment Status"; Text[50])
        {
            Caption = 'Payment Status';
            DataClassification = CustomerContent;
        }
        field(16; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }
        field(17; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
        field(18; "Fetched DateTime"; DateTime)
        {
            Caption = 'Fetched DateTime';
            DataClassification = SystemMetadata;
        }
        field(100; "Is Processed"; Boolean)
        {
            Caption = 'Is Processed';
            DataClassification = SystemMetadata;
            Description = 'Marks if the buffer entry has been processed (e.g., created as a sales order).';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Order ID")
        {
            Unique = true;
        }
    }
}