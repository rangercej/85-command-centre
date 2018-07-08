{$A+,B+,E-,F-,G-,I+,N-,O+,V-,X+}

{$IFDEF debug}
{$L+,D+,S+,R+}
{$ELSE}
{$L-,D-,S-,R-}
{$ENDIF}

unit T85CC_U;

interface
uses dos;

  procedure ReceiveData;
  procedure SendData;
  procedure CommentFile;
  procedure LockFile;
  procedure SetupCC;
  procedure AboutCC;

  procedure initwindow;
  procedure inittitle;
  procedure initbase;
  procedure initmenu;


implementation
  uses crt,keyb,t85cc_lk,t85cc_rl;

(****************************************************************************)
(** Support Routines (called by everything else :) **************************)
(****************************************************************************)


procedure ReceiveData;
label label1;
var data: array[0..32767] of byte;
    bt: byte;
    w: word;
    wbk: word;
    i: word;
    sum: word;
    dofs: word;
    di: word;
    f: file of byte;
    s: string;
    cmd: byte;
    vcount: word;
    ext: string;
    x,y: word;
    tmp: word;
    fname: string[8];
    v,err: integer;
    ch: char;
    disp: byte;
    errs: msgarry;

begin
  removebar (bar);
  showbar (1);
  disp:=savedisplay;

  PutBorder;

  setcomms (conf.comport);
  writeln ('Please connect TI-85 and hit ENTER...');
  putstatus (' Hit ENTER');
  repeat until readkey=#13;

  initport;

  putstatus (' Any key cancels receive...');
  window (3,7,79,23);
  textbackground (blue);
  textcolor (white);
  writeln ('Waiting for TI-85 (hit any key to cancel at any time)...');

  bt:=0; i:=0; w:=0; dofs:=0; di:=0; vcount:=0;

  repeat
    stop:=FALSE;
    first:=TRUE;
    repeat
      bt:=receive;
      if stop then begin
        errs[1]:='Transmission stopped.';
        errormessage (errs,1);
        putdisplay (disp);
        exit;
      end;
    until (bt=$85) or (bt=$82);
    first:=FALSE;

    if bt=$82 then begin
      writeln ('Sorry. Only the TI-85 is currently supported :( .');
      initport;
      waitkey;
      putdisplay (disp);
      exit;
    end;

    sum:=0;

    bt:=receive;

    if (bt in [$36,$6D]) then begin
      writeln ('Unexpected command: ',bt);
      str (bt,errs[1]);
      errs[1]:='Unexpected command: '+errs[1];
      errormessage(errs,1);
      initport;
      putdisplay (disp);
      exit;
    end;

    if (bt=$56) then begin
      bt:=receive;
      bt:=receive;
    end;

    if (bt=$6) OR (bt=$15) then
    begin
      if bt=$6 then begin
        writeln;
        write ('Receiving: ');
        inc (vcount);
      end;
      cmd:=bt;
      sum:=0;
      bt:=receive; w:=bt;         data[dofs+di]:=bt; inc(di);
      bt:=receive; w:=w+(bt*256); data[dofs+di]:=bt; inc(di);

      stop:=FALSE;
      repeat
        if stop then begin
          errs[1]:='Transmission stopped.';
          errormessage (errs,1);
          putdisplay (disp);
          exit;
        end;

        tmp:=dofs+di;
        for i:=dofs+di to dofs+di+w-1 do begin
          data[i]:=receive;
          sum:=sum+data[i];

          if cmd=$15 then begin
            gotoxy(x,y);
            write (i-tmp+1);
          end;
        end;

        wbk:=w;

        bt:=receive; w:=bt;
        bt:=receive; w:=w+(bt*256);

        sum:=sum AND $FFFF;

        if w<>sum then begin
          send ($05); send ($5a);
          send ($00); send ($00);
        end;

        if cmd=$6 then begin
          write (data[dofs+2]+(data[dofs+3]*256),' bytes:');
          if data[dofs+4] in [$17,$18,$19,$1A,$1B] then
            case data[dofs+4] of
              $17: write ('Func');
              $18: write ('Pol');
              $19: write ('Param');
              $1A: write ('DifEq');
              $1B: write ('ZRCL');
            end
          else
            for i:=dofs+6 to dofs+6+data[dofs+5]-1 do
              write (chr(data[i]));
          write (':');
          case data[dofs+4] of
            0: write ('REAL');
            1: write ('CPLX');
            2..3: write ('VECTR');
            4..5: write ('LIST');
            6..7: write ('MATRX');
            8..9: write ('CONST');
            $A: write ('EQU');
            $B: write ('RANGE');
            $C: write ('STRNG');
            $D..$10: write ('GDB');
            $11: write ('PICT');
            $12: write ('PRGM');
            $13: write ('RANGE');
            $15..$1B: write ('RANGE');
            else write ('Unknown (',data[dofs+4],')');
          end;
          write (':');
          x:=wherex; y:=wherey;
        end;
      until w=sum;

      dofs:=dofs+di+wbk; di:=0;

      send ($05); send ($56);
      send ($00); send ($00);

      if cmd=$6 then begin
        send ($05); send ($09);
        send ($00); send ($00);
      end;

    end;
  until bt=$92;

  bt:=receive;
  bt:=receive;
  send ($05); send ($56);
  send ($00); send ($00);

  initport;

  writeln;
  writeln ('Finished receive.');
  writeln ('Received ',vcount,' vars.');
  writeln ('----------------------------------------');

