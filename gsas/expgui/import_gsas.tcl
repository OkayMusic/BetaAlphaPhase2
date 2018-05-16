# $Id: import_gsas.tcl 1251 2014-03-10 22:17:29Z toby $

#-------------------------------------------------
# define info used in addcmds.tcl
if {[file exists [file join $expgui(scriptdir) dumpexp.tcl]]} {
    set description "GSAS .EXP file"
    set extensions {.EXP .O??}
    set procname ReadGSASEXPCoordinates
}
#-------------------------------------------------

proc ReadGSASEXPCoordinates {filename} {
    global wishshell expgui
    set result {}
    catch {
	set result [exec $wishshell \
		[file join $expgui(scriptdir) dumpexp.tcl] $filename]
    }
    return $result
}
