program simple;

{
  Copyright    2018, EAB Global, Inc.
  Author       Marcus Fernstrom on behalf of EAB Global, Inc.
  Version      0.2.1
}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  cmem, SysUtils, fphttpapp, httpdefs, httproute, IniFiles;

CONST
  SimpleVersion = '0.2.1';

var
  INI: TINIFile;
  ApplicationPort: Integer;

procedure endpointManager(aRequest : TRequest; aResponse : TResponse);
var
  Counter : Integer;
  UrlMatcher : String;
  ContentType, Header, HeaderValue : String;
begin
  UrlMatcher := RightStr(aRequest.URL, length(aRequest.URL)-1);

  WriteLn(format('Request received at %s for [http://localhost:9080/%s]', [TimeToStr(Time), UrlMatcher]));

  if aRequest.ContentFields.Count > 0 then begin
    WriteLn('Form data');
    for Counter := 0 to aRequest.ContentFields.Count-1 do begin
      WriteLn(format('[%s]', [aRequest.ContentFields[Counter]]));
    end;
  end;

  if INI.SectionExists(UrlMatcher) then begin
    WriteLn(format('Request matched INI section %s', [UrlMatcher]));

    aResponse.Content := INI.ReadString(UrlMatcher, 'Content', '');
    ContentType       := INI.ReadString(UrlMatcher, 'ContentType', '');
    Header            := INI.ReadString(UrlMatcher, 'Header', '');
    HeaderValue       := INI.ReadString(UrlMatcher, 'HeaderValue', '');
    aResponse.Code    := INI.ReadInteger(UrlMatcher, 'Code', 200);

    if length(ContentType) > 0 then
      aResponse.ContentType := 'text/html';

    if (length(Header) > 0) and (length(HeaderValue) > 0) then
      aResponse.SetCustomHeader(Header, HeaderValue);

    aResponse.ContentLength := length(aResponse.Content);
    WriteLn(' ');
    WriteLn('Responding with');
    WriteLn(format('Code [%d]', [aResponse.Code]));
    WriteLn(format('Content [%s]', [aResponse.Content]));
    WriteLn(format('ContentType [%s]', [aResponse.ContentType]));

    aResponse.SendContent;
  end;
  WriteLn(' ');
end;

procedure displayLogo();
begin
  WriteLn('                      .__  .__');
  WriteLn('  ______ _____ _____  |  | |  |');
  WriteLn(' /  ___//     \\__  \ |  | |  |     Copyright EAB Global');
  WriteLn(' \___ \|  Y Y  \/ __ \|  |_|  |__   Author Marcus Fernstrom, on behalf of EAB Global, Inc.');
  WriteLn('/____  >__|_|  (____  /____/____/   version ' + SimpleVersion);
  WriteLn('     \/      \/     \/');
end;

procedure displayHelp();
begin
  WriteLn(' ');
  WriteLn('Simple is a utility to easily run a webserver that dumps out data sent to it, and optionally responds based on a simple INI file.');
  WriteLn('Simple was created by Marcus Fernstrom for EAB Global, Inc. in 2018');
  WriteLn(format('Version %s', [SimpleVersion]));
  WriteLn(' ');
  WriteLn('Example simple.ini');
  WriteLn(' ');
  WriteLn('[myendpoint]');
  WriteLn('Content={"success":true}');
  WriteLn('ContentType=application/json');
  WriteLn('Header=Access-Control-Allow-Origin');
  WriteLn('HeaderValue=*');
  WriteLn('Code=200');
  WriteLn(' ');
  WriteLn('[myotherendpoint]');
  WriteLn('Content={"success":false}');
  WriteLn('ContentType=application/json');
  WriteLn('Header=Access-Control-Allow-Origin');
  WriteLn('HeaderValue=*');
  WriteLn('Code=200');
end;

begin
  INI := TINIFile.Create(Application.Location + 'simple.ini');

  // Parameters are either 'help' or a port number
  if Application.ParamCount > 0 then begin
    if ParamStr(1) = 'help' then begin
      displayLogo();
      displayHelp();
      exit;
    end else
      ApplicationPort := StrToInt(ParamStr(1));
  end else
    ApplicationPort := 9080;

  Application.Port := ApplicationPort;
  HTTPRouter.RegisterRoute('/endpointManager', @endpointManager, true);
  Application.Threaded := true;
  Application.Initialize;
  WriteLn(format('Simple v.%s is ready at http://localhost:%d/', [SimpleVersion, ApplicationPort]));
  Application.Run;
end.
