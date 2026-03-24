*===================================================*
* Full-Scale - Agent Survey (Baseline)
* Currently cleaning the benchtest survey
* Author: Muthia
* Last modified: 17 Agustus 2025
* Last modified by: Muthia
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
gl do            "$path/06 Survey Data/dofiles/04 client_midline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"


* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

******************
** IMPORT DATA **
******************

        import excel "$raw/03 client_midline/raw_client_midline_20032026.xlsx", sheet("Sheet0") firstrow

*******************
** DATA CLEANING **
*******************

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

        ren *, lower
        * Parse the string to a proper datetime, then split date & time
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

        * Convert survey duration to minutes
        destring duration__in_seconds_, replace
        replace duration__in_seconds_ = round(duration__in_seconds_ / 60, .01)
        ren duration__in_seconds_ total_duration
        lab var total_duration "Durations (in minutes)"
        format total_duration %9.2f

** #3. Renaming varibale
gen q_4b_6 =. /// NEED TO DELETE THIS BEFORE RUNNING THE REAL CODE /// kemarin kelupaan digenerate dari qualtricks

        *q_6c_1
        forvalues i = 1/7 {
                rename q_6c_1__`i' q_6c_1_`i'
        }

** #4. Adding label value

        *frequency of doing financial transactions in the past month
        label define q_1a_lbl 1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "Have not done it"
        destring q_1a q_1b_1 q_2a q_2c, replace
        label values q_1a q_1b_1 q_2a q_2c q_1a_lbl

        *amount of fee charged
        label define q_1a_3_lbl 1 "Rp 0 - 500" 2 "Rp 500 - 1,500" 3 "Rp 1,500 - 2,500" 4 "Rp 2,500 - 3,500" 5 "Rp 3,500 - 4,500" 6 "Rp 4,500 - 5,500" 7 "Rp 5,500 - 6,500" 8 "More than Rp 6,500"
        destring q_1a_3 q_2b_2 , replace
        label values q_1a_3 q_2b_2 q_1a_3_lbl

        *confidence
        label define confidence_lbl 1 "a great deal of confidence" 2 "quite a lot of confidence" 3 "not very much confidence" 4 "no confidence at all"
        destring q_3a_1 q_3a_2 q_3a_3 q_3a_4, replace
        label values q_3a_1 q_3a_2 q_3a_3 q_3a_4 confidence_lbl

        *agree disagree
        label define agree_lbl 1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree"
        destring q_4a_1 q_4a_2 q_4a_3 q_4a_4 q_4a_5 q_4a_6 q_4b_1 q_4b_2 q_4b_3 q_4b_4 q_4b_5 q_4b_6, replace
        label values q_4a_1 q_4a_2 q_4a_3 q_4a_4 q_4a_5 q_4a_6 q_4b_1 q_4b_2 q_4b_3 q_4b_4 q_4b_5 q_4b_6 agree_lbl

        *q_5a
        label define q_5a_lbl 1 "None at all" 2 "Sometime" 3 "A lot of time"
        destring q_5a, replace
        label values q_5a q_5a_lbl

        *q_5b
        label define q_5b_lbl 1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree"
        destring q_5b, replace
        label values q_5b q_5b_lbl

        *q_6a_1
        label define q_6a_1_lbl 1 "There is an official price set by the bank and the agent has to stick to that price" ///
                 2 "There is an official price set by the bank, but the agent can charge more or less than this price " ///
                 3 "There is no official price and the agent can decide what price to charge" ///
                 4 "The government or banking regulator sets the prices" ///
                 5 "I don't know"
        destring q_6a_1, replace
        label values q_6a_1 q_6a_1_lbl

        *q_6a_2
        label define q_6a_2_lbl 1 "More" 2 "Less" 3 "it depends ont he client (sometimes more, sometime less)"
        destring q_6a_2, replace
        label values q_6a_2 q_6a_2_lbl

        *q_6c_1
        label define q_6c_1_lbl 1 "Friend and family" 2 "high-value customers" 3 "New customers" 4 "Long-time customers" 5 "Poorer customers" 6 "customers from local area" 7 "Customers who can easily do business with other agents"
        destring q_6c_1_1 q_6c_1_2 q_6c_1_3 q_6c_1_4 q_6c_1_5 q_6c_1_6 q_6c_1_7, replace
        label values q_6c_1_1 q_6c_1_2 q_6c_1_3 q_6c_1_4 q_6c_1_5 q_6c_1_6 q_6c_1_7 q_6c_1_lbl

        *q_7b
        label define q_7b_lbl 1 "Yes, agent was present and helped me" 2 "No, agent was not present and i had to come back"
        destring q_7b, replace
        label values q_7b q_7b_lbl

        *q_7d
        label define q_7d_lbl 1 "There was no wait time, agent helped me right away" 2 "5-10 minutes" 3 "10-15 minutes" 4 "15-30 minutes" 5 "30-45 minutes"
        destring q_7d, replace
        label values q_7d q_7d_lbl

        *q_7e
        label define q_7e_lbl 1 "Transaction was processed on first visit" 2 "2 times" 3 "3 times" 4 "4 times"
        destring q_7e, replace
        label values q_7e q_7e_lbl

        *q_8a 
        label define q_8a_lbl 1 "Prior customer of the agent" 2 "Can clearly answer my questions on the new account opening services" ///
                        3 "Close proximity of my home or workplace" 4 "Sufficient cash balance to perform transactions" ///
                        5 "Transparent and displays a price list" 6 "Available every time I need for transaction" ///
                        7 "Offers the lowest price" 8 "Affiliated with the bank where I want to open an account" ///
                        9 "I trust the agent" 10 "Charges everyone the same prices"
        destring q_8a_1 q_8a_2 q_8a_3 q_8a_4 q_8a_5 q_8a_6 q_8a_7 q_8a_8 q_8a_9 q_8a_10, replace
        label values q_8a_1 q_8a_2 q_8a_3 q_8a_4 q_8a_5 q_8a_6 q_8a_7 q_8a_8 q_8a_9 q_8a_10 q_8a_lbl

        * q_8b
        label define q_8b_lbl 1 "I would prefer to continue doing business with my regular agent, even if other agents in the area offer lower prices/fees" ///
                         2 "I would prefer to do business with the agent that offers the lowest prices/fees and will switch easily if another agent offers better conditions"
        destring q_8b, replace
        label values q_8b q_8b_lbl

        *q_9a_1
        label define q_9a_1_lbl 1 "I would be indifferent" 2 "I would think that is unfair, and start transacting with another agent" ///
                         3 "I would think that is unfair, but would continue making transactions with the same agent" 4 "I would think that is fair"
        destring q_9a_1 q_9a_2, replace
        label values q_9a_1 q_9a_2 q_9a_1_lbl

        *q_9b
        label define q_9b_lbl 1 "Agent A" 2 "Agent B"
        destring q_9b, replace
        label values q_9b q_9b_lbl

        *q_10a
        label define q_10a_lbl 1 "There are many branchless banking agents in my area and I have a lot of options which one I want to use" ///
                                2 "The number of branchless banking agents in my area is limited and I do not have many options which one I want to use"
        destring q_10a, replace
        label values q_10a q_10a_lbl

        *q_11b
        label define q_11b_lbl 1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years"
        destring q_11b, replace
        label values q_11b q_11b_lbl

        *q_11e
        label define q_11e_lbl 1 "They are honest and charge the correct prices" 2 "They are not honest and often overcharge customers"
        destring q_11e, replace
        label values q_11e q_11e_lbl

        *q_11h
        label define q_11h_lbl 1 "New to agent banking, don't know much about products and prices" 2 "Somewhat new, still learning about products and prices" /// 
                                3 "Somewhat experienced, familiar with products and prices" 4 "Very experienced, fully informed about products and prices"
        destring q_11h, replace
        label values q_11h q_11h_lbl
        
        *q_12a
        label define q_12a_lbl 1 "Female" 2 "Male"
        destring q_12a, replace
        label values q_12a q_12a_lbl

        *compensation_option
        rename q_13a compensation_option
        label define compensation_option_lbl 1 "Indomaret" 2 "Alfamart" 3 "Tokopedia"
        destring compensation_option, replace
        label values compensation_option compensation_option_lbl

        rename consent_comp_1 informed_consent
        drop if informed_consent == "0" 
        drop if progress != "100"

save "$dta/03 client_midline/client_midline_`date'.dta", replace