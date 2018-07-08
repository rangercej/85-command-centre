{$A+,B+,E-,F-,G-,I+,N-,O+,R-,V-,X+}

{$IFDEF debug}
{$L+,D+,S+}
{$ELSE}
{$L-,D-,S-}
{$ENDIF}

unit t85cc_lk;

interface
var first: boolean;
    pause: boolean;
    skip:  boolean;
    stop:  boolean;

 procedure SetComms(commprt: byte);
 procedure SetPort(Bits:Byte);
 function  GetPort:Byte;
 procedure Send(B:Byte);
 function receive:Byte;
 procedure InitPort;
 procedure InitLink;


implementation

uses crt,dos,t85cc_rl;

var PortAddr: word;
    tmp: longint;


  function GetTicks: longint;
  var regs: registers;
  begin
    regs.ah:=0;
    intr ($1A,regs);
    getticks:=(regs.cx*65536)+regs.dx;
  end;


(****** Procedure to set commport This MUST be called before initport: *)

  procedure SetComms(commprt: byte);
  begin
    case commprt of
      1: PortAddr:=$3f8;
      2: PortAddr:=$2f8;
      3: PortAddr:=$3e8;
      4: PortAddr:=$2e8;
      else PortAddr:=$3f8;
    end;
  end;


(****** Procedure to set/reset RTS/DTR: *)

 procedure SetPort(Bits:Byte);
 { Input: "Bits", a byte 0 - 3, bit 0 = DTR, bit 1 = RTS }

 begin
   Port[PortAddr+4]:=Bits and 3;
 end;

(****** Function to read CTS/DSR: *)

 function  GetPort:Byte;
 { Returns a byte 0 - 3, bit 0 = CTS, bit 1 = DSR }
 { if GetPort returns 0, then the calculator have noticed a timeout }

 begin
   GetPort:=(Port[PortAddr+6] and 48) div 16;
   if KeyPressed then begin
     initport;
     ClearKeybBuf;
     STOP:=TRUE;
   end else
     Stop:=FALSE;

   { Add the line above if you don't add a timeout-check somewhere else. }
   { The program will probably hang in "GetPort" when the calculator     }
   { causes a Timeout }
 end;

(****** To send a byte to the TI85/TI82: *)

 procedure Send(B:Byte);
 { Sends the byte B to the calculator }

 var
    BitLoop:Byte;
    clk: longint;

 begin
   if skip then exit;

   { Send the bits from bit 0 -> bit 7 }
   SetPort(3);
   for BitLoop:=0 to 7 do begin
       clk:=getticks;
       { Wait for calculator to be ready to receive a bit }
       { RTS and DTR must be set }
     while GetPort<>3 do begin
       if stop then exit;
       if ((getticks-clk) >= 55) then begin
         writeln;
         writeln ('Timeout error on send');
         initport;
         delay (2000);
         stop:=TRUE;
         exit;
       end;
     end;

     if (B and 1)=0 then begin
          { Send 0 : DTR=1, DSR=0 }
        SetPort(1);
          { Wait for calculator to set RTS=1 }
        while (GetPort and 2)=2 do begin
          if stop then exit;
          if ((getticks-clk) >= 55) then begin
            writeln;
            writeln ('Timeout error on send');
            initport;
            delay (2000);
            stop:=TRUE;
            exit;
          end;
        end;
          { CTS=1, DSR=1 }
        SetPort(3);
          { Wait for calculator to set RTS=0 }
        clk:=getticks;
        while (GetPort and 2)=0 do begin
          if stop then exit;
          if ((getticks-clk) >= 55) then begin
            writeln;
            writeln ('Timeout error on send');
            initport;
            delay (2000);
            stop:=TRUE;
            exit;
          end;
        end;
     end else begin
          { Send 1 : CTS=0, DSR=1 }
        SetPort(2);
          { Wait for calculator to set DTR=1 }
        while (GetPort and 1)=1 do begin
          if stop then exit;
          if ((getticks-clk) >= 55) then begin
            writeln;
            writeln ('Timeout error on send');
            initport;
            delay (2000);
            stop:=TRUE;
            exit;
          end;
        end;
          { CTS=1, DSR=1 }
        SetPort(3);
          { Wait for calculator to set DTR=0 }
        clk:=getticks;
        while (GetPort and 1)=0 do begin
          if stop then exit;
          if ((getticks-clk) >= 55) then begin
            writeln;
            writeln ('Timeout error on send');
            initport;
            delay (2000);
            stop:=TRUE;
            exit;
          end;
        end;

     end;
     B:=B div 2;
   end;
 end;

(****** To receive a byte from the TI85/TI82: *)

 function receive:Byte;
 { receives a byte from calculator }

 var
    B,CurrentBit,BitLoop:Byte;
    clk: longint;

 begin
   if skip then exit;

   CurrentBit:=1;
   B:=0;
   { receive bit 0 first }
   SetPort(3);
   for BitLoop:=0 to 7 do begin
     clk:=getticks;
       { Wait for the calculator to send a bit }
     while GetPort=3 do begin
       if stop then exit;
       if ((not first) AND (not pause)) then
         if ((getticks-clk) >= 55) then begin
           writeln;
           writeln ('Timeout error on receive');
           initport;
           delay (2000);
           stop:=TRUE;
           exit;
         end;
     end;

       { Check it the calculator sends a 1 or 0 }
     if GetPort=1 then begin
        if stop then exit;
        { 1 }
        B:=B or CurrentBit;
          { CTS=1, DSR=0 }
        SetPort(1);
          { Wait while RTS=0 }
        clk:=getticks;
        while (GetPort and 2)=0 do begin
          if stop then exit;
          if ((not first) AND (not pause)) then
            if ((getticks-clk) >= 55) then begin
              writeln;
              writeln ('Timeout error on receive');
              initport;
              delay (2000);
              stop:=TRUE;
              exit;
            end;
        end;
     end else begin
        { 0 }
          { CTS=0, DSR=1 }
        SetPort(2);
          { Wait while DTR=0 }
        clk:=getticks;
        while (GetPort and 1)=0 do begin
          if stop then exit;
          if ((not first) AND (not pause)) then
            if ((getticks-clk) >= 55) then begin
              writeln;
              writeln ('Timeout error on receive');
              initport;
              delay (2000);
              stop:=TRUE;
              exit;
            end;
        end;
     end;
       { CTS=1, DSR=1 }
     SetPort(3);
       { Wait for calculator to set RTS & DTR }
(*     while GetPort<>3 do; *)
     CurrentBit:=CurrentBit*2;
   end;
   receive:=B;
 end;


(****** Initiates the com-port (MUST be called before anything else) *)

 procedure InitPort;

 begin
   Port[PortAddr+1]:=0;
   Port[PortAddr+2]:=1;
   Port[PortAddr+3]:=0;
   Port[PortAddr+4]:=3;
   Port[PortAddr+5]:=96;
   Port[PortAddr+6]:=50;
   Port[PortAddr+7]:=0;
      { Set CTS & DSR }
   SetPort(3);
 end;

 procedure InitLink;
 begin
   setcomms(1);
   initport;
   skip:=FALSE;
   pause:=FALSE;
   stop:=FALSE;
   first:=TRUE;
 end;

end.

