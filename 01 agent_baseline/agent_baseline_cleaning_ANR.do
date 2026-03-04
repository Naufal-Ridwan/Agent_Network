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
gl user = c(username)

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
//dis c(username) // activate this code if you need to check your username

* Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

* Set the path
gl do            "$path/06 Survey Data/dofiles/agent_baseline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses/agent_baseline"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day


*******************************************
**--------------IMPORT DATA--------------**
*******************************************
import excel "/Users/athonaufalridwan/Downloads/JPAL/AN/raw/raw_agent_baseline_090125.xlsx", sheet("Sheet0") firstrow
********************************************
**----------------CLEANING----------------**
********************************************

** #1. Rename and revised variable name
ren *, lower
*drop b_1_1


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

/*
* Store the first row values into local macros
ds
local vars `r(varlist)'


quietly {
    local i = 1
    foreach v of local vars {
        local lbl = `"`= `v'[1]'"'
        label variable `v' "`lbl'"
        local ++i
    }
}
*/

* Drop the first row since it's now in labels
drop in 1

ren *, lower
ren informed_consent_1 informed_consent
ren externalreference unique_code

***date time
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

* Revised manually for Section 1
ren (q_1b_1_1_11 q_1b_1_1_do_11) (q_1b_1_1_8 q_1b_1_1_do_8)

* Revised manually for Section 8
ren (q_8a_1_11 q_8a_1_do_11) (q_8a_1_8 q_8a_1_do_8)

* Revised manually for Agents Info
ren q_10b gender
ren (q_10c_1) (birthyear)


** # 2. Drop irrelevant variables 
drop if status == "1"
drop if progress == "0"
drop status recordeddate recipientlastname-recipientemail distributionchannel 


** #2. Rename survey block randomization
* Treatment arms (FL = Field Label aka. Survey Block)
local old_numbers 1305 2283 2328 2373 2418 2463 2508 2553
local new_numbers 1 2 3 4 5 6 7 8
local treatments purecontrol t1 t2 t3 t4

