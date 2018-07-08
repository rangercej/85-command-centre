{$A+,B+,E-,F-,G-,I+,N-,O+,R-,V-,X+}

{$IFDEF debug}
{$L+,D+,S+}
{$ELSE}
{$L-,D-,S-}
{$ENDIF}

unit T85CC_GP;

(***************************************************************************
**  TI-85 Command Center Group manager
**  It's gonna be big, so I've got a seperate unit for it ...
***************************************************************************)

interface
  procedure GroupManage;

implementation
uses crt,dos,keyb,t85cc_rl;

const Head1:string = '**TI85**'+#$1A+#$0C+#0+'Group created by 85CC                     ';
      Head2:string = '**TI85**'+#$1A+#$0C+#0+'Ungrouped by 85CC                         ';
      FSuff:string = 'NCVVLLMMKKERSDDDDIPR RRRRRRR                         ';
      months: array[1..12] of string[3] = ('Jan','Feb','Mar','Apr',
                                           'May','Jun','Jul','Aug',
                                           'Sep','Oct','Nov','Dec');
      extract = 1;
      view = 2;

type varheadtype = record
       headlen: word;
       datalen: word;
       vartype: byte;
       name:    string[8];
     end;
     dbt = array[1..32767] of byte;

var inf,ouf: file;
    err: msgarry;
    files: array[1..100] of pathstr;
    cmd: string[2];
    opt: string[2];
    databuffer: ^dbt;
    result: word;
    tmw: word;
    tmp: byte;
    sum: word;

function GetDataSize (fname: pathstr): word;
var qinf: file;
    qs: word;
    result: word;
begin
  assign (qinf,fname);
  reset (qinf,1);
  seek (qinf,$35);
  blockread (qinf,qs,2,result);

  getdatasize:=qs;
  close (qinf);
end;

function lz(w: word):string;
var s: string;
begin
  str(w:0,s);
  if length(s)=1 then
    s:='0'+ s;
  lz:=s;
end;

procedure GetVarHead (var searchstart: word; var f: file; var head: varheadtype);
var result: word;
begin
  seek(f,searchstart);
  if searchstart=0 then
    searchstart:=$37;

  seek(f,searchstart);
  blockread(f,head,sizeof(head),result);
end;

function ismatch (s1,s2: string):boolean;
var i: byte;
begin
  if (pos ('?',s1) > 0) or (pos ('?',s2) > 0) or
     (pos ('*',s1) > 0) or (pos ('*',s2) > 0) then begin

    if length(s1) > length(s2) then
      for i:=length(s2)+1 to length(s1) do
        s2:=s2+' '
    else
      for i:=length(s1)+1 to length(s2) do
        s1:=s1+' ';

    if pos('*',s1) > 0 then begin
      for i:=pos ('*',s1) to length(s1) do
        s1[i]:='?'
    end;

    if pos('*',s2) > 0 then begin
      for i:=pos ('*',s2) to length(s2) do
        s2[i]:='?'
    end;

    for i:=1 to length(s1) do begin
      if s1[i]='?' then s2[i]:='?';
      if s2[i]='?' then s1[i]:='?';
    end;
  end;

  if s1=s2 then
    ismatch:=TRUE
  else
    ismatch:=FALSE;
end;



procedure UnGroup (ifile,destname: string);
var t: longint;
    td: datetime;
    seekst: word;
    varhead: varheadtype;
    i: word;
    c: char;
    fname: pathstr;
    num: byte;
    linecount: word;
    x,y: word;
