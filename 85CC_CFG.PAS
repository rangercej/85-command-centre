uses Dos;

type cfgtype = record
       initpath: pathstr;
       comport:  byte;
     end;

var f: file of cfgtype;
    q: cfgtype;

begin
  assign (f,'85CC.CFG');
  rewrite (f);

  q.initpath:='C:\';
  q.comport:=1;

  write (f,q);
  close (f);
end.
