{$A+,B+,E-,F-,G-,I+,N-,O+,V-,X+}

{$IFDEF debug}
{$L+,D+,S+,R+}
{$ELSE}
{$L-,D-,S-,R-}
{$ENDIF}

unit T85CC_RL;

(*************************************************************************
** Run-time library.
** All the common routines between everything (I hope :)
*************************************************************************)

interface
uses dos;

type scrtype = array[0..3999] of byte;
     cfgtype = record
       initpath: pathstr;
       comport:  byte;
     end;
     msgarry = array[1..15] of string[80];

const vnum = '0.51.2';
      numitems = 8;
      menuitems: array[1..numitems] of string[20] = ('&1.  &Receive','&2.  &Send','&3.  &Comment','&4.  &Group',
                                                     '&5.  &Lock','&6.  S&etup','&7.  &About','&8.  &Quit');
      suff: string = 'NCVVLLMMKKERSDDDDIPR RRRRRRR                         ';

      up = -1;
      down = 1;

      dispID: word = 1;
      ESUDCtrl: byte = 0;


var QUIT: boolean;
    SETUP: boolean;
    UNLOCK: boolean;
    bar : byte;
    sscr: array[1..10] of scrtype;
    conf: cfgtype;
    stpath: string;
    prgpath: pathstr;

    tmpw1,tmpw2: word;
    cursz: word;  { Store cursor state }

  function  GetComment (fname: pathstr): string;
  procedure PutInfo (ln: byte; s: string);

  procedure PutStatus (s: string);
  procedure ShowBar (pos: byte);
  procedure RemoveBar (pos: byte);
  procedure MoveBar (dir: shortint);
  procedure SaveSetup;
  function  SaveDisplay: word;
  procedure PutDisplay (savedpage: byte);
  procedure ErrorMessage (m: msgarry; b: byte);

  procedure PutBorder;

  procedure Center (lne : byte; txt : string;col : word);
  function  GetString (stx,sty,maxx : integer;shw : string;col1,col2 : word;outc : string):string;
  function  EditString (stx,sty,maxx: integer; fore_col,back_col: byte; Edi_Str: string; SKey: word): string;
  procedure CursorOn;
  procedure CursorOff;
  procedure ClearKeybBuf;
  procedure WaitKey;
  procedure Note (freq,dur: word);
  procedure ChDrv (s: string);
  function  UpStr (s: string): string;

  procedure InitConfig;
  procedure RestoreDrvDir;


implementation
uses crt,keyb;

function GetComment (fname: pathstr): string;
var inf: file of char;
    s: string[50];
    b: char;
    j: byte;
    i: byte;