begin
  num:=0;
  assign (ouf,ifile);
  reset (ouf,1);
  if ioresult<>0 then begin
    err[1]:='Cannot open file: '+ifile;
    errormessage (err,1);
    dispose (databuffer);
    exit;
  end;

  write ('Processing group: ',ifile,', ');
  writeln (getdatasize(ifile),' bytes');
  writeln ('Comment: ',getcomment(ifile));
  getftime (ouf,t);
  unpacktime (t,td);
  write ('Group date: ');
  with td do begin
    writeln (lz(day),'-',months[month],'-',year);
    writeln ('      time: ',lz(hour),':',lz(min),':',lz(sec));
  end;

  writeln;
  if num=0 then begin
    files[1]:='*';
    num:=1;
  end;

  linecount:=8;

  seekst:=0;
  repeat
    if (linecount > 16) AND (cmd<>'E') then begin
      x:=wherex;
      y:=wherey;
      write ('More...hit any key...');
      waitkey;
      putstatus ('');
      linecount:=1;
      gotoxy (x,y);
      write ('                      ');
      gotoxy (x,y);
    end;

    getvarhead (seekst,ouf,varhead);

    if varhead.vartype in [$13,$15..$1B] then begin
      case varhead.vartype of
        $17: varhead.name:='Func';
        $18: varhead.name:='Pol';
        $19: varhead.name:='Param';
        $1A: varhead.name:='DifEq';
        $1B: varhead.name:='ZRCL';
        else varhead.name:='Unknown';
      end;
    end;

    if num<>0 then begin
      i:=0;
      repeat
        inc(i);
      until (ismatch (varhead.name,files[i])) OR (i > num);
    end;

    if (ismatch (varhead.name,files[i])) OR (num=0) then begin
      write (varhead.name);
      gotoxy (11,wherey);
      case varhead.vartype of
        0: write ('REAL ');
        1: write ('CPLX ');
        2..3: write ('VECTR');
        4..5: write ('LIST ');
        6..7: write ('MATRX');
        8..9: write ('CONST');
        $A: write ('EQU  ');
        $B: write ('RANGE');
        $C: write ('STRNG');
        $D..$10: write ('GDB  ');
        $11: write ('PICT ');
        $12: write ('PRGM ');
        $13: write ('RANGE');
        $15..$1B: write ('RANGE');
      end;
      write ('  ');
      writeln (varhead.datalen+varhead.headlen+4,' bytes');
      linecount:=linecount+1;

      c:='Y';
      if cmd='E' then begin
        fname:=varhead.name+'.85'+fsuff[varhead.vartype+1];
        if fsearch(fname,'.')<>'' then begin
          if opt='P' then begin
            writeln (': ',varhead.name,' already exists. Overwrite? (y/n/a/q)');
            repeat
              c:=upcase(readkey)
            until c in ['Y','N','A','Q'];
            if c='A' then begin
              opt:='O';
              c:='Y';
            end;
            if c='Q' then halt(4);
          end;
        end;

        if (opt[1] in ['O','P']) then begin
          if c='Y' then begin
            assign (inf,destname+fname);
            rewrite (inf,1);
            for i:=1 to length(head2) do
              blockwrite (inf,head2[i],1,result);

            tmw:=varhead.headlen+varhead.datalen+4;

            blockwrite (inf,tmw,2,result);

            with varhead do begin
              blockwrite (inf,headlen,sizeof(headlen),result);
              blockwrite (inf,datalen,sizeof(datalen),result);
              blockwrite (inf,vartype,sizeof(vartype),result);
              tmp:=length(name);
              blockwrite (inf,tmp,1,result);
              for i:=1 to length(name) do
                blockwrite(inf,name[i],1,result);
            end;

            seek (ouf,filepos(ouf)-(8-length(varhead.name)));

            blockread (ouf,databuffer^,varhead.datalen+2,result);
            blockwrite (inf,databuffer^,varhead.datalen+2,result);

            sum:=0;

            seek (inf,$35);
            blockread (inf,tmw,2,result);
            blockread (inf,databuffer^,tmw,result);

            for i:=0 to tmw-1 do
              sum:=(sum+databuffer^[i]) AND $FFFF;

            blockwrite (inf,sum,2,result);
            close (inf);
          end else begin
            writeln (': ',varhead.name,' exists. Skipping');
          end;
        end else begin
          writeln (': ',varhead.name,' exists. Skipping');
        end;
      end
    end;
    seekst:=seekst+varhead.datalen+varhead.headlen+4;
  until seekst >= getdatasize(ifile);
  close (ouf);
  writeln ('Done.');
end;

procedure DeGroupManage (whattodo: byte);
var disp: byte;
    ifile: string;
    ddir: string;
    tmpinfo: searchrec;
