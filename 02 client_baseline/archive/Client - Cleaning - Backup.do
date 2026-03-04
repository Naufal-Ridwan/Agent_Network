*===================================================*
* Full-Scale - Client Survey (Baseline)
* Currently cleaning the benchtest survey
* Last modified: 5 Nov 2024
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
	loc initials "MRP"
	}

* Set the path
	gl do			"$path\dofiles\client_baseline"
	gl dta			"$path\dtafiles"
	gl log			"$path\logfiles"
	gl output		"$path\output"
	gl raw			"$path\rawresponses\client_baseline"

***IMPORTANT***

* Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*******************************************
**--------------IMPORT DATA--------------**
*******************************************
import delimited "$raw\raw_client_baseline_04112024_1345", clear

********************************************
**----------------CLEANING----------------**
********************************************
**#1. Drop unnecessary obs & variables
drop if status == 1
drop if progress == 0
drop status ipaddress recordeddate recipientlastname-recipientemail locationlatitude-distributionchannel q_language

**#2. Change var name to label name
loc varname startdate enddate progress durationinseconds finished responseid externalreference userlanguage
loc labval  "startdate" "enddate" "progress" "total_duration" "finished" "responseid" "unique_code" "userlanguage"
labvars `varname' "`labval'"

foreach var of varlist * {
    loc label : variable label `var'
    if ("`label'" != "") {
        local oldnames `oldnames' `var'
        local newnames `newnames' q_`label'
    }
}

