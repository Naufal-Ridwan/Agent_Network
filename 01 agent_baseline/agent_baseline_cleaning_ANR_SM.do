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

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

* Naufal
//	

if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }
 
if "`c(username)'" == "athonaufalridwan" {
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"
}
 
 

* Set the path
gl do            "$path/06 Survey Data/dofiles/agent_baseline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day


*******************************************
**--------------IMPORT DATA--------------**
*******************************************
// import excel "/Users/athonaufalridwan/Downloads/JPAL/AN/raw/raw_agent_baseline_090125.xlsx", sheet("Sheet0") firstrow

import excel "$raw/02 agent_baseline/raw_agent_baseline_`date'.xlsx", sheet("Sheet0") firstrow

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


* Drop the first row since it's now in labels
drop in 1

ren *, lower
ren informed_consent_1 informed_consent
ren externalreference unique_code_agent

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
//ren (q_1b_1_1_11 q_1b_1_1_do_11) (q_1b_1_1_8 q_1b_1_1_do_8)

* Revised manually for Section 8
//ren (q_8a_1_11 q_8a_1_do_11) (q_8a_1_8 q_8a_1_do_8)

* Revised manually for Agents Info
ren q_10b gender
ren (q_10c_1) (birthyear)


** # 2. Drop irrelevant variables 
/*drop if status == "1"
drop if progress == "0"
drop status recordeddate recipientlastname-recipientemail distributionchannel 
*/
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


** #5_1. Combining people randomized to T1 and T3 into a single variable and create treatment status
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

** #5_1. Combining people randomized to T1 and T3 into a single variable and create treatment status

gen treatment_status_2 = ""

foreach var in fl_1305_do fl_2795_do fl_2809_do fl_2823_do fl_2837_do fl_2851_do fl_2865_do fl_2879_do {
    replace treatment_status_2 = `var' if ///
        missing(treatment_status_2) & !missing(`var')
}


** #7. Convert years
* BM Agent
destring q_10a_1, replace force
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
forval i = 1/13 {
    local year : word `i' of `years'
    replace q_10a_1 = `year' if q_10a_1 == `i'
}

* Year of Birth
destring birthyear, replace force
tab birthyear

destring informed_consent q_1b q_8a q_8c q_9d, replace force 
la def yes_no 1 "Yes" 0 "No" 
la val informed_consent q_1b q_8a q_8c q_9d yes_no


** Split multiple answers
loc vartosplit q_1b_1_1 q_2a q_8a_1 q_9e_1 q_9e_2 q_9f
foreach i of loc vartosplit {
    split `i', parse (,) destring
    drop `i'
}

loc var q_1b_1_11 
foreach i of loc var {
    replace `i' = 8 if `i' == 11
}

/*
CHANGE TO THIS
loc var q_1b_1_11 q_1b_1_12 q_1b_1_13 q_1b_1_14 q_1b_1_15 q_1b_1_16 q_1b_1_17 q_1b_1_18  q_8a_11 q_8a_12 q_8a_13 q_8a_14 q_8a_15 q_8a_16 q_8a_17 q_8a_18
foreach i of loc var {
    replace `i' = 8 if `i' == 11
}
*/


la def la_client_cat 1 "Friends" 2 "Family" 3 "High-value" 4 "New" 5 "Long-term" 6 "Lower-income" 7 "Local" 8 "Can switch agents"
la val q_1b_1_11 la_client_cat
/*
CHANGE TO THIS
la def la_client_cat 1 "Friends" 2 "Family" 3 "High-value" 4 "New" 5 "Long-term" 6 "Lower-income" 7 "Local" 8 "Can switch agents"
la val q_1b_1_11 q_1b_1_12 q_1b_1_13 q_1b_1_14 q_1b_1_15 q_1b_1_16 q_1b_1_17 q_1b_1_18  q_8a_11 q_8a_12 q_8a_13 q_8a_14 q_8a_15 q_8a_16 q_8a_17 q_8a_18 la_client_cat
*/

la def la_agent_characters 1 "Prior customer" 2 "Answers clearly" 3 "Close proximity" 4 "Sufficient cash" 5 "Price transparency" 6 "Always available" 7 "Lowest price" 8 "Bank-affiliated" 9 "Trusted agent" 10 "Same price for all"
la val q_2a1 q_2a2 q_2a3 la_agent_characters

