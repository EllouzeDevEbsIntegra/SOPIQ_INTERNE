// table 70013 "Follow Up Header"
// {
//     DrillDownPageID = "Follow Up List";
//     LookupPageID = "Follow Up Card";
//     DataCaptionFields = No, "Sales Invoice No";

//     fields
//     {
//         field(1; No; Integer)
//         {
//             DataClassification = ToBeClassified;
//             AutoIncrement = true;
//         }

//         field(2; "Sales Invoice No"; code[20])
//         {
//             DataClassification = ToBeClassified;
//             TableRelation = "Sales Invoice Header";
//         }

//         field(3; "Sales Invoice Date"; date)
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(4; "Customer No"; code[20])
//         {
//             DataClassification = ToBeClassified;
//             TableRelation = Customer;
//         }

//         field(5; "Customer Name"; Text[100])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(6; "Customer Phone No"; text[50])
//         {
//             DataClassification = ToBeClassified;
//         }
//         field(7; "Customer Adress"; text[250])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(8; "Date"; DateTime)
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(9; "Service Order No"; code[20])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(10; "Service Order Date"; Date)
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(11; "Service Order Type"; Text[100])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(12; "Work Description"; Text[1000])
//         {
//             DataClassification = ToBeClassified;
//         }
//         field(13; "Salesperson Code"; code[20])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(20; statut; Enum "Follow Up Statut")
//         {
//             DataClassification = ToBeClassified;
//             InitValue = Created;
//         }

//         field(21; type; Enum "Follow Up Type")
//         {
//             DataClassification = ToBeClassified;
//             InitValue = SAV;
//         }

//         field(22; "Comment"; Text[2048])
//         {
//             DataClassification = ToBeClassified;
//         }

//         field(23; note; Decimal)
//         {
//             DataClassification = ToBeClassified;
//             InitValue = 0;

//         }




//     }

//     keys
//     {
//         key(Key1; No)
//         {
//             Clustered = true;
//         }
//     }


//     trigger OnInsert()
//     begin
//         Date := System.CurrentDateTime()
//     end;

//     trigger OnModify()
//     begin

//     end;

//     trigger OnDelete()
//     begin

//     end;

//     trigger OnRename()
//     begin

//     end;



// }