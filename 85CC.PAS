{$M 65520,32768,655350}
{$A+,B+,E-,F-,G-,I+,N-,V-,X+}

{$IFDEF debug}
{$L+,D+,S+,R+}
{$ELSE}
{$L-,D-,S-,R-}
{$ENDIF}

program P85CC;

(*****************************************************************************
**
** TI-85 Command Center
**
** Copyright (c) 1995 Chris Johnson
**
** Thanks to everyone who has posted the technical info on the '85 somewhere
** on the TI-85 mailing list, or the several FTP sites :)
**
** These include (in no particular order):
**    Dan Eble         <dan.eble@commlink.org>  Edit locking
**    Per Finander     <pkfimdt93@hvdc.hv.se>   TI-85 comms protocol
**    Magnus Hagander  <mha@algonet.se>         FTP site, TI-85 link interface
**    David Brodbeck   <gull@cyberspace.org>    .85? file formats
**
******************************************************************************
**
** Units requiered:
**    CRT      - Screen, keyboard etc... procedures      (Borland)
**    DOS      - File handling, interrupts etc...        (Borland)
**    KEYB     - Keyboard constants & getkey procedure   (Chris J)
**    T85CC_IT - Initialise routines (init,run,done)     (Chris J)
**    T85CC_GP - Group file manager                      (Chris J)
**    T85CC_RL - Run-time library                        (Chris J)
**    T85CC_U  - The main procedures, bar group manager  (Chris J)
**    T85CC_LK - TI-85 Link procedures - get/send etc... (Chris J)
**
*****************************************************************************)


uses t85cc_it;

begin
  init;
  run;
  done;
end.