la def la_agent_improve 1 "Lower fees" 2 "Longer hours" 3 "Offers credit" 4 "Extra services" 5 "More cash" 6 "Clean premises" 7 "Better service" 8 "Builds trust" 9 "Closer to customers"
la val q_9e_11 q_9e_12 q_9e_13 q_9e_21 q_9e_22 q_9e_23 q_9f1 q_9f2 q_9f3 la_agent_improve

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
la def q_4a 1 "Many agents in my area" 2 "Limited agents in my area"
la val q_4a q_4a

destring q_4b, replace force
la def q_4b 1 "Continue doing business with me despite lower prices elsewhere" 2 "Switch to cheaper agents"
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

destring code_province, replace force
la def la_code_province 1 "Aceh" 2 "Bali" 3 "Banten" 4 "Bengkulu" 5 "DI Yogyakarta" 6 "DKI Jakarta" 7 "Gorontalo" 8 "Jambi" 9 "Jawa Barat" 10 "Jawa Tengah" 11 "Jawa Timur" 12 "Kalimantan Barat" 13 "Kalimantan Selatan" 14 "Kalimantan Tengah" 15 "Kalimantan Timur" 16 "Kalimantan Utara" 17 "Kepulauan Bangka Belitung" 18 "Kepulauan Riau" 19 "Lampung" 20 "Maluku" 21 "Maluku Utara" 22 "Nusa Tenggara Barat" 23 "Nusa Tenggara Timur" 24 "Papua" 25 "Papua Barat" 26 "Riau" 27 "Sulawesi Barat" 28 "Sulawesi Selatan" 29 "Sulawesi Tengah" 30 "Sulawesi Tenggara" 31 "Sulawesi Utara" 32 "Sumatera Barat" 33 "Sumatera Selatan" 34 "Sumatera Utara"
la val code_province la_code_province

** #11. Change variable labels
la var total_duration "Total survey duration (minutes)"

la var q_1a "How do you set transaction fees?"
la var q_1b "Do you charge all clients the same fee?"
la var q_1c "Client understanding of BM official fees"

la var q_1b_1_11 "Lowest-fee customers: choice 1"
/*
CHANGE TO THIS
la var q_1b_1_12 "Lowest-fee customers: choice 2"
la var q_1b_1_13 "Lowest-fee customers: choice 3"
la var q_1b_1_14 "Lowest-fee customers: choice 4"
la var q_1b_1_15 "Lowest-fee customers: choice 5"
la var q_1b_1_16 "Lowest-fee customers: choice 6"
la var q_1b_1_17 "Lowest-fee customers: choice 7"
la var q_1b_1_18 "Lowest-fee customers: choice 8"
*/

la var q_2a1 "Most important agent characteristic: 1st choice"
la var q_2a2 "Most important agent characteristic: 2nd choice"
la var q_2a3 "Most important agent characteristic: 3rd choice"

la var q_3a "Client reaction if fees are 50% above official"
la var q_3b "Estimated revenue loss if fees are 50% above official"
la var q_3c "Client reaction if another client is charged 50% more"
la var q_3d "Estimated revenue loss from charging another client 50% more"
la var q_3e "Estimated revenue loss if withdrawal fee rises from IDR 3k to 4.5k"

la var q_4a "Preferred statement on pricing competition"
la var q_4b "Preferred statement on customer switching"
la var q_4c "Estimated revenue loss if a new agent charges 50% less"
la var prior "Prior belief: Change in number of agents (%)"

la var treatment_status "Treatment status (0=Control, 1=T1, 2=T2, 3=T3, 4=T4)"

la var posterior "Posterior belief: Change in number of agents (%)"

la var q_7a "Chosen marketing plan"
la var q_7a_do "Chosen marketing plan (display order)"

la var q_8a "Offer additional customer benefits"
la var q_8a_2 "Number of customers offered additional benefits"
destring q_8a_2, replace

