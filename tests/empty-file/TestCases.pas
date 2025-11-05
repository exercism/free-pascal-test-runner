unit TestCases;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, FPCUnit, TestRegistry, FPCUnitTestUtils;

type
  EmptyFileTest = class(TTestCase)
  published
    procedure SayHi;
  end;

implementation

uses EmptyFile;

// af9ffe10-dc13-42d8-a742-e7bdafac449d
procedure EmptyFileTest.SayHi;
begin
  TapAssertTrue(Self, 'Say Hi!', 'Hello, World!', EmptyFile.SayHi());
end;

initialization
RegisterTest(EmptyFileTest);

end.