rename (`oldnames')(`newnames')

rename ///
(q_startdate q_enddate q_progress q_total_duration q_finished q_responseid q_unique_code q_userlanguage) ///
(startdate enddate progress total_duration finished responseid unique_code userlanguage)

ren q_12j gender

rename (q_12k_1 q_12k_2 q_12k_3) (birthdate birthmonth birthyear)

rename (consent_comp_1 consent_lottery_1) (consent_compensation consent_lottery)

order consent_lottery, after(consent_compensation)

**#3. Convert survey duration to minutes
replace total_duration = round(total_duration / 60, .01)

**#4. Concatenate the randomization order (DO refer to Display Order)
loc newvars q_3a_DO q_3a_1_DO q_3c_1_1_DO q_5a_DO q_5b_DO q_7_DO q_8_DO q_9_DO q_11a_DO q_12e_DO
loc ords q_3a q_3a_1 q_3c_1_1_g q_5a_10 q_5b q_7d q_8f q_9e q_11a q_12e

forval i = 1/10 {
    local newvar : word `i' of `newvars'
    local ord : word `i' of `ords'

    egen `newvar' = concat(`newvar'_*) , punct(|)
    order `newvar', after(`ord')
    replace `newvar' = "" if `ord' == .
    drop `newvar'_*
}

**#5. Convert input number (amount of transaction) from string to int
local inpt q_1a_1 q_1b_1 q_2a_1 q_2b_1
destring `inpt', replace ignore("." "-")

**#6. Recode "I do not know" value to missing for the slider answer
recode q_1a_2 q_2a_2 (99 = .)

**#7. Convert years
* BM Agent
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
forval i = 1/12 {
    local year : word `i' of `years'
    replace q_12a_1 = `year' if q_12a_1 == `i'
}

* Year of Birth
replace birthyear = birthyear + 1899

**#8. Format mobile phone number
foreach a of varlist q_13b q_13c_2 q_14a {
	tostring `a', format("%14.0f") force replace
	replace `a' = "0" + `a'
	replace `a' = "" if `a' == "0."
}

**#9. Lottery and compensation status
recode compensation_status (0 = 2)

**#10. Change value labels
la def yes_no 1 "Yes" 0 "No"
la val consent_compensation consent_lottery q_3b-q_3c_1_1_g q_10e q_12h q_12i q_13c_1 yes_no

la def last_time 1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "I have not done this transaction before"
la val q_1a q_1b q_2a q_2b last_time

la def fee_approx 1 "Rp 0 – 500" 2 "Rp 500 – 1.500" 3 "Rp 1.500 – 2.500" 4 "Rp 2.500 – 3.500" 5 "Rp 3.500 – 4.500" 6 "Rp 4.500 – 5.500" 7 "Rp 5.500 – 6.500" 8 "More than Rp. 6.500"
la val q_1a_3 q_2a_3 fee_approx

la def likert_important 1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important"
la val q_5a_1 - q_5a_10 likert_important

la def fairness_perception 1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair"
la val q_6a q_6b fairness_perception

la def likert_agree 1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree"
la val q_8a - q_8f q_9a - q_9e likert_agree

la def likert_approach 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all"
la val q_10c q_10d likert_approach

la def likert_confidence 1 "A great deal of confidence" 2 "Quite a lot of confidence" 3 "Not very much confidence" 4 "No confidence at all"
la val q_7a-q_7d likert_confidence

la def q_3a 1 "There's an official price and the agent has to stick with it" 2 "There's an official price, but agent can charge more/less" 3 "No official price and agent can decide the price" 4 "The government sets the prices" 5 "I do not know"
la val q_3a q_3a

la def q_3a_1 1 "More" 2 "Less" 3 "Depends on the client (sometimes more/less)"
la val q_3a_1 q_3a_1

la def q_5b 1 "Continue doing business w/ regular agent, even if others offer lower prices" 2 "Change to other agents who offer lower prices"
la val q_5b q_5b

la def q_6c 1 "Agent A" 2 "Agent B" 3 "I would be indifferent"
la val q_6c q_6c

la def q_10a 1 "None at all" 2 "Some time" 3 "A lot of time"
la val q_10a q_10a

la def q_10b 1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree"
la val q_10b q_10b

la def q_11a 1 "There are many agents in my area" 2 "There are limited agents in my area"
la val q_11a q_11a

la def q_12b 1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years"
la val q_12b q_12b

la def q_12c 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Every 3 months" 7 "Every 6 months" 8 "Once a year"
la val q_12c q_12c

la def q_12e 0 "They are honest and charge the correct prices" 1 "They are not honest and often overcharge customers"
la val q_12e q_12e

la def q_12g 1 "New & don't know much about products and prices" 2 "Somewhat new, and still learning about products and prices" 3 "Somewhat experienced, and familiar with products and prices" 4 "Very experienced, and fully informed about products and prices"
la val q_12g q_12g

la def gender 1 "Female" 0 "Male"
la val gender gender

la def q_13a 1 "Pulsa Telkomsel" 2 "Pulsa 3 (Tri)" 3 "Pulsa XL" 4 "Pulsa Axis" 5 "Pulsa Indosat" 6 "E-Money OVO" 7 "E-Money GoPay" 8 "E-Money LinkAja" 9 "E-Money DANA" 10 "E-Money ShopeePay"
la val q_13a q_13a

la def compensation_status 1 "Compensation" 2 "Lottery"
la val compensation_status compensation_status

**#11. Change variable labels
labvars consent_compensation consent_lottery ///
"Consent Form: Compensation" ///
"Consent Form: Lottery"

labvars q_1a q_1a_1 q_1a_2 q_1a_3 q_1a_4 q_1b q_1b_1 q_1b_2  ///
"When was the last time you did a cash deposit with BM Agent?" ///
"In your last transaction with BM Agent, how much did you deposit?" ///
"Last transaction fee charged by BM Agent for a cash deposit" ///
"Approximate transaction fee charged by BM Agent for last cash deposit" ///
"Last 3 months, how many deposits have you made with BM Agent?" ///
"When was the last time you did a cash deposit with a non-BM Agent?" ///
"In your last transaction with a non-BM Agent, how much did you deposit?" ///
"Last 3 months, how many deposits have you made with a non-BM Agent?"

labvars q_2a q_2a_1 q_2a_2 q_2a_3 q_2a_4 q_2b q_2b_1 q_2b_2 ///
"When was the last time you did a cash withdrawal with BM Agent?" ///
"In your last transaction with BM Agent, how much did you withdraw?" ///
"Last transaction fee charged by BM Agent for a cash withdrawal" ///
"Approximate transaction fee charged by BM Agent for last cash withdrawal" ///
"Last 3 months, how many withdrawals have you made with BM Agent?" ///
"When was the last time you did a cash withdrawal with a non-BM Agent?" ///
"In your last transaction with a non-BM Agent, how much did you withdraw?" ///
"Last 3 months, how many withdrawals have you made with a non-BM Agent?"

labvars q_3a q_3a_DO q_3a_1 q_3a_1_DO q_3b q_3c q_3c_1 q_3c_1_1_a - q_3c_1_1_DO ///
"How do you think banking agents set a fee for each transaction?" ///
"q_3a display order" ///
"Does the agent typically charge more or less than official price?" ///
"q_3a_1 display order" ///
"Does your BM Agent display the official price at his/her shop?" ///
"Does your BM Agent set the same price for everyone?" ///
"Is there a specific type of cust that your BM Agent charges less?" ///
"Who pays less: friends and family" ///
"Who pays less: high-value cust" ///
"Who pays less: new cust" ///
"Who pays less: long-time cust" ///
"Who pays less: poorer cust" ///
"Who pays less: cust from local area" ///
"Who pays less: cust who can easily do business w/ other agents" ///
"q_3c_1_1 display order"

la var q_4 "How satisfied were you with your BM Agent service (last transaction)?"

labvars q_5a_1 - q_5a_DO q_5b q_5b_DO ///
"Important characteristics: I've been a prior customer" ///
"Important characteristics: agent can clearly answer question" ///
"Important characteristics: agent proximity to home or workplace" ///
"Important characteristics: agent has sufficient cash balance" ///
"Important characteristics: price transparent and displayed on the store" ///
"Important characteristics: agent always available every time needed" ///
"Important characteristics: agent offers the lowest price" ///
"Important characteristics: agent works w/ the bank whr I want to open acc" ///
"Important characteristics: I trust the agent" ///
"Important characteristics: agent charges everyone the same prices" ///
"q_5a display order" ///
"Which of the following statements do you agree with most?" ///
"q_5b display order"

labvars q_6a q_6b q_6c ///
"My reaction if my BM Agent charged other cust a lower fee than me" ///
"My reaction if my BM Agent charged me 50% higher than other cust" ///
"Preference to do a regular transaction when there are only two agents"

labvars q_7a q_7b q_7c q_7d q_7_DO ///
"Views on BM Agent & BM: confidence in banks" ///
"Views on BM Agent & BM: confidence in BM" ///
"Views on BM Agent & BM: confidence in BM agent" ///
"Views on BM Agent & BM: confidence that BM Agent will give the best price" ///
"q_7 display order"

labvars q_8a q_8b q_8c q_8d q_8e q_8f q_8_DO ///
"Agree/no: my BM Agent is honest and trustworthy" ///
"Agree/no: my BM Agent puts cust well-being above profits" ///
"Agree/no: my BM Agent treats all cust equally well" ////
"Agree/no: my BM Agent is transparent about pricing" ///
"Agree/no: my BM Agent does his/her job well" ///
"Agree/no: my BM Agent offers reliable service" ///
"q_8 display order"

labvars q_9a q_9b q_9c q_9d q_9e q_9_DO ///
"Agree/no: BM is honest and trustworthy" ///
"Agree/no: BM puts cust well-being above profits" ///
"Agree/no: BM treats all cust equally well" ///
"Agree/no: BM is transparent about pricing" ///
"Agree/no: BM offers reliable service" ///
"q_9 display order"

labvars q_10a q_10b q_10c q_10d q_10e ///
"How much time did your BM Agent spend advertising his services last month?" ///
"Agree/no: BM Agent did all to convince people to adopt BM Agent products last mo" ///
"Has your BM Agent approached you to do more agent transactions last month?" ///
"Has your BM Agent approached you to adopt new BM financial products last month?" ///
"Has your BM Agent approached you w/ new info abt BM transaction fees last month?"

labvars q_11a q_11a_DO q_11b ///
"Which of the following statements do you agree with most?" ///
"q_11a display order" ///
"How many branchless banking agents are in your area?"

labvars q_12a_1 q_12b q_12c q_12d q_12e q_12e_DO q_12f q_12g q_12h q_12i ///
"Since when have you been doing transactions with your BM Agent?" ///
"For how long have you known your BM Agent?" ///
"How often do you talk with your BM Agent?" ///
"What % of your overall agent transactions do you do with your BM Agent?" ///
"Which of the following best describes ur opinion abt banking agents in general?" ///
"q_12e display order" ///
"Imagine a ladder with 10 steps. In which step do you think you are?" ///
"How would you describe your cust profile when it comes to financial services?" ///
"Do you use BM Agent to send or receive business payments?" ///
"Do you use BM Agent to receive salary payments?"

labvars gender birthdate birthmonth birthyear q_13a q_13b q_13c_1 q_13c_2 q_14a baseline_status compensation_status ///
"Gender" ///
"Birth date" ///
"Birth month" ///
"Birth year" ///
"Compensation type" ///
"Compensation: mobile phone number" ///
"Compensation: are you sure your number is correct?" ///
"Compensation: alternative mobile phone number" ///
"Lottery: mobile phone number" ///
"Baseline status" ///
"Client compensation status (compensation or lottery)"

**#12. Save cleaned data
save "$dta\cleaned_baseline_client_survey_`date'.dta", replace