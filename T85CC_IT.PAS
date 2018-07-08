{$A+,B+,E-,F-,G-,I+,N-,O+,V-,X+}

{$IFDEF debug}
{$L+,D+,S+,R+}
{$ELSE}
{$L-,D-,S-,R-}
{$ENDIF}

unit T85CC_IT;

(****************************************************************************
** Start, dispatch and shutdown routines...
****************************************************************************)

interface
  procedure Init;
  procedure Run;
  procedure Done;

implementation
uses dos,crt,overlay,keyb,t85cc_gp,t85cc_rl,t85cc_u,t85cc_lk;

const pw = 'Do you know what happened to Death? He went missing...presumed err...gone :)';


(****************************************************************************)
(** Main Routines ***********************************************************)
(****************************************************************************)

procedure init;
var Name,Ext: string;
    pwd: string[41];
    f: file of cfgtype;
    q: cfgtype;
    err: string[40];
    prgfile: file;
    prgdatetime: longint;
    prgdt: datetime;
begin
  unlock:=FALSE;
  writeln;
  writeln ('85 Command Center - Version ',vnum);
  writeln ('Copyright (c) 1995 C.Johnson');
  writeln;
{$IFDEF debug}
  writeln ('Running in debug mode ...');
  assign (prgfile,paramstr(0));
  reset (prgfile,1);
  getftime (prgfile,prgdatetime);
  close (prgfile);
  unpacktime (prgdatetime,prgdt);
  with prgdt do begin
    writeln ('Compiliation date: ',day,'-',month,'-',year);
    writeln ('Compiliation time: ',hour,':',min,':',sec);
  end;
  write ('Hit any key to continue...');
  waitkey;
{$ENDIF}
  writeln;
  if paramcount > 1 then begin
    writeln ('Error: Synatax: 85CC [RESET]');
    writeln ('   RESET   (Optional) Reset the configuration.');
    halt (3);
  end;

  fsplit(paramstr(0),prgpath,Name,Ext);
  if prgpath='' then
    getdir (0,prgpath);

  if paramcount=1 then
    if upstr(paramstr(1))='RESET' then begin
      write ('Resetting configuration...');
      assign (f,prgpath+'.\85CC.CFG');
      rewrite (f);

      q.initpath:='C:\';
      q.comport:=1;

      write (f,q);
      close (f);
      writeln ('Done.');
    end else
      if upstr(paramstr(1))='CEJ' then begin
        write ('Err...can I have a password please? ');
        pwd:=getstring (wherex,wherey,wherex+40,'N',7,7,'*');
        writeln;
        if pwd=copy (pw,21,13) then begin
          unlock:=TRUE;
          writeln ('WoTcHa :)');
        end else begin
          unlock:=FALSE;
          writeln ('Bummer - wrong :(');
        end;
      end else begin
        writeln ('Error: Synatax: 85CC [RESET]');
        writeln ('   RESET   (Optional) Reset the configuration.');
        halt (3);
      end;

  delay (1000);
  setcomms(1);
  initwindow;
  inittitle;
  initbase;
  initmenu;
  initlink;
  initconfig;

{$IFDEF debug}
  writeln ('  Start path: ',stpath);
  writeln ('Program path: ',prgpath);
  writeln (' Config path: ',conf.initpath);
{$ENDIF}
end;

procedure run;
begin
  showbar (1);

  QUIT:=FALSE;
  SETUP:=FALSE;

  repeat
    case getkey of
      ord('1'),ord('R'),ord('r'): ReceiveData;
      ord('2'),ord('S'),ord('s'): SendData;
      ord('3'),ord('C'),ord('c'): CommentFile;
      ord('4'),ord('G'),ord('g'): GroupManage;
      ord('5'),ord('L'),ord('l'): LockFile;
      ord('6'),ord('E'),ord('e'): SetupCC;
      ord('7'),ord('A'),ord('a'): AboutCC;
      ord('8'),ord('Q'),ord('q'): QUIT:=TRUE;
      13: case bar of
            1: ReceiveData;
            2: SendData;
            3: CommentFile;
            4: GroupManage;
            5: LockFile;
            6: SetupCC;
            7: AboutCC;
            8: Quit:=TRUE;
          end;
      CUp  : movebar (up);
      CDown: movebar (down);
    end;

  until QUIT;

  if setup then
    savesetup;
end;

procedure done;
begin
  cursoron;
  normvideo;
  clrscr;
  writeln ('Thanks for using the 85 Command Center');
  writeln ('Copyright (c) 1995 C.Johnson');
  restoredrvdir;
end;


end.
