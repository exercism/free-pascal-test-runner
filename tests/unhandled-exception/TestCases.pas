unit TestCases;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, FPCUnit, TestRegistry, FPCUnitTestUtils;

type
  UnhandledExceptionTest = class(TTestCase)
  published
    procedure SayHi;
  end;

implementation

uses UnhandledException;

// af9ffe10-dc13-42d8-a742-e7bdafac449d
procedure UnhandledExceptionTest.SayHi;
begin
  TapAssertTrue(Self, 'Say Hi!', 'Hello, World!', UnhandledException.SayHi());
end;

initialization
RegisterTest(UnhandledExceptionTest);

end.
