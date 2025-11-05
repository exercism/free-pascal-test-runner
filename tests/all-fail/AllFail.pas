unit AllFail;

{$mode ObjFPC}{$H+}

interface

function abbreviate(const phrase: string) : string;

implementation

uses SysUtils;

function abbreviate(const phrase: string) : string;
begin

  result := phrase;

end;

end.
