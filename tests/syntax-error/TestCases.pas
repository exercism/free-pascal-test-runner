unit TestCases;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, FPCUnit, TestRegistry, FPCUnitTestUtils;

type
  SyntaxErrorTest = class(TTestCase)
  published
    procedure SayHi;
  end;

implementation

uses SyntaxError;

// af9ffe10-dc13-42d8-a742-e7bdafac449d
procedure SyntaxErrorTest.SayHi;
begin
  TapAssertTrue(Self, 'Say Hi!', 'Hello, World!', SyntaxError.SayHi());
end;

initialization
RegisterTest(SyntaxErrorTest);

end.