forvalues i = 1/8 {
    // Extract old block number as STRING
    local old : word `i' of `old_numbers'

    // Extract new block number as STRING
    local new : word `i' of `new_numbers'

    foreach t of local treatments {
        capture rename fl_`old'_do_`t' fl_`new'_do_`t'
    }
}


** #3. Convert survey duration to minutes
destring duration__in_seconds_, replace
replace duration__in_seconds_ = round(duration__in_seconds_ / 60, .01)
ren duration__in_seconds_ total_duration
lab var total_duration "Durations (in minutes)"


***** FOR SECTION 1 and 9, WE NEED TO CREATE VARIABLES FOR SELECT UP TO 3 QUESTIONS
local qs q_1b_1_1_1 q_1b_1_1_2 q_1b_1_1_3 q_1b_1_1_4 q_1b_1_1_5 q_1b_1_1_6 q_1b_1_1_7 q_1b_1_1_8 ///
         q_9e_1_1 q_9e_1_2 q_9e_1_3 q_9e_1_4 q_9e_1_5 q_9e_1_6 q_9e_1_7 q_9e_1_8 q_9e_1_9 ///
         q_9e_2_1 q_9e_2_2 q_9e_2_3 q_9e_2_4 q_9e_2_5 q_9e_2_6 q_9e_2_7 q_9e_2_8 q_9e_2_9 ///
         q_9f_1 q_9f_2 q_9f_3 q_9f_4 q_9f_5 q_9f_6 q_9f_7 q_9f_8 q_9f_9

local prefixes
foreach v of local qs {
    local prefix = substr("`v'", 1, length("`v'") - 1)
    local prefixes : list prefixes | prefix
}

* Remove duplicates
local prefixes : list uniq prefixes

foreach p of local prefixes {

    * Identify all variables in this block
    local blockvars
    foreach v of local qs {
        if substr("`v'", 1, length("`p'")) == "`p'" {
            local blockvars `blockvars' `v'
        }
    }

	* Generate output variables as STRING (fix type mismatch)
	gen str10 `p'A1 = ""
	gen str10 `p'A2 = ""
	gen str10 `p'A3 = ""

    * Collapsing logic → collect up to 3 nonmissing answers
    forvalues i = 1/`=_N' {
        local k = 1
        foreach v of local blockvars {
            if !missing(`v'[`i']) {
                replace `p'A`k' = `v'[`i'] in `i'
                local ++k
                if `k' > 3 continue, break
            }
        }
    }
}

* Result: q_9e_1 q_9e_2 q_9e_3 and q_9f_1 q_9f_2 q_9f_3 (numeric).
* If a row had only one or two choices, the remaining cells are missing (.)
drop q_1b_1_1_1 q_1b_1_1_2 q_1b_1_1_3 q_1b_1_1_4 q_1b_1_1_5 q_1b_1_1_6 q_1b_1_1_7 q_1b_1_1_8 ///
         q_9e_1_1 q_9e_1_2 q_9e_1_3 q_9e_1_4 q_9e_1_5 q_9e_1_6 q_9e_1_7 q_9e_1_8 q_9e_1_9 ///
         q_9e_2_1 q_9e_2_2 q_9e_2_3 q_9e_2_4 q_9e_2_5 q_9e_2_6 q_9e_2_7 q_9e_2_8 q_9e_2_9 ///
         q_9f_1 q_9f_2 q_9f_3 q_9f_4 q_9f_5 q_9f_6 q_9f_7 q_9f_8 q_9f_9

		 /*
** #4. Concatenate the randomization order (DO refer to Display Order)
local ords q_1b_1_1_do q_1c_do q_2a_do q_4a_do q_7a_do q_8a_1_do q_9e_1_do q_9f_do
 
foreach v of local ords {
    
    * Split by "|", create numbered suffix variables
    capture noisily split `v', parse(|) gen(`v'_)

    * Clean and convert to numeric
    foreach w of varlist `v'_* {
        replace `w' = strtrim(`w')
        destring `w', replace
    }

    * Place new variables right after the original
    order `v'_*, after(`v')
}
*/


** #5. Combining people randomized to T1 and T3 into a single variable and create treatment status
destring t1* t2 t3* t4 pure_control, force replace
foreach rand in t1 t3 {
    egen `rand'_combined = rowtotal(`rand'_a - `rand'_g)
    order `rand'_combined, after(`rand'_g)
    recode `rand'_combined (0 = .)
}
replace t1_combined = 0 if t1_combined==.
replace t2 = 0 if t2==.
replace t3_combined = 0 if t3_combined==.
replace t4 = 0 if t4==.
replace pure_control = 0 if pure_control==.

* Check if there is double value in all treatment arm from each observation
gen check = pure_control + t1_combined + t2 + t3_combined + t4
tab check
drop if check == . //all safe
drop check

* Treatment status
gen treatment_status = .
order treatment_status, after(t4)

local num = 0
local tstats pure_control t1_combined t2 t3_combined t4
forval a = 1/5 {
    local tstat : word `a' of `tstats'
    replace treatment_status = `num' if `tstat' == 1
    local num = `num' + 1
}

drop t1* t2* t3* t4* pure_control

/*
**#6. Recode missing value for 9e and 9f
foreach mval in q_9e q_9f {
    recode `mval'_1 - `mval'_9 (. = 0) if `mval'_total != .
}
*/


** #7. Convert years
* BM Agent
destring q_10a_1, replace force
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
forval i = 1/12 {
    local year : word `i' of `years'
    replace q_10a_1 = `year' if q_10a_1 == `i'
}

* Year of Birth
destring birthyear, replace force
tab birthyear

destring informed_consent q_1b q_8a q_8c q_9d, replace force 
la def yes_no 1 "Yes" 0 "No" 
la val informed_consent q_1b q_8a q_8c q_9d yes_no

* Section 1 & 8 DO -- Define mapping for all q_1b_1_do_* variables
destring q_1b_1_1_A1 q_1b_1_1_A2 q_1b_1_1_A3, replace force
la def do_1b 1 "Friends" 2 "Family" 3 "High-value customers" 4 "New customers" 5 "Long-time customers" 6 "Poorer customers" 7 "Customers from local area" 8 "Customers who can easily do business with other agents"
la val q_1b_1_1_A1 q_1b_1_1_A2 q_1b_1_1_A3 do_1b

