report 50229 "Batch Sending Message"
{
    trigger OnInitReport()
    begin
        Codeunit.Run(Codeunit::"Sopiq SMS Queue Dispatcher");
    end;
}