Label1:
  cursoron;
  write ('Enter name to write data to (8 chars max): ');
  fname:=getstring (wherex,wherey,wherex+8,'Y',white,blue,'');
  cursoroff;

  if vcount > 1 then begin
    ext:=fname+'.85G';
  end
  else
  begin
    ext:=fname+'.85'+suff[data[4]+1];
  end;

  writeln;
  textcolor (white);
  if fsearch (ext,'.')<>'' then begin
    writeln ('File already exists.');
    writeln ('(O)verwrite, (R)ename, (C)ancel and quit (data will be lost)');
    repeat
      ch:=upcase(readkey);
      putstatus (' O - Overwrite          R - Rename          C - Cancel and return');
    until ch in ['O','R','C'];
    if ch='C' then begin
      writeln ('OKay...quitting. Data lost.');
      initport;
      putdisplay (disp);
      exit;
    end;
    if ch='R' then goto label1;
  end;

  putstatus (' Saving ....');
  writeln ('Saving data to ',ext);

  assign (f,ext);
  rewrite (f);

  s:='**TI85**'+#$1A+#$0C+#0+'Created by 85CC                           ';
  bt:=0; sum:=0;

  for i:=1 to length(s) do begin
    bt:=ord(s[i]);
    write (f,bt);
  end;

  bt:=lo(dofs); write (f,bt);
  bt:=hi(dofs); write (f,bt);

  for i:=0 to dofs-1 do begin
    write (f,data[i]);
    sum:=sum+data[i];
  end;

  sum:=sum AND $FFFF;

  bt:=lo(sum); write (f,bt);
  bt:=hi(sum); write (f,bt);

  close (f);
  writeln ('Done.');

  putdisplay (disp);
end;

procedure SendData;
var data: array[0..32767] of byte;
    datasize: word;
    ifile: pathstr;
    inf: file;
    dofs: word;
    index: word;
    i: word;
    sum: word;
    bt: byte;
    x,y: word;
    result: word;
    disp: byte;
    err: msgarry;

procedure DoReadfile;
var tmpbuf: string;
begin
  assign (inf,ifile);
  reset (inf,1);

  blockread (inf,tmpbuf,8,result);
  if pos('*TI85**',tmpbuf)=0 then begin
    close (inf);
    writeln ('Error: Invalid TI85 file: ',ifile);
    waitkey;
    putdisplay (disp);
    exit;
  end;

  seek (inf,$35);
  blockread (inf,datasize,2,result);
  blockread (inf,data,datasize,result);
  close (inf);

{$IFDEF debug}
  assign (inf,'85CC.DBG');
  rewrite (inf);
  blockwrite (inf,data,datasize,result);
  close (inf);
{$ENDIF}
end;

