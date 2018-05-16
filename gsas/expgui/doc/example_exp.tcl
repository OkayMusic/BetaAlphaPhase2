# basic definitions
set expgui(gsasdir) /home/gsas
set expgui(gsasexe) /home/gsas/exe
set env(GSASBACKSPACE) 1
set expgui(autoiconify) 0
set expgui(debug) 0
# source files
source ${expgui(gsasdir)}/expgui/readexp.tcl
source ${expgui(gsasdir)}/expgui/gsascmds.tcl
# load exp file
cd /home/toby/test/
expload GARNET.EXP
mapexp
# make changes
expinfo title set "GARNET 300K"
histinfo 1 file set GARNET300.RAW
phaseinfo 1 a set [expr 1.0001 * [phaseinfo 1 a]]
phaseinfo 1 b set [expr 1.0001 * [phaseinfo 1 b]]
phaseinfo 1 c set [expr 1.0001 * [phaseinfo 1 c]]
# save & run 
expwrite GARNET300.EXP
forknewterm POWPREF "$expgui(gsasexe)/powpref GARNET300" 
forknewterm GENLES  "$expgui(gsasexe)/genles  GARNET300"