begin
  assign (inf,fname);
  reset (inf);
  s:='';
  seek (inf,$B);
  for i:=1 to $2A do begin
    read (inf,b);
    s:=s+b;
  end;

  j:=pos(#0,s);
  if j>0 then
    s:=copy(s,1,j);

  getcomment:=s;
  close (inf);
end;

  procedure EditStringUserDef (var s: string);
  type scrntype = array[0..3999] of byte;
  const Drv: boolean = FALSE;
  var i: byte;
      scrn: scrntype;
      dis: scrntype absolute $B800:0;
      txat: byte;
      winh,winl: word;
      found: searchrec;
      x,y,c,ch: word;
      f: array[1..70] of record
           name: string[13];
           sys:  byte;
         end;
      barp: shortint;

  procedure DefFnBox (s: string);
  begin
    window (3,23,79,23);
    textbackground (black);
    clrscr;
    gotoxy (1,1);
    write (s);
    window (3,7,79,21);
    textbackground (blue);
  end;

  procedure PutHighlight(p: shortint);
  begin
    x:=(p div 14)+1;
    y:=(p mod 14);

    if y=0 then begin y:=14; x:=x-1; end;
    gotoxy ((x*16)-15,y);
    textbackground (green);
    write (f[p].name);
  end;

  procedure ZapHighlight(p: shortint);
  begin
    x:=(p div 14)+1;
    y:=(p mod 14);

    if y=0 then begin y:=14; x:=x-1; end;
    gotoxy ((x*16)-15,y);
    textbackground (blue);
    write (f[p].name);
  end;

  procedure GetDrives;
  begin
    Drv:=TRUE;
    sound (2500);
    delay (200);
    nosound;
  end;

  begin
    (** User def'n = File selection **)

    if ESUDCtrl=0 then exit;

    chdrv (s);
    chdir (s);

    txat:=textattr;
    scrn:=dis;
    winh:=windmax;
    winl:=windmin;

    window (1,6,80,24);
    textbackground (blue);
    textcolor (white);
    clrscr;

    window (1,6,80,25);
    write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('บ                                                                              บ');
    write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');

    textcolor (yellow);
    textbackground (black);
    write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
    write ('บ                                                                              บ');
    write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');

    window (1,25,80,25);
    textcolor (blue);
    textbackground (cyan);
    clrscr;
    write (' ',#24,#25,#27,#26,' - Move highlight          '+#17+'ฤู - Select          ESC - Back to previous');

    repeat
      Drv:=FALSE;
      textbackground (blue);
      textcolor (white);
      window (3,7,79,20);
      clrscr;
      findfirst ('*.*',AnyFile,Found);
      x:=1; y:=1;
      c:=0;
      while doserror=0 do begin
        case ESUDCtrl of
          1: if (found.attr AND directory)<>0 then begin
               inc (c);
               gotoxy (x,y);
               write (Found.name);
               f[c].name:=found.name;
               f[c].sys:=found.attr;
               inc (y);
               if (y > 14) then begin
                 y:=1;
                 x:=x+16;
               end;
             end;
          2: if ((found.attr AND Directory)<> 0) OR
                ((pos('.85',found.name) <> 0) AND
                (found.name[length(found.name)] in ['G','P','S','I','N','C','L','K','M','V','D','E','R'])) then begin
               inc (c);
               gotoxy (x,y);
               write (found.name);
               f[c].name:=found.name;
               f[c].sys:=found.attr;
               inc (y);
               if (y>14) then begin
                 y:=1;
                 x:=x+16;
               end;
             end;
          3: if ((found.attr AND Directory)<> 0) OR
                (pos('.85P',found.name) <> 0) Then begin
               inc (c);
               gotoxy (x,y);
               write (found.name);
               f[c].name:=found.name;
               f[c].sys:=found.attr;
               inc (y);
               if (y>14) then begin
                 y:=1;
                 x:=x+16;
               end;
             end;
          4: if ((found.attr AND Directory)<> 0) OR
                (pos('.85G',found.name) <> 0) Then begin
               inc (c);
               gotoxy (x,y);
               write (found.name);
               f[c].name:=found.name;
               f[c].sys:=found.attr;
               inc (y);
               if (y>14) then begin
                 y:=1;
                 x:=x+16;
               end;
             end;
        end;
        findnext (found);
      end;

      if (x=1) AND (y=1) then begin
        writeln ('Nothing found.');
        getdrives;
      end;

      puthighlight(1);
      barp:=1;

      if (f[barp].sys AND Directory) <> 0 then
        if f[barp].name='.' then
          deffnbox ('This directory: '+fexpand(f[barp].name))
        else
          deffnbox ('Directory: '+fexpand(f[barp].name))
      else
        deffnbox (getcomment (fexpand(f[barp].name)));

      repeat
        ch:=getkey;
        if (ch=F3) OR (ch=CUp) OR (ch=CDown) OR (ch=CLeft) OR (ch=CRight) then
          zaphighlight (barp);
        case ch of
          F3: Drv:=TRUE;
          CUp: dec (barp);
          CDown: inc (barp);
          CLeft: dec (barp,14);
          CRight: inc (barp,14);
        end;
        if (ch=F3) OR (ch=CUp) OR (ch=CDown) OR (ch=CLeft) OR (ch=CRight) then begin
          if (barp < 1) then barp:=1;
          if (barp > c) then barp:=c;
          puthighlight (barp);

          if (f[barp].sys AND Directory) <> 0 then
            if f[barp].name='.' then
              deffnbox ('This directory: '+fexpand(f[barp].name))
            else
              deffnbox ('Directory: '+fexpand(f[barp].name))
          else
            deffnbox (getcomment (fexpand(f[barp].name)));
        end;

      until (ch=13) OR (ch=27) OR Drv;

      if (ch=13) AND ((f[barp].sys AND Directory)<>0) then begin
        chdir(fexpand (f[barp].name));
        chdrv(fexpand (f[barp].name));
      end;

      if Drv then GetDrives;

    until NOT Drv AND (((ch=13) AND ((f[barp].sys AND Directory)=0)) or (ch=27));

    windmax:=winh;
    windmin:=winl;
    textattr:=txat;
    dis:=scrn;

    if (f[barp].sys AND directory)<>0 then begin
      chdrv(f[barp].name);
      chdir(f[barp].name);
    end;

    s:=fexpand (f[barp].name);
  end;


  procedure Center (lne : byte; txt : string;col : word);
    var lentxt,xpos : byte;
        z : word;
    begin
      z:=textattr;
      textcolor (col);
      lentxt:=length(txt);
      xpos:=40-(lentxt div 2);
      gotoxy (xpos,lne);
      write (txt);
      textcolor (z);
    end;

  function GetString (stx,sty,maxx : integer;shw : string;col1,col2 : word;outc : string):string;
    procedure Beep;
      begin
        sound (300);
        delay (40);
        nosound;
      end;

  label ALoopA,ALoopB;
  var i    : integer;
      j    : integer;
      x    : integer;
      y    : integer;
      tmp  : string;
      sng  : string;
      hsng : string;
      chc  : char;
      show : boolean;

  begin
    gotoxy(stx,sty);
    if shw='N' then show:=FALSE else show:=TRUE;
    sng:='';
    hsng:='';
    x:=wherex;
    y:=wherey;

  ALoopA:
    textcolor(col2);
    gotoxy(x,y);

  ALoopB:
    if keypressed then
      begin
        chc:=readkey;
        if chc=#0 then
          if keypressed then
              chc:=readkey;

        if chc=#13 then
          begin
            gotoxy(x,y);
            write(' ');
            GetString:=sng;
            if show=false then getstring:=hsng;
            exit;
          end;

        if chc=#8 then
          begin
            if x<=stx then
              begin
                beep;
                x:=stx;
                goto ALoopA;
              end;
            gotoxy(x,y);
            write(' ');
            tmp:='';
            i:=length(sng);
            sng[i]:=' ';
            textcolor(col1);
            gotoxy(stx,sty);
            write(sng);
            for j:=1 to (i-1) do
              tmp:=tmp+sng[j];
            sng:=tmp;
            if show=false then
              begin
                tmp:='';
                i:=length(hsng);
                hsng[i]:=' ';
                for j:=1 to (i-1) do
                  tmp:=tmp+hsng[j];
                hsng:=tmp;
              end;
            dec(x);
            if x < stx then
              begin
                beep;
                x:=stx;
              end;
            goto ALoopA;
          end;

        if x>=maxx then
          begin
            beep;
            x:=maxx;
            goto ALoopA;
          end;
        if show=true then sng:=sng+chc else
          begin
            sng:=sng + outc;
            hsng:=hsng + chc;
          end;
        textcolor (col1);
        gotoxy(stx,y);
        write(sng);
        inc(x);
        if x>maxx then
          begin
            beep;
            x:=maxx;
            gotoxy(x,y);
            goto ALoopA;
          end;
        gotoxy(x,y);
      end
    else goto ALoopB;
    goto ALoopA;
  end;


  function EditString (stx,sty,maxx: integer; fore_col,back_col: byte; Edi_Str: string; SKey: word): string;
    procedure Beep;
      begin
        sound (300);
        delay (40);
        nosound;
      end;

  label ALoopA,ALoopB,StartProper;
  var i    : integer;
      j    : integer;
      z    : integer;
      x    : integer;
      y    : integer;
      tmp  : string;
      sng  : string;
      chc  : char;
      c    : word;
      show : boolean;

  begin
    sng:=edi_str;
  StartProper:
    for i:=stx to maxx do begin
      gotoxy (i,sty);
      write (' ');
    end;
    z:=length (edi_str);
    gotoxy(stx,sty);
    x:=stx+z;
    y:=wherey;
    gotoxy (stx,sty);
    write (sng);

  ALoopA:
    textcolor(fore_col);
    textbackground (back_col);
    gotoxy(x,y);

  ALoopB:
    if keypressed then
      begin
        chc:=readkey;
        if chc=#0 then
          if keypressed then
          begin
            c:=ord(readkey);
            if c*256=SKey then begin
              EditStringUserDef (sng);
              edi_str:=sng;
              goto StartProper;
            end;
            beep;
            goto ALoopA;
          end;

        if chc=#13 then
          begin
            gotoxy(x,y);
            write(' ');
            EditString:=sng;
            exit;
          end;

        if chc=#8 then
          begin
            if x<=stx then
              begin
                beep;
                x:=stx;
                goto ALoopA;
              end;
            gotoxy(x,y);
            write(' ');
            tmp:='';
            i:=length(sng);
            sng[i]:=' ';
            textcolor(fore_col);
            textbackground (back_col);
            gotoxy(stx,sty);
            write(sng);
            for j:=1 to (i-1) do
              tmp:=tmp+sng[j];
            sng:=tmp;
            dec(x);
            if x < stx then
              begin
                beep;
                x:=stx;
              end;
            goto ALoopA;
          end;

        if chc=#27 then
        begin
          editstring := '*ESCHIT*';
          exit;
        end;

        if x>=maxx then
          begin
            beep;
            x:=maxx;
            goto ALoopA;
          end;
          sng:=sng+chc;
        textcolor (fore_col);
        textbackground (back_col);
        gotoxy(stx,y);
        write(sng);
        inc(x);
        if x>maxx then
          begin
            beep;
            x:=maxx;
            gotoxy(x,y);
            goto ALoopA;
          end;
        gotoxy(x,y);
      end
    else goto ALoopB;
    goto ALoopA;
  end;


procedure CursorOff;
var regs: registers;
begin;
  regs.ah:=3;
  intr ($10,regs);
  cursz:=regs.cx;
  regs.ch:=$20;
  regs.cl:=0;
  regs.ah:=1;
  intr ($10,regs);
end;

procedure CursorOn;
var regs: registers;
begin
  regs.cx:=cursz;
  regs.ah:=01;
  intr ($10,regs);
end;

procedure ClearKeybBuf;
begin
  if keypressed then repeat readkey until not keypressed;
end;

procedure WaitKey;
var tx: byte;
    winh,winl: word;
begin
  tx:=textattr;
  winl:=windmin;
  winh:=windmax;
  putstatus (' Hit any key...');
  ClearkeybBuf;
  repeat until keypressed;
  ClearkeybBuf;
  windmax:=winh;
  windmin:=winl;
  textattr:=tx;
end;

procedure Note (freq, dur: word);
begin
  sound (freq);
  delay (dur);
  nosound;
end;

procedure ChDrv (s: string);
var regs: registers;
begin
  if (upcase(s[1]) in ['A'..'Z']) AND (s[2]=':') then begin
    s[1]:=upcase(s[1]);
    regs.dl:=ord(s[1])-ord('A');
    regs.ah:=$E;
    intr ($21,regs);
  end;
end;

function UpStr (s: string): string;
var i: byte;
begin
  for i:=1 to length (s) do
    s[i]:=upcase (s[i]);
  UpStr:=s;
end;

function SaveDisplay: word;
var cscr: scrtype absolute $b800:0;
begin
  sscr[dispID]:=cscr;
  savedisplay:=dispID;
  inc (dispID);
  if dispID > 10 then
    dispID:=1;
end;

procedure PutDisplay (savedpage: byte);
var cscr: scrtype absolute $b800:0;
begin
  cscr:=sscr[savedpage];
  window (1,1,80,25);
end;

procedure ErrorMessage (m: msgarry; b: byte);
var mxlen: byte;
    i,j: byte;
    disp: byte;
    xst,yst: word;
    tx: byte;
    winh,winl: word;
begin
  disp:=savedisplay;
  tx:=textattr;
  winh:=windmax;
  winl:=windmin;

  window (1,1,80,25);
  mxlen:=0;
  for i:=1 to b do
    if length(m[i]) > mxlen then
      mxlen:=length(m[i]);

  mxlen:=mxlen+4;
  b:=b+2;
  xst:=40-(mxlen div 2)+1;
  yst:=12-(b div 2)+1;

  textcolor (red);
  textbackground (7);
  gotoxy (xst,yst);

  write ('ฺ');
  for i:=xst+1 to xst+mxlen-2 do
    write ('ฤ');
  write ('ฟ');

  for i:=yst+1 to yst+b-2 do begin
    gotoxy (xst,i);
    write ('ณ');
    for j:=xst+1 to xst+mxlen-2 do
      write (' ');
    write ('ณ');
  end;

  gotoxy (xst,i+1);
  write ('ภ');
  for i:=xst+1 to xst+mxlen-2 do
    write ('ฤ');
  write ('ู');

  for i:=1 to b-2 do begin
    gotoxy (xst+2,yst+i);
    write (m[i]);
  end;

  waitkey;

  textattr:=tx;
  window (lo(winl),hi(winl),lo(winh),hi(winh));
  putdisplay (disp);
end;

procedure PutBorder;
begin
  window (1,6,80,25);
  textbackground (blue);
  textcolor (white);
  clrscr;
  write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
  window (3,7,80,23);
end;

procedure PutDesc (choice: byte);
begin
  window (3,21,79,23);
  textbackground (0);
  textcolor (15);
  clrscr;
  window (3,21,80,24);

  case choice of
    1: writeln ('Receive from the TI-85. No Backups though, sorry :-(');
    2: writeln ('Send data to the TI-85. No Backups though, sorry :-(');
    3: writeln ('Change the comment of a .85? file');
    4: begin
         writeln ('Enter the group file manage. Add, extract, view and delete data from TI-85');
         writeln ('group files (.85G)');
       end;
    5: begin
         writeln ('Editlock programs. This will prevent anyone being able to edit your program.');
         writeln ('Remember to keep an Unlocked copy or *you* won''t be able to edit it either.');
       end;
    6: writeln ('Change the initial setup: Com port, initial path etc...');
    7: writeln ('About the program :-)');
    8: writeln ('Guess.... ;-)');
  end;
  window (1,1,80,25);
end;

procedure PutInfo (ln: byte; s: string);
begin
  window (3,20+ln,79,20+ln);
  textbackground (0);
  textcolor (15);
  clrscr;
  window (3,21,80,24);
  gotoxy (1,ln);
  write (s);
end;


procedure PutStatus (s: string);
var txc: byte;
    winh,winl: word;
    tx,ty: word;
begin
  tx:=wherex; ty:=wherey;
  txc:=textattr;
  winl:=windmin;
  winh:=windmax;
  window (1,25,80,25);
  textcolor (blue);
  textbackground (cyan);
  clrscr;
  gotoxy (1,1);
  write (s);
  window (lo(winl)+1,hi(winl)+1,lo(winh)+1,hi(winh)+1);
  textattr:=txc;
  gotoxy (tx,ty);
end;


(****************************************************************************)
(** Run Routines (called by run) ********************************************)
(****************************************************************************)

procedure RemoveBar (pos: byte);
var x,y: word;
    scr: scrtype absolute $b800:0;
    offs,offsmax: word;
    v,w: byte;
begin
  y:=8+pos;

  offs:=((y-1)*80)+27;
  offs:=offs*2;

  offsmax:=offs+(23*2);

  x:=offs;
  repeat
    v:=scr[x+1];
    w:=v and (black SHL 4);
    v:=w or (v AND 15);
    scr[x+1]:=v;
    inc (x,2);
  until x > offsmax;
end;

procedure ShowBar (pos: byte);
var x,y: word;
    scr: array[0..3999] of byte absolute $b800:0;
    offs,offsmax: word;
    v,w: byte;
begin
  bar:=pos;

  y:=8+pos;

  offs:=((y-1)*80)+27;
  offs:=offs*2;

  offsmax:=offs+(23*2);

  x:=offs;
  repeat
    v:=scr[x+1];
    w:=green SHL 4;
    v:=v or w;
    scr[x+1]:=v;
    inc (x,2);
  until x > offsmax;

  putdesc (pos);
end;

procedure MoveBar (dir: shortint);
begin
  removebar (bar);

  bar:=bar+dir;
  if bar > numitems then
    bar:=1;
  if bar < 1 then
    bar:=numitems;

  showbar (bar);
end;

procedure SaveSetup;
var f: file of cfgtype;
    ch: word;
begin
  window (25,10,54,12);
  textcolor (yellow);
  textbackground (white);
  clrscr;

  window (25,10,54,13);
  write ('ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ');
  write ('ณ                            ณ');
  write ('ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู');

  textcolor (black);
  gotoxy (3,2);
  write ('Setup changed. Save? (Y/n)');

  putinfo (1,'');
  putinfo (2,'Hit Y to save changes, N to discard');
  putinfo (3,'');
  putstatus ('');

  repeat
    ch:=getkey;
  until (ch in [ord('Y'),ord('y'),ord('N'),ord('n')]);

  if ch in [ord('Y'),ord ('y')] then begin
    assign (f,prgpath+'.\85CC.CFG');
    rewrite (f);
    write (f,conf);
    close (f);
  end;

  window (1,1,80,25);
end;


(****************************************************************************)
(** Init Routines (called by init) ******************************************)
(****************************************************************************)

procedure Initwindow;
begin
  cursoroff;
  textbackground (cyan);
  clrscr;
  putstatus (' '+#24+#25+' - Move bar         1->7, highlighted character or '+#17+'ฤู - Select');
end;

procedure InitTitle;
begin
  gotoxy (1,1);
  textcolor (yellow);
  textbackground (black);
  write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
  textcolor (white);
  center (3,'TI-85 Command Center - C.Johnson 1995',white);
end;

procedure InitBase;
begin
  gotoxy (1,20);
  textcolor (yellow);
  textbackground (black);
  write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('บ                                                                              บ');
  write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
end;

procedure InitMenu;
var i,j: byte;
begin
  textcolor (yellow);
  textbackground (black);
  center (7,'ษออออออออออออออออออออออออป',14);
  center (8,'บ                        บ',14);
  center (9,'บ                        บ',14);
  center (10,'บ                        บ',14);
  center (11,'บ                        บ',14);
  center (12,'บ                        บ',14);
  center (13,'บ                        บ',14);
  center (14,'บ                        บ',14);
  center (15,'บ                        บ',14);
  center (16,'บ                        บ',14);
  center (17,'บ                        บ',14);
  center (18,'ศออออออออออออออออออออออออผ',14);

  window (34,9,56,17);
  gotoxy (1,1);
  for i:=1 to numitems do begin
    for j:=1 to length (menuitems[i]) do begin
      if menuitems[i][j]='&' then begin
        textcolor(lightcyan);
        inc (j);
      end else
        textcolor (15);

      write (menuitems[i][j]);
    end;
    writeln;
  end;
  window (1,1,80,25);
end;

procedure InitConfig;
var f: file of cfgtype;
    Dir,Name,Ext: string;
begin
  assign (f,prgpath+'.\85CC.CFG');
  reset (f);

  read (f,conf);
  close (f);

  getdir (0,stpath);
  chdir (conf.initpath);
  chdrv (conf.initpath);
end;

procedure RestoreDrvDir;
begin
  chdir (stpath);
  chdrv (stpath);
end;

end.