* Section 9 DO -- Define mapping for all do variables
destring q_9e_1_A1 q_9e_1_A2 q_9e_1_A3 q_9f_A1 q_9f_A2 q_9f_A3, replace force
la def do_9 1 "Reduced fees charged per transaction" 2  "Longer business hours" 3  "Offer buy on credit option" 4  "Offer complementary services/products" 5  "Having extra cash in hand" 6  "Cleanliness premises" 7  "Better customer service" 8  "Create more trust among cust" 9 "Proximity to customers"
la val q_9e_1_A1 q_9e_1_A2 q_9e_1_A3 q_9f_A1 q_9f_A2 q_9f_A3 do_9

/* 
la def likert_important 1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important"
la val q_2a_1 - q_2a_10 likert_important
*/

destring q_3a q_3c, replace force
la def fairness_perception 1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair"
la val q_3a q_3c fairness_perception

destring q_9h q_9i q_9j, replace force
la def time_period 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all"
la val q_9h q_9i q_9j time_period

destring q_1a, replace force
la def q_1a 1 "I follow the official list" 0 "I set my own prices"
la val q_1a q_1a

destring q_1c, replace force
la def q_1c 1 "Most clients know the fees well" 0 "Most clients do not know the fees"
la val q_1c q_1c

destring q_4a, replace force
la def q_4a 1 "There are many agents in my area" 2 "There are limited agents in my area"
la val q_4a q_4a

destring q_4b, replace force
la def q_4b 1 "Continue doing business with me, even if other agents offer lower prices" 2 "Change to other agents who offer lower prices"
la val q_4b q_4b

la def treatment_status 0 "Pure Control" 1 "T1" 2 "T2" 3 "T3" 4 "T4"
la val treatment_status treatment_status

destring q_7a, replace force
la def q_7a 1 "Plan A" 0 "Plan B"
la val q_7a q_7a

destring q_9b, replace force 
la def q_9b 1 "High" 2 "Neither high nor low" 3 "Low"
la val q_9b q_9b

destring q_9c, replace force
la def q_9c 1 "Easy" 2 "Neither easy nor difficult" 3 "Difficult"
la val q_9c q_9c

destring q_9g, replace force
la def q_9g 1 "None at all" 2 "Some time" 3 "A lot of time"
la val q_9g q_9g

destring gender, replace force
la def gender 1 "Female" 0 "Male"
la val gender gender


** #11. Change variable labels
la var total_duration "Total survey duration (in minutes)"

la var q_1a                 "How do you set the banking transaction fees?"
la var q_1b                 "Do you charge all clients the same fee?"
la var q_1c                 "How well does your customer understand the official transaction fees from BM?"

la var q_2a_1   "Reg cust characteristics: client is a prior customer"
la var q_2a_2   "Reg cust characteristics: agent can clearly answer question"
la var q_2a_3   "Reg cust characteristics: agent proximity to home or workplace"
la var q_2a_4   "Reg cust characteristics: agent has sufficient cash balance"
la var q_2a_5   "Reg cust characteristics: price transparent and displayed on the store"
la var q_2a_6   "Reg cust characteristics: agent always available every time needed"
la var q_2a_7   "Reg cust characteristics: agent offers the lowest price"
la var q_2a_8   "Reg cust characteristics: agent works w/ the bank whr client wants to open acc"
la var q_2a_9   "Reg cust characteristics: clients trust the agent"
la var q_2a_10  "Reg cust characteristics: agent charges everyone the same prices"

la var q_3a "Client reaction if the agent charges 50% higher than the official fees"
la var q_3b "Estimated agent reduced revenue if agent charges 50% higher than official fees"
la var q_3c "Client reaction if the agent charges 50% higher to another customer"
la var q_3d "Estimated agent reduced revenue if agent charges 50% higher to other customer"
la var q_3e "Estimated agent reduced revenue if withdrawal fees increase from IDR 3K to 4,5K"