begin
  ESUDCtrl:=2;
  removebar (bar);
  showbar (2);
  disp:=savedisplay;

  PutBorder;
  putstatus (' '+#17+'ฤู - Send          F2 - File list          ESC - Back to menu');

  textcolor (white);
  textbackground (blue);
  window (3,7,79,23);
  first:=FALSE;
  clrscr;

  ifile:='';
  cursoron;
  write ('File to send: ');
  ifile:=editstring (wherex,wherey,wherex+60,white,blue,ifile,F2);
  cursoroff;

  window (3,7,79,23);
  textbackground (blue);
  textcolor (white);

  if ifile='*ESCHIT*' then begin
    putdisplay (disp);
    exit;
  end;

  if fsearch (ifile,'.')='' then begin
    err[1]:='Error: File not found: "'+ifile+'"';
    errormessage (err,1);
    putdisplay (disp);
    exit;
  end;

  DoReadfile;

  textcolor (15);
  clrscr;
  writeln ('Please connect TI-85 and hit ENTER...');
  putstatus (' Hit ENTER');
  repeat until readkey=#13;

  writeln;
  initport;

  putstatus (' Any key cancels send...');
  textcolor (white);
  textbackground (blue);
  window (3,7,79,23);
  writeln ('Sending data: ',ifile,' - ',datasize,' bytes total...           ');
  dofs:=0;

  stop:=FALSE;
  repeat
    if stop then begin
      err[1]:='Transmission stopped.';
      errormessage (err,1);
      putdisplay (disp);
      exit;
    end;

    index:=0;
    write ('Sending: ');
    write (data[dofs+2]+(data[dofs+3]*256),' bytes:');
    case data[dofs+4] of
       $17: write ('Func');
       $18: write ('Pol');
       $19: write ('Param');
       $1A: write ('DifEq');
       $1B: write ('ZRCL');
       else for i:=dofs+6 to dofs+6+data[dofs+5]-1 do
              write (chr(data[i]));
    end;
    write (':');
    case data[dofs+4] of
      0: write ('REAL');
      1: write ('CPLX');
      2..3: write ('VECTR');
      4..5: write ('LIST');
      6..7: write ('MATRX');
      8..9: write ('CONST');
      $A: write ('EQU');
      $B: write ('RANGE');
      $C: write ('STRNG');
      $D..$10: write ('GDB');
      $11: write ('PICT');
      $12: write ('PRGM');
      $13: write ('RANGE');
      $15..$1B: write ('RANGE');
      else write ('Unknown (',data[dofs+4],')');
    end;
    write (':');

    sum:=0;
    if stop then exit;
    send ($05); if stop then begin     (* Initiate data xfer *)
      err[1]:='Transmission stopped.';
      errormessage (err,1);
      putdisplay(disp);
      exit;
    end;
    send ($06); if stop then exit;
    repeat
      send (data[dofs]); if stop then exit;       (* Packet length *)
      send (data[dofs+1]); if stop then exit;
      for index:=dofs+2 to dofs+1+(data[dofs]+(256*data[dofs+1])) do begin
        send (data[index]); if stop then exit;     (* Data *)
        sum:=sum+data[index];
      end;

      dofs:=index+1;

      sum:=sum AND $FFFF;

      send (lo(sum)); if stop then exit;
      send (hi(sum)); if stop then exit;   (* Send checksum *)

      bt:=receive;
      if bt<>$85 then begin
        writeln ('Unsupported calculator! Only TI-85 sorry :(');
        initport;
        waitkey;
        putdisplay (disp);
        exit;
      end;
      bt:=receive;              (* Get command    *)
      receive; receive;        (* Junk two bytes *)
    until (bt=$56);             (* $56 = Packet Okay *)

    pause:=TRUE;
    bt:=receive;
    if bt<>$85 then begin
      writeln ('Yikes! Major error - out of sync. Stopping.');
      initport;
      waitkey;
      putdisplay (disp);
      exit;
    end;

    bt:=receive;                (* Get command    *)
    receive; receive;          (* Junk two bytes *)

{    if bt=$5A then              (* Checksum error *) }


    pause:=FALSE;
    skip:=FALSE;
    if bt=$36 then begin        (* $36 = Already exists *)
      bt:=receive;

      if bt=$1 then begin
        receive; receive;
        writeln ('Not Accepted. Exiting.');
        initport;
        waitkey;
        putdisplay (disp);
        exit;
      end
      else begin
        receive; receive;
        write ('Skipping...');
        skip:=TRUE;
      end;
    end;

    if skip then begin
      skip:=FALSE;
      send ($05); send ($56); send ($00); send ($00); (* Received okay bit...*)
      skip:=TRUE;
    end else begin
      send ($05); send ($56); send ($00); send ($00); (* Received okay bit...*)
    end;

    x:=wherex;
    y:=wherey;

    sum:=0;

    send ($05);
    send ($15);
    send (data[dofs]);
    send (data[dofs+1]);
    for index:=dofs+2 to dofs+1+(data[dofs]+(256*data[dofs+1])) do begin
      send (data[index]);
      sum:=sum+data[index];
      if (not skip) then begin
        gotoxy (x,y);
        write (index-dofs-1);
      end;
    end;

    send (lo(sum)); send (hi(sum));    (* Send checksum *)

    dofs:=index+1;

    bt:=receive;
    bt:=receive;
    bt:=receive;
    bt:=receive;
    skip:=FALSE;
    writeln;

  until (dofs>=datasize);

  send ($05); send ($92); send ($0); send ($0);  (* That's all 4 now :) *)

  receive; receive; receive; receive;

  writeln;
  writeln ('Done.');

  WaitKey;

  putdisplay (disp);
  ESUDCtrl:=0;
end;

procedure CommentFile;
var disp: byte;
    ifile: string;
    newcmt: string;
    x,y,i: word;
    buf: array[1..$2A] of byte;
    f: file;
    err: msgarry;
begin
  ESUDCtrl:=2;
  removebar (bar);
  showbar (3);
  disp:=savedisplay;

  PutBorder;
  putstatus (' '+#17+'ฤู - Change comment         F2 - File list          ESC - Back to menu');

  textcolor (white);
  textbackground (blue);
  window (3,7,79,23);
  clrscr;

  ifile:='';
  cursoron;
  write ('Comment which file? ');
  ifile:=editstring (wherex,wherey,wherex+60,white,blue,ifile,F2);
  cursoroff;
  writeln;

  if ifile='*ESCHIT*' then begin
    putdisplay (disp);
    exit;
  end;

  if fsearch (ifile,'.')='' then begin
    err[1]:='Error: File not found: "'+ifile+'"';
    errormessage (err,1);
    putdisplay (disp);
    exit;
  end;

  putstatus (' '+#17+'ฤู - Change comment.          ESC - Back to menu');
  textcolor (white);
  textbackground (blue);
  window (3,8,79,23);

  newcmt:=getcomment(ifile);
  writeln ('Current comment is: ',newcmt);
  writeln;
  write ('New comment: [ ');
  x:=wherex; y:=wherey;
  for i:=1 to $2B do write (' ');
  write (']');

  gotoxy (x,y);
  cursoron;
  newcmt:=editstring (wherex,wherey,wherex+$2A,white,blue,newcmt,0);
  cursoroff;

  for i:=1 to $2A do
    buf[i]:=ord(' ');

  for i:=1 to length(newcmt) do
    buf[i]:=ord(newcmt[i]);

  assign (f,ifile);
  reset (f,1);
  seek (f,$B);
  blockwrite(f,buf,$2a,i);
  close (f);

  writeln;
  writeln ('Done.');

  window (3,7,79,23);
  textbackground (blue);
  textcolor (white);

  WaitKey;

  putdisplay (disp);
  ESUDCtrl:=0;
end;


procedure LockFile;
var disp: byte;
    fle: file of byte;
    ifile: pathstr;
    b: byte;
    w: word;
    ch: byte;
    state: byte;
    c: word;
    err: msgarry;

begin
  ESUDCtrl:=3;
  removebar (bar);
  showbar(5);
  disp:=savedisplay;

  PutBorder;
  putstatus (' '+#17+'ฤู - Lock file         F2 - File list          ESC - Back to menu');

  textcolor (white);
  textbackground (blue);
  window (3,7,79,23);
  clrscr;

  ifile:='';
  cursoron;
  write ('Lock which file? ');
  ifile:=editstring (wherex,wherey,wherex+60,white,blue,ifile,F2);
  cursoroff;
  writeln;

  if ifile='*ESCHIT*' then begin
    putdisplay (disp);
    exit;
  end;

  if fsearch (ifile,'.')='' then begin
    err[1]:='Error: File not found: "'+ifile+'"';
    errormessage (err,1);
    putdisplay (disp);
    exit;
  end;

  putstatus (' '+#17+'ฤู - Lock          ESC - Back to menu');
  textcolor (white);
  textbackground (blue);
  window (3,8,79,23);

  assign (fle,ifile);
  reset (fle);
  seek (fle,$3b);
  read (fle,b);
  if b<>$12 then begin
    writeln ('Error: Filetype: Not a program file');
    writeln;
    close (fle);
    putdisplay (disp);
    waitkey;
    exit;
  end;

  writeln;
  read (fle,b);
  seek (fle,filepos(fle)+b+2);
  read (fle,b);
  if b=0 then begin
    err[1]:='Error: Program: Program does not appear to be tokenized';
    err[2]:='   Programs must be ''tokenized'' to lock them. To do this: ';
    err[3]:='      - Send them to the calculator using the link';
    err[4]:='      - Run the program (this will tokenize it)';
    err[5]:='      - Send the program back to the computer';
    err[6]:='      - Rerun 85LOCK on the now-tokenized program';
    err[7]:='';
    err[8]:='   Note that you also need a STOP statement at the end of your';
    err[9]:='   program, and at least 2 blank lines AFTER the stop statement.';
    errormessage (err,9);

    close (fle);
    putdisplay (disp);
    exit;
  end;

  seek (fle,filesize(fle)-3);
  read (fle,b);
  state:=b;
  case b of
    $FF: if unlock then ch:=$6F;
    $6F: ch:=$FF;
    else begin
           err[1]:='Error: Program: Program does not appear to be terminated correctly';
           err[2]:='   Programs to be edit locked should follow these criteria:';
           err[3]:='      - a STOP statement after the last non-blank line';
           err[4]:='      - at least 2 blank lines AFTER the STOP statement';
           err[5]:='      - they should be ''tokenized'' ';
           err[6]:='              - To tokenize, follow these instructions: ';
           err[7]:='              - Send the program to the calculator using the link';
           err[8]:='              - Run the program (this will tokenize it)';
           err[9]:='              - Send the program back to the computer';
           err[10]:='              - Try and relock it !!';
           errormessage (err,10);
           close (fle);
           putdisplay (disp);
           exit;
         end;
  end;

  case b of
    $FF: if unlock then writeln ('Program is LOCKED - unlocking it');
    $6F: writeln ('Program is UNLOCKED - locking it');
  end;

  if (not unlock) AND (b=$FF) then begin
    writeln ('Sorry ... program is already locked. I am unable to unlock programs.');
    writeln;
    Waitkey;
    putdisplay (disp);
    ESUDCtrl:=0;
    exit;
  end;

  writeln;
  writeln ('Warning!');
  writeln ('You have asked to lock this program. Locking it will mean you will be unable');
  writeln ('to edit it. You will also be _unable_ to UNLOCK it - so keep and unlocked');
  writeln ('copy!!');
  writeln;
  writeln ('Hit any key to continue, or ESCAPE to backout...');
  putstatus (' ESC - Back out to menu          Any other key - Lock the program');

  c:=getkey;
  if c=27 then begin
    putdisplay (disp);
    exit;
  end;

  seek (fle,filepos(fle)-1);
  write (fle,ch);

  read (fle,b);
  w:=b;
  read (fle,b);
  w:=w+(b*256);
  case state of
    $FF: if unlock then w:=w-$90;
    $6F: w:=w+$90;
  end;

  seek (fle,filepos(fle)-2);
  b:=lo(w);
  write (fle,b);
  b:=hi(w);
  write (fle,b);

  case state of
    $FF: if unlock then writeln ('Program now UNLOCKED');
    $6F: writeln ('Program now LOCKED');
  end;

  close (fle);
  writeln ('Done.');

  WaitKey;

  putdisplay (disp);
  ESUDCtrl:=0;
end;

procedure SetupCC;
var i: byte;
    field: byte;
    s,s2: string;
    err: integer;
    escape: boolean;
begin
  ESUDCtrl:=1;
  removebar (bar);
  showbar (6);
  setup:=TRUE;

  i:=savedisplay;
  putstatus (' '+#17+'ฤู - Move to next field          ESC - Back to menu');

  window (5,9,76,15);
  textbackground (red);
  textcolor (white);
  clrscr;

  window (5,9,76,16);
  write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write ('บ Setup                                                                บ');
  write ('บ ฤฤฤฤฤ                                                                บ');
  write ('บ Initial path on startup:                                             บ');
  write ('บ       Serial (com) port:                                             บ');
  write ('บ                                                                      บ');
  write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');

  gotoxy (29,4); write (conf.initpath);
  gotoxy (29,5); write (conf.comport);

  field:=1;
  ESCAPE:=false;
  repeat
    case field of
      1: begin
           putstatus (' F2 - Directory list          '+#17+'ฤู - Next          ESC - Back to menu');
           putinfo (1,'Enter initial path on startup. This will be the directory the program will');
           putinfo (2,'log into when the program is first loaded.');
           putinfo (3,'');
           window (5,9,76,16);
           textcolor (yellow);
           textbackground (black);
           inc (field);
           gotoxy (28,4);
           write ('                                           ');
           gotoxy (29,4);
           cursoron;
           s:=editstring(wherex,wherey,wherex+41,yellow,black,conf.initpath,F2);
           cursoroff;
           if s='*ESCHIT*' then begin
             escape:=TRUE;
             dec(field);
           end else
             conf.initpath:=s;
           gotoxy (28,4);
           textcolor (white);
           textbackground (red);
           write ('                                           ');
           gotoxy (29,4);
           write (conf.initpath);
         end;
      2: begin
           putstatus (' '+#17+'ฤู - Next field          ESC - Back to menu');
           putinfo (1,'Enter the serial port that the connect-85 link is connected to. If this is');
           putinfo (2,'wrong, you won''t be able to send or receive!');
           putinfo (3,'');
           window (5,9,76,16);
           textcolor (yellow);
           textbackground (black);
           dec (field);
           repeat
             gotoxy (28,5);
             write ('   ');
             gotoxy (29,5);
             str(conf.comport,s);
             cursoron;
             s2:=editstring(wherex,wherey,wherex+1,yellow,black,s,0);
             cursoroff;
             val (s2,conf.comport,err);
             if err<>0 then
               val (s,conf.comport,err);
           until ((s2[1] in ['1','2','3','4']) OR (s2='*ESCHIT*'));
           if s2='*ESCHIT*' then begin
             escape:=TRUE;
             inc(field);
           end;
           gotoxy (28,5);
           textcolor (white);
           textbackground (red);
           write ('   ');
           gotoxy (29,5);
           write (conf.comport);
         end;
    end;
  until ESCAPE;
  putdisplay (i);
  ESUDCtrl:=0;
end;

procedure AboutCC;
var i: byte;
begin
  removebar (bar);
  showbar (7);

  i:=savedisplay;

  putstatus (' ESC - Return to menu');
  window (1,6,80,24);
  textbackground (red);
  textcolor (white);
  clrscr;

  window (1,6,80,25);
  write ('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write ('บ TI-85 Command Center                                                         บ');
  write ('บ ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ                                                         บ');
  write ('บ This program was programmed by C.Johnson 1995 because of the limits of TI''s  บ');
  write ('บ LINK85X.                                                                     บ');
  write ('บ                                                                              บ');
  write ('บ It should be simple enough to use. The only thing I''d like to point out is   บ');
  write ('บ that this program does NOT as yet support BACKUP (.85B) files.               บ');
  write ('บ                                                                              บ');
  write ('บ Thanks for everyone who has supplied information on low-level aspects of the บ');
  write ('บ calculator.                                                                  บ');
  write ('บ                                                                              บ');
  write ('บ This program has only been tested on the Connect-85 homemade link. Details   บ');
  write ('บ can be obtained from WWW: http://www.algonet.se/~mha/ti.html                 บ');
  write ('บ                                                                              บ');
  write ('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');


  repeat until getkey=27;

  putdisplay (i);
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


end.
