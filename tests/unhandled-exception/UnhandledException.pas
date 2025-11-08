unit UnhandledException;

interface
function SayHi : string;

implementation

uses SysUtils;

function SayHi : string;
const
  four : integer = 4;
  zero : integer = 0;
begin
  SayHi := IntToStr(four div zero);
end;

end.