la var q_4a    "Which of the following statements do you agree with most?"
la var q_4b    "Which of the following statements do you agree with most?"
la var q_4c    "Estimated agent reduced revenue if new agent charges 50% less"
la var prior    "Prior: Estimated change in the number of agents (in %)"
        
la var treatment_status "Treatment status: =0 pure control, =1 T1, =2 T2, =3 T3, =4 T4"

la var posterior "Posterior: Estimated change in the number of agents (in %)"

la var q_7a       "Choice of marketing plans"

la var q_8a       "Offer additional benefits to your customers"
la var q_8a_1_1   "Additional benefit to Friends"
la var q_8a_1_2   "Additional benefit to Family"
la var q_8a_1_3   "Additional benefit to High-value cust"
la var q_8a_1_4   "Additional benefit to New cust"
la var q_8a_1_5   "Additional benefit to Long-time cust"
la var q_8a_1_6   "Additional benefit to Poorer cust"
la var q_8a_1_7   "Additional benefit to Cust from local"
la var q_8a_1_8   "Additional benefit to Cust who can easily do business"
la var q_8b       "% of revenues from branchless banking business last month"
la var q_8c_1     "% of revenues from BM business last month"

la var q_9a "How many agents are in your area? (BM agents and agents from other banks)"
la var q_9b "Current level of competition with other agents in your area"
la var q_9c "How easy for you to attract new clients?"
la var q_9d "Do you display a price list with BM's official prices in your shop?"

* q_9e (expected new competitor strategies)
la var q_9e_1_A1    "Expected new comp's main strat: Answer 1"
la var q_9e_1_A2    "Expected new comp's main strat: Answer 2"
la var q_9e_1_A3   "Expected new comp's main strat: Answer 3"

la var q_9e_2_A1	"Most effective convincing current cust: Answer 1"
la var q_9e_2_A2	"Most effective convincing current cust: Answer 2"
la var q_9e_2_A3	"Most effective convincing current cust: Answer 3"

* q_9f (agent’s own strategies)
la var q_9f_A1    "Agent's strat used: Answer 1"
la var q_9f_A2    "Agent's strat used: Answer 2"
la var q_9f_A3    "Agent's strat used: Answer 3"

* q_9g – q_9j
la var q_9g "How much time was spent advertising your branchless banking last month?"
la var q_9h "How often do you promote more branchless banking transactions to customers?"
la var q_9i "How often do you encourage your customers to adopt new BM's financial products?"
la var q_9j "How often do you approach your customers to inform official fees from BM?"

la var q_10a_1   "Since when have you been an agent for Bank Mandiri?"
la var gender    "Gender"
la var birthyear "Birthyear"

la var strata        "Respondent's strata"
la var code_province "Respondent's province code"

destring q_3b q_3d q_3e q_4c prior posterior q_8b q_8c_1 q_9a, replace float

replace q_3b = 0 if missing(q_3b)
replace q_3d = 0 if missing(q_3d)
replace q_3e = 0 if missing(q_3e)
replace q_4c = 0 if missing(q_4c)
replace prior = 0 if missing(prior)
replace posterior = 0 if missing(posterior)
replace q_8b = 0 if missing(q_8b)
replace q_8c_1 = 0 if missing(q_8c_1)
replace q_9a = 0 if missing(q_9a)

drop fl* 


keep if progress == "100"
drop if treatment_status ==.
keep if informed_consent == 1

destring progress, force replace

** #12. Save cleaned data
save "$dta/cleaned_baseline_agent_survey_`date'.dta", replace
export delimited using "$dta/cleaned_baseline_agent_survey_`date'.csv", replace

/*
duplicates drop unique_code_agen, force
ren unique_code unique_code_agen 

** get the unresponded unique code 
merge 1:m unique_code_agen using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/07 Stratification/data/clean/data_agen_nasabah_unique_code_stratification"

keep if _m == 2
keep unique_code_agen 


export delimited using "$dta/cleaned_baseline_agent_survey_not_response_`date'.csv", replace
*\
