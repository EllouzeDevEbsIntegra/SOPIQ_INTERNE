table 25006899 "Sales Invoice Feedback"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(3; "Document Profile"; Option)
        {
            Caption = 'Document Profile';
            OptionCaption = ' ,Spare Parts Trade,Vehicles Trade,Service,Rent';
            OptionMembers = " ","Spare Parts Trade","Vehicles Trade",Service,Rent;
        }
        field(4; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(5; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(6; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        field(7; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(8; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(9; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(10; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
        }
        field(11; "Order Creator"; Code[10])
        {
            Caption = 'Order Creator';
            Description = 'Internal';
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(13; "Deal Type Code"; Code[10])
        {
            Caption = 'Deal Type Code';
            TableRelation = "Deal Type";
        }
        field(14; "Service Document"; Boolean)
        {
            Caption = 'Service Document';
        }

        field(15; Amount; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Invoice Line".Amount WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Invoice Line"."Amount Including VAT" WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(18; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(19; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(20; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
        }
        field(21; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }
        field(22; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
        }
        field(23; "Work Description"; TEXT[250])
        {
            Caption = 'Work Description';
        }
        field(24; "Vehicle Registration No."; Code[20])
        {
            Caption = 'Vehicle Registration No.';
        }
        field(25; "Make Code"; Code[20])
        {
            Caption = 'Make Code';
            Description = 'Only For Service or Spare Parts Trade';
            TableRelation = Make;
        }
        field(26; "Model Code"; Code[20])
        {
            Caption = 'Model Code';
            Description = 'Only For Service or Spare Parts Trade';
            TableRelation = Model.Code where("Make Code" = field("Make Code"));
        }
        field(27; "Vehicle Serial No."; Code[20])
        {
            Caption = 'Vehicle Serial No.';
            Description = 'Not for Vehicle Trade';
        }
        field(28; VIN; Code[20])
        {
            Caption = 'VIN';
            Description = 'Only For Service or Spare Parts Trade';
            TableRelation = Vehicle;
        }
        field(29; feedback; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Feedback';
        }
        field(30; "Feedback Date"; Date)
        {
            Caption = 'Feedback Date';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.")
        {
        }
        key(Key3; "Sell-to Customer No.", "External Document No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Sell-to Customer No.", "Order Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Sell-to Customer No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Posting Date")
        {
        }
        key(Key8; "Salesperson Code")
        {
        }
        key(Key9; "Document Profile")
        {
        }
        key(Key10; "Vehicle Serial No.")
        {
        }
        key(Key11; "Service Order No.", "Service Document")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}