la var q_8a_11 "Customers receiving additional benefits: choice 1"
/*
CHANGE TO THIS
la var q_8a_12 "Customers receiving additional benefits: choice 2"
la var q_8a_13 "Customers receiving additional benefits: choice 3"
la var q_8a_14 "Customers receiving additional benefits: choice 4"
la var q_8a_15 "Customers receiving additional benefits: choice 5"
la var q_8a_16 "Customers receiving additional benefits: choice 6"
la var q_8a_17 "Customers receiving additional benefits: choice 7"
la var q_8a_18 "Customers receiving additional benefits: choice 8"
*/

la var q_8c_1 "% revenue from BM transactions (last month)"

la var q_9a "Number of agents in the area"
la var q_9b "Level of competition with nearby agents"
la var q_9c "Ease of attracting new clients"
la var q_9d "Displays BM official price list"

* q_9e (expected competitor strategies)
la var q_9e_11 "Expected competitor strategy: Option 1"
la var q_9e_12 "Expected competitor strategy: Option 2"
la var q_9e_13 "Expected competitor strategy: Option 3"

la var q_9e_21 "Most effective retention strategy: Option 1"
la var q_9e_22 "Most effective retention strategy: Option 2"
la var q_9e_23 "Most effective retention strategy: Option 3"

* q_9f (agent strategies)
la var q_9f1 "Agent strategy used: Option 1"
la var q_9f2 "Agent strategy used: Option 2"
la var q_9f3 "Agent strategy used: Option 3"

* q_9g – q_9j
la var q_9g "Time spent on promotion last month"
la var q_9h "Frequency of promoting transactions"
la var q_9i "Frequency of promoting new BM products"
la var q_9j "Frequency of informing official BM fees"

la var q_10a_1 "Year became a Bank Mandiri agent"
la var gender "Gender"
la var birthyear "Year of birth"

la var strata "Sampling strata"
la var code_province "Province code"

destring q_3b q_3d q_3e q_4c prior posterior q_8b q_8c_1 q_9a, replace float


drop fl* ci
drop q_1b_1_1_do q_1c_do q_2a_do q_4a_do q_4b_do q_8a_1_do q_9e_1_do q_9e_2_do q_9f_do


keep if progress == "100"
drop if treatment_status ==.
keep if informed_consent == 1

destring progress, force replace

/*
gen signal = .

replace signal = 51 if code_province == 1
replace signal = 49 if code_province == 2
replace signal = 49 if code_province == 3
replace signal = 49 if code_province == 4
replace signal = 49 if code_province == 5
replace signal = 45 if code_province == 6
replace signal = 48 if code_province == 7
replace signal = 48 if code_province == 8
replace signal = 49 if code_province == 9
replace signal = 49 if code_province == 10
replace signal = 48 if code_province == 11
replace signal = 46 if code_province == 12
replace signal = 48 if code_province == 13
replace signal = 46 if code_province == 14
replace signal = 46 if code_province == 15
replace signal = 43 if code_province == 16
replace signal = 49 if code_province == 17
replace signal = 46 if code_province == 18
replace signal = 49 if code_province == 19
replace signal = 46 if code_province == 20
replace signal = 46 if code_province == 21
replace signal = 48 if code_province == 22
replace signal = 47 if code_province == 23
replace signal = 44 if code_province == 24
replace signal = 44 if code_province == 25
replace signal = 48 if code_province == 26
replace signal = 48 if code_province == 27
replace signal = 48 if code_province == 28
replace signal = 47 if code_province == 29
replace signal = 48 if code_province == 30
replace signal = 46 if code_province == 31
replace signal = 48 if code_province == 32
replace signal = 47 if code_province == 33
replace signal = 48 if code_province == 34

gen posterior_prior  = posterior - prior
gen signal_prior     = signal - prior

gen posterior_per_prior = posterior / prior 
gen signal_per_prior    = signal / prior  

gen log_posterior_per_prior = ln(posterior_per_prior)
gen log_signal_per_prior    = ln(signal_per_prior)
*/

destring strata, force replace


append using "$dta/02 agent_baseline/cleaned_baseline_agent_survey_09032026.dta"



** #12. Save cleaned data
save "$dta/02 agent_baseline/cleaned_baseline_agent_survey_`date'.dta", replace
//export delimited using "$dta/cleaned_baseline_agent_survey_`date'.csv", replace

