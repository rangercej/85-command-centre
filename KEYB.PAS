{$A+,B+,E-,F-,G-,I+,N-,O+,V-,X+}

{$IFDEF debug}
{$L+,D+,S+,R+}
{$ELSE}
{$L-,D-,S-,R-}
{$ENDIF}

unit Keyb;

interface
const
  F1 = 15104;
  F2 = 15360;
  F3 = 15616;
  F4 = 15872;
  F5 = 16128;
  F6 = 16384;
  F7 = 16640;
  F8 = 16896;
  F9 = 17152;
  F10 = 17408;

  CtrlA = 1;
  CtrlB = 2;
  CtrlC = 3;
  CtrlD = 4;
  CtrlE = 5;
  CtrlF = 6;
  CtrlG = 7;
  CtrlH = 8;
  CtrlI = 9;
  CtrlJ = 10;
  CtrlK = 11;
  CtrlL = 12;
  CtrlM = 13;
  CtrlN = 14;
  CtrlO = 15;
  CtrlP = 16;
  CtrlQ = 17;
  CtrlR = 18;
  CtrlS = 19;
  CtrlT = 20;
  CtrlU = 21;
  CtrlV = 22;
  CtrlW = 23;
  CtrlX = 24;
  CtrlY = 25;
  CtrlZ = 26;

  AltA = 7680;
  AltB = 12288;
  AltC = 11776;
  AltD = 8192;
  AltE = 4608;
  AltF = 8448;
  AltG = 8704;
  AltH = 8960;
  AltI = 5888;
  AltJ = 9216;
  AltK = 9472;
  AltL = 9728;
  AltM = 12800;
  AltN = 12544;
  AltO = 6144;
  AltP = 6400;
  AltQ = 4096;
  AltR = 4864;
  AltS = 7936;
  AltT = 5120;
  AltU = 5632;
  AltV = 12032;
  AltW = 4352;
  AltX = 11520;
  AltY = 5376;
  AltZ = 11264;

  CUp    = 18432;
  CDown  = 20480;
  CLeft  = 19200;
  CRight = 19712;
  CPgUP  = 18688;
  CPgDN  = 20736;
  CHome  = 18176;
  CEnd   = 20224;
  CDel   = 21248;
  CIns   = 20992;

function Getkey: word;

implementation
uses crt;

function Getkey: word;
var v: word;
begin
  v:=ord(readkey);
  if v=0 then
    v:=ord(readkey)*256;

  getkey:=v;
end;

end.