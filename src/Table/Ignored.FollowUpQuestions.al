// table 70011 "Follow Up Questions"
// {
//     DataClassification = ToBeClassified;

//     fields
//     {
//         field(50025; "Line No"; Integer)
//         {
//             DataClassification = ToBeClassified;
//             AutoIncrement = true;
//         }
//         field(1; "Question Order"; Integer)
//         {
//             DataClassification = ToBeClassified;

//         }

//         field(2; "Question"; Text[250])
//         {
//             DataClassification = ToBeClassified;

//         }

//         field(3; "Type Follow Up"; Enum "Follow Up Type")
//         {
//             DataClassification = ToBeClassified;

//         }

//         field(4; "weight"; Decimal)
//         {
//             DataClassification = ToBeClassified;
//             InitValue = 10;
//             MinValue = 10;
//             trigger OnValidate()
//             begin
//                 if weight = 0 then Error('Valeur doit être different de zéro (0) !');
//             end;

//         }
//     }

//     keys
//     {
//         key(Key1; "Line No")
//         {
//             Clustered = true;
//         }
//     }

//     var
//         myInt: Integer;

//     trigger OnInsert()
//     begin

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