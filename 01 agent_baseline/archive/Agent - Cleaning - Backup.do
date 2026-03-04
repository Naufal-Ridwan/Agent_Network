*===================================================*
* Full-Scale - Agent Survey (Baseline)
* Currently cleaning the benchtest survey
* Last modified: 25 Nov 2024
* Stata version: 17
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
gl user = c(username)

*Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

* Riko
if "$user" == "Riko"{
	gl path "C:\Users\Riko\Dropbox\17 Large-Scale RCT"
	local initials "MRP"
	}

* Set the path
	gl do			"$path\dofiles\agent_baseline"
	gl dta			"$path\dtafiles"
	gl log			"$path\logfiles"
	gl output		"$path\output"
	gl raw			"$path\rawresponses\agent_baseline"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*******************************************
**--------------IMPORT DATA--------------**
*******************************************
import delimited "$raw\raw_agent_baseline_291024_1415.csv", clear

********************************************
**----------------CLEANING----------------**
********************************************
**#1. Drop unnecessary obs & variables
drop if status == 1
drop if progress == 0
drop status ipaddress recordeddate recipientlastname-recipientemail locationlatitude-distributionchannel
drop gps*
drop fl* //I don't know what this is, but I think these are unnecessary variables

**# Temporarily deleting observations that previously had problems (T2 can get competition info and pure control, T2, T4 can click next without selecting an option): basically all observation until 24 Oct 2024
drop in 1/16

**#2. Change var name to label name
local varname startdate enddate progress finished responseid externalreference userlanguage durationinseconds informed_consent_1 city stateregion countryname postalcode
local labval  "startdate" "enddate" "progress" "finished" "responseid" "unique_code" "userlanguage" "total_duration" "informed_consent" "city" "state_region" "country_name" "postal_code"
labvars `varname' "`labval'"

foreach var of varlist * {
    local label : variable label `var'
    if ("`label'" != "") {
        local oldnames `oldnames' `var'
        local newnames `newnames' q_`label'
    }
}

rename (`oldnames')(`newnames')

rename ///
(q_startdate q_enddate q_progress q_total_duration q_finished q_responseid q_unique_code q_userlanguage q_informed_consent q_city q_state_region q_country_name q_postal_code) ///
(startdate enddate progress total_duration finished responseid unique_code userlanguage informed_consent city state_region country_name postal_code)

rename ///
(q_T1_a q_T1_b q_T1_c q_T1_d q_T1_e q_T1_f q_T1_g q_T2 q_T3_a q_T3_b q_T3_c q_T3_d q_T3_e q_T3_f q_T3_g q_T4) ///
(t1_a t1_b t1_c t1_d t1_e t1_f t1_g t2 t3_a t3_b t3_c t3_d t3_e t3_f t3_g t4)

ren q_10b gender

rename (q_10c_1 q_10c_2 q_10c_3) (birthdate birthmonth birthyear)

**#3. Convert survey duration to minutes
replace total_duration = round(total_duration / 60, .01)

**#4. Concatenate the randomization order (DO refer to Display Order)
/*foreach list in q_9e q_9f {
	egen `list'_total = rowtotal(`list'_1 - `list'_9)
	order `list'_total, after(`list'_9)
	recode `list'_total (0 = .)
}

local newvars q_1b_1_1_DO q_1c_DO q_2a_DO q_4a_DO q_4b_DO q_9e_DO q_9f_DO
local ords q_1b_1_g q_1c q_2a_10 q_4a q_4b q_9e_total q_9f_total

forval i = 1/7 {
    local newvar : word `i' of `newvars'
    local ord : word `i' of `ords'

    egen `newvar' = concat(`newvar'_*) , punct(|)
    order `newvar', after(`ord')
    replace `newvar' = "" if `ord' == .
    drop `newvar'_*
}

*/
**#5. Combining people randomized to T1 and T3 into a single variable and create treatment status
foreach rand in t1 t3 {
	egen `rand'_combined = rowtotal(`rand'_a - `rand'_g)
	order `rand'_combined, after(`rand'_g)
	recode `rand'_combined (0 = .)
}

* Check if there is double value in all treatment arm from each observation
gen check = pure_control + t1_combined + t2 + t3_combined + t4
tab check
drop if check != . //all safe
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

// gen treatstat = 0 if pure_control == 1
// replace treatstat = 1 if t1_combined == 1
// replace treatstat = 2 if t2 == 1
// replace treatstat = 3 if t3_combined == 1
// replace treatstat = 4 if t4 == 1
//
// gen check = 1 if treatment_status == treatstat
// order treatstat check, after(treatment_status)

drop pure_control - t4

**#6. Recode missing value for 9e and 9f
foreach mval in q_9e q_9f {
	recode `mval'_1 - `mval'_9 (. = 0) if `mval'_total != .
}

**#7. Convert years
* BM Agent
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
forval i = 1/12 {
    local year : word `i' of `years'
    replace q_10a_1 = `year' if q_10a_1 == `i'
}

* Year of Birth
replace birthyear = birthyear + 1899

**#8. Format mobile phone number
foreach a of varlist q_11b q_11b_1_1 {
	tostring `a', format("%14.0f") force replace
	replace `a' = "0" + `a'
	replace `a' = "" if `a' == "0."
}

**#9. Lottery and compensation status for clients
gen lot_comp_status = 1 if lottery_clients == 1
replace lot_comp_status = 2 if compensation_clients == 1
order lot_comp_status, after(compensation_clients)
drop lottery_clients compensation_clients

**#10. Change value labels
la def yes_no 1 "Yes" 0 "No"
la val informed_consent q_1b q_1b_1 q_1b_1_a - q_1b_1_g q_8b q_9d q_9e_1 - q_9e_9 q_9f_1 - q_9f_9 q_11b_1 yes_no

la def likert_important 1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important"
la val q_2a_1 - q_2a_10 likert_important

la def fairness_perception 1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair"
la val q_3a q_3c fairness_perception

la def time_period 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all"
la val q_9h q_9i q_9j time_period

la def q_1a 1 "I follow the official list" 0 "I set my own prices"
la val q_1a q_1a

la def q_1c 1 "Most clients know the fees well" 0 "Most clients do not know the fees"
la val q_1c q_1c

la def q_4a 1 "There are many agents in my area" 2 "There are limited agents in my area"
la val q_4a q_4a

la def q_4b 1 "Continue doing business with me, even if other agents offer lower prices" 2 "Change to other agents who offer lower prices"
la val q_4b q_4b

la def treatment_status 0 "Pure Control" 1 "T1" 2 "T2" 3 "T3" 4 "T4"
la val treatment_status treatment_status

la def q_7a 1 "Plan A" 0 "Plan B"
la val q_7a q_7a

la def q_9b 1 "High" 2 "Neither high nor low" 3 "Low"
la val q_9b q_9b

la def q_9c 1 "Easy" 2 "Neither easy nor difficult" 3 "Difficult"
la val q_9c q_9c

la def q_9g 1 "None at all" 2 "Some time" 3 "A lot of time"
la val q_9g q_9g

la def gender 1 "Female" 0 "Male"
la val gender gender

la def q_11a 1 "Pulsa Telkomsel" 2 "Pulsa 3 (Tri)" 3 "Pulsa XL" 4 "Pulsa Axis" 5 "Pulsa Indosat" 6 "E-Money OVO" 7 "E-Money GoPay" 8 "E-Money LinkAja" 9 "E-Money DANA" 10 "E-Money ShopeePay"
la val q_11a q_11a

la def lot_comp_status 1 "Lottery" 2 "Compensation"
la val lot_comp_status lot_comp_status

**#11. Change variable labels
la var total_duration "Total survey duration (in minutes)"

labvars q_1a q_1b q_1b_1 q_1b_1_a - q_1b_1_1_DO q_1c q_1c_DO ///
"How do you set the banking transaction fees?" ///
"Do you charge all clients the same fee?" ///
"Do you have a specific type of customers that you charge the lowest fees from?" ///
"Friends and family" ///
"High-value customers" ///
"New customers" ///
"Long-time customers" ///
"Poorer customers" ///
"Customers from local area" ///
"Customers who can easily do business with other agents" ///
"q_1b_1_1 display order" ///
"How well does your customer understand the official transaction fees from BM?" ///
"q_1c display order"

labvars q_2a_1 - q_2a_DO ///
"Reg cust characteristics: client is a prior customer" ///
"Reg cust characteristics: agent can clearly answer question" ///
"Reg cust characteristics: agent proximity to home or workplace" ///
"Reg cust characteristics: agent has sufficient cash balance" ///
"Reg cust characteristics: price transparent and displayed on the store" ///
"Reg cust characteristics: agent always available every time needed" ///
"Reg cust characteristics: agent offers the lowest price" ///
"Reg cust characteristics: agent works w/ the bank whr client wants to open acc" ///
"Reg cust characteristics: clients trust the agent" ///
"Reg cust characteristics: agent charges everyone the same prices" ///
"q_2a display order"

labvars q_3a q_3b q_3c q_3d q_3e ///
"Client reaction if the agent charges 50% higher than the official fees" ///
"Estimated agent reduced revenue if agent charges 50% higher than official fees" ///
"Client reaction if the agent charges 50% higher to another customer" ///
"Estimated agent reduced revenue if agent charges 50% higher to other customer" ///
"Estimated agent reduced revenue if withdrawal fees increase from IDR 3K to 4,5K"

labvars q_4a q_4a_DO q_4b q_4b_DO q_4c q_4d ///
"Which of the following statements do you agree with most?" ///
"q_4a display order" ///
"Which of the following statements do you agree with most?" ///
"q_4b display order" ///
"Estimated agent reduced revenue if new agent charges 50% less" ///
"Prior: Estimated change in the number of agents (in %)"

la var treatment_status "Treatment status: =0 pure control, =1 T1, =2 T2, =3 T3, =4 T4"

la var q_6 "Posterior: Estimated change in the number of agents (in %)"

labvars q_7a q_7a_DO_1 q_7a_DO_0 ///
"Choice of marketing plans" ///
"q_7a display order for plan A" ///
"q_7a display order for plan B"

labvars q_8a q_8b q_8b_1 ///
"% of revenues from branchless banking business last month" ///
"Do you also work as an agent for other banks, besides BM?" ///
"% of revenues from BM business last month"

labvars q_9a q_9b q_9c q_9d q_9e_1 - q_9e_9 q_9e_total q_9e_DO q_9f_1 - q_9f_9 q_9f_total q_9f_DO q_9g q_9h q_9i q_9j ///
"How many agents are in your area? (BM agents and agents from other banks)" ///
"Current level of competition with other agents in your area" ///
"How easy for you to attract new clients?" ///
"Do you display a price list with BM's official prices in your shop?" ///
"Expected new comp's main strat: reduced fees charged per transaction" ///
"Expected new comp's main strat: longer business hours" ///
"Expected new comp's main strat: offer buy on credit option" ///
"Expected new comp's main strat: offer complementary services/products" ///
"Expected new comp's main strat: having extra cash in hand" ///
"Expected new comp's main strat: cleanliness premises" ///
"Expected new comp's main strat: better customer service" ///
"Expected new comp's main strat: create more trust among cust" ///
"Expected new comp's main strat: proximity to customers" ///
"q_9e total selected answer(s)" ///
"q_9e display order" ///
"Agent's strat used: reduced fees charged per transaction" ///
"Agent's strat used: longer business hours" ///
"Agent's strat used: offer buy on credit option" ///
"Agent's strat used: offer complementary services/products" ///
"Agent's strat used: having extra cash in hand" ///
"Agent's strat used: cleanliness premises" ///
"Agent's strat used: better customer service" ///
"Agent's strat used: create more trust among cust" ///
"Agent's strat used: proximity to customers" ///
"q_9f total selected answer(s)" ///
"q_9f display order" ///
"How much time was spent advertising your branchless banking last month?" ///
"How often do you promote more branchless banking transactions to customers?" ///
"How often do you encourage your customers to adopt new BM's financial products?" ///
"How often do you approach your customers to inform official fees from BM?"

labvars q_10a_1 gender birthdate birthmonth birthyear ///
"Since when have you been an agent for Bank Mandiri?" ///
"Gender" ///
"Birthdate" ///
"Birthmonth" ///
"Birthyear"

labvars q_11a q_11b q_11b_1 q_11b_1_1 lot_comp_status ///
"Compensation type" ///
"Phone number" ///
"Are you sure your number is correct?" ///
"Revised phone number" ///
"Lottery and compensation status"

labvars strata code_province ///
"Respondent's strata" ///
"Respondent's province code"

**#12. Save cleaned data
save "$dta\cleaned_baseline_agent_survey_`date'.dta", replace