begin
  new (databuffer);
  ESUDCtrl:=4;
  disp:=savedisplay;

  PutBorder;
  case whattodo of
    extract:  putstatus (' '+#17+'ฤู - Ungroup         F2 - File list          ESC - Back to menu');
    view:     putstatus (' '+#17+'ฤู - View content    F2 - File list          ESC - Back to menu');
  end;

  window (3,7,79,23);

  ifile:='';
  cursoron;
  case whattodo of
    extract: write ('Ungroup which file? ');
    view:    write ('View contents of which file? ');
  end;
  ifile:=editstring (wherex,wherey,wherex+60,white,blue,ifile,F2);

  if ifile='*ESCHIT*' then begin
    cursoroff;
    putdisplay (disp);
    dispose (databuffer);
    exit;
  end;

  if fsearch (ifile,'.')='' then begin
    err[1]:='Error: File not found: '+ifile;
    ErrorMessage (err,1);

    putdisplay (disp);
    dispose (databuffer);
    exit;
  end;

  writeln;
  if whattodo = extract then begin
    ddir:='';
    ESUDCtrl:=1;
    write ('Destination? ');
    ddir:=editstring (wherex,wherey,wherex+60,white,blue,ddir,F2);
    writeln;

    if ddir='*ESCHIT*' then begin
      cursoroff;
      putdisplay (disp);
      dispose (databuffer);
      exit;
    end;

    if ddir[length(ddir)]='\' then
      delete (ddir,length(ddir),1);
    if ddir<>'' then begin
      findfirst (ddir,Directory,tmpinfo);
      if doserror<>0 then begin
         err[1]:='Error: Destination not found: '+ddir;
         ErrorMessage (err,1);

         putdisplay (disp);
         dispose (databuffer);
         exit;
      end;
    end;

    ddir:=ddir+'\';
  end;
  cursoroff;

  case whattodo of
    extract: writeln ('Ungrouping...');
    view:    writeln ('Examining...');
  end;
  writeln;

  case whattodo of
    extract: cmd:='E';
    view:    cmd:='V';
  end;
  opt:='P';
  ungroup (ifile,ddir);

  waitkey;
  putdisplay (disp);
  ESUDCtrl:=0;
  dispose (databuffer);
end;

procedure GroupManage;

function GPHilite (pos,dir: shortint): shortint;
var scr: array[0..1999] of word absolute $B800:0;
    i: byte;
    scrmem_ofs: word;
begin
  scrmem_ofs:=(80*(9+pos))+19;

  for i:=1 to 39 do
    scr[scrmem_ofs+i]:=scr[scrmem_ofs+i] OR $7000;

  pos:=pos+dir;
  if pos > 4 then pos:=1;
  if pos < 1 then pos:=4;
  scrmem_ofs:=(80*(9+pos))+19;

  for i:=1 to 39 do
    scr[scrmem_ofs+i]:=scr[scrmem_ofs+i] AND $2FFF;

  GPHilite:=pos;
end;

var disp,i,j: byte;
    mentxt: string;
    ch: word;
    barpos: shortint;
    quitGM: boolean;
begin
  ESUDCtrl:=4;
  removebar (bar);
  showbar (4);
  disp:=savedisplay;

  QuitGM:=FALSE;
  repeat
    window (20,10,60,15);
    textbackground (white);
    textcolor (black);
    clrscr;

    window (20,10,60,16);
    write ('ษอออออออออออออออออออออออออออออออออออออออป');
    write ('บ                                       บ');
    write ('บ                                       บ');
    write ('บ                                       บ');
    write ('บ                                       บ');
    write ('ศอออออออออออออออออออออออออออออออออออออออผ');

    window (21,11,60,15);
    for j:=1 to 4 do begin
      case j of
        1: mentxt:=' &1.  &Group files';
        2: mentxt:=' &2.  &Ungroup a group file';
        3: mentxt:=' &3.  &View contents of group file';
        4: mentxt:=' &4.  &Return to main menu';
      end;

      for i:=1 to length(mentxt) do begin
        if mentxt[i]='&' then begin
          textcolor(Red);
          inc (i);
        end else
          textcolor (black);

        write (mentxt[i]);
      end;
      writeln;
    end;

    gphilite(1,0);
    barpos:=1;
    repeat
      ch:=getkey;
      case ch of
        ord ('1'),ord('G'),ord('g'): note(2000,300);
        ord ('2'),ord('U'),ord('u'): DegroupManage (extract);
        ord ('3'),ord('V'),ord('v'): DegroupManage (view);
        ord ('4'),ord('R'),ord('r'): QuitGM:=TRUE;
        CUp: barpos:=gphilite(barpos,-1);
        CDown: barpos:=gphilite(barpos,+1);
        13: case barpos of
              1: note(2000,300);
              2: DeGroupManage (extract);
              3: DeGroupManage (view);
              4: QuitGM:=TRUE;
            end;
      end;
    until QuitGM;
  until QuitGM;

  putdisplay (disp);
end;

end.
