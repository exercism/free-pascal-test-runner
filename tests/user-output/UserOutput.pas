unit UserOutput;

{$mode ObjFPC}{$H+}

interface

function abbreviate(const phrase: string) : string;

implementation

uses SysUtils, StrUtils;

function abbreviate(const phrase: string) : string;
begin

  writeln(DupeString(phrase, 20));

  result := phrase;

end;

end.
