unit Success;

{$mode ObjFPC}{$H+}

interface

function LeapYear(const year : integer) : boolean;

implementation

uses SysUtils;

function LeapYear(const year : integer) : boolean;
begin
  result := IsLeapYear(year);
end;

end.
