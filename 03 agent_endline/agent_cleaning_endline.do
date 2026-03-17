*===================================================*
* Full-Scale - Agent Survey (Endline)
* Author: Naufal Ridwan
* Last modified: 06 March 2026
* Last modified by: Naufal
* Stata version: 16
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
// gl user = c(username)

if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }
 
if "`c(username)'" == "athonaufalridwan" {
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"
}
 
* Set the path
gl do            "$path/06 Survey Data/dofiles/03 agent_endline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses/04 agent_endline"


* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************

import excel "$raw/raw_agent_endline_`date'.xlsx", sheet("Sheet0") firstrow

*****************
* DATA CLEANING *
*****************

** #1. Rename and revised variable name
ren *, lower

        * Drop the first row since it's now in labels
        drop in 1

        * Rename every variable to its label;
        * add "q_" ONLY if the label starts with a number.
        ds
        foreach v of varlist `r(varlist)' {
        local lbl : variable label `v'
        if "`lbl'" == "" continue

        * does the label start with a digit?
        if regexm("`lbl'","^[0-9]") {
        local new = strtoname("q_`lbl'")
        }
        else {
        local new = strtoname("`lbl'")
        }

        * skip if name wouldn't change
        if "`new'" == "`v'" continue

        * avoid collisions
        capture confirm variable `new'
        if _rc==0 {
                di as err "skip: `v' -> `new' (already exists)"
                continue
        }

        rename `v' `new'
        }
** #2. Generating Date and Time Variables

        * Parse the string to a proper datetime, then split date & time
        ren *, lower
        rename startdate startdatetime_str
        rename enddate enddatetime_str

        gen double st_dt = clock(startdatetime_str, "MDY hm")
        replace    st_dt = clock(startdatetime_str, "DMY hm") if missing(st_dt)   // use if data were DMY
        gen double et_dt = clock(enddatetime_str, "MDY hm")
        replace    et_dt = clock(enddatetime_str, "DMY hm") if missing(et_dt)   // use if data were DMY

        * Date only
        gen int startdate = dofc(st_dt)
        format startdate %tdCCYY-NN-DD    // e.g., 2025-08-05
        gen int enddate = dofc(et_dt)
        format enddate %tdCCYY-NN-DD    // e.g., 2025-08-05

        * Time only (milliseconds since midnight; displayed as HH:MM)
        gen double starttime = mod(st_dt, 24*60*60*1000)
        format starttime %tcHH:MM         // e.g., 03:33
        gen double endtime = mod(et_dt, 24*60*60*1000)
        format endtime %tcHH:MM         // e.g., 03:33

        * Optional: clean up
        drop st_dt et_dt startdatetime_str enddatetime_str
        order startdate starttime enddate endtime

        la var startdate "Start Date"
        la var starttime "Start Time"
        la var enddate "End Date"
        la var endtime "End Time"

        

** #3. Generate
*tbc