*===================================================*
* Full-Scale - Client Survey (Baseline)
* Currently cleaning the benchtest survey
* Author: Riko
* Last modified: 2 Sep 2025
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
// dis c(username) // activate this code if you need to check your username

* Muthia
    gl path "/Users/auliamuthia/Desktop/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"

* Set the path
gl do            "$path/dofiles/client_baseline"
gl dta           "$path/dtafiles"
gl log           "$path/logfiles"
gl output        "$path/output"
gl raw           "$path/rawresponses/client_baseline"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*******************************************
**--------------IMPORT DATA--------------**
*******************************************
import excel "${raw}/[Full-Scale]+Baseline+Survey+to+Clients+(Launched)_December+16,+2025_01.41.xlsx", firstrow clear

********************************************
**----------------CLEANING----------------**
********************************************
**#1. Drop unnecessary obs & variables
ren *, lower
drop if status == "1"
drop if progress == "0"
drop status recordeddate recipientlastname-recipientemail distributionchannel q_language // ipaddress locationlatitude --Jibril: I prefer to keep Lat, Long, and IP Address as these variables are our backup to identify user's location

**#2 Change var name to label name 
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

* Lowercase all vars EXCEPT ones containing uppercase "DO"
local tolower
foreach v of varlist _all {
    if strpos("`v'", "DO") == 0 {
        local tolower `tolower' `v'
    }
}
if "`tolower'" != "" rename (`tolower'), lower

* Drop the first row since it's now in labels
drop in 1

* Rename manually for several columns
ren *, lower
ren q_12j gender
ren q_12k_1 birthyear
ren (q_3c_1_1_4 q_3c_1_1_5 q_3c_1_1_6 q_3c_1_1_7 q_3c_1_1_11) (q_3c_1_1_3 q_3c_1_1_4 q_3c_1_1_5 q_3c_1_1_6 q_3c_1_1_7)
ren (q_5a_10 q_5a_12 q_5a_9 q_5a_13 q_5a_14) (q_5a_3 q_5a_7 q_5a_8 q_5a_9 q_5a_10)
ren (q_4_a q_4_b q_4_c q_4_d q_4_e) (q_4a q_4b q_4c q_4d q_4e)

drop consent_comp_1

**#3. Convert survey duration to minutes
ren duration__in_seconds_ total_duration
destring total_duration, replace force
replace total_duration = round(total_duration / 60, .01)

/*
**#4. Concatenate the randomization order (DO refer to Display Order)
loc newvars q_3a_do q_3a_1_do q_3c_1_1_do q_5a_do q_5b_do q_7_do q_8_do q_9_do q_11a_do q_12e_do
loc ords q_3a q_3a_1 q_3c_1_1_g q_5a_10 q_5b q_7d q_8f q_9e q_11a q_12e

forval i = 1/10 {
    local newvar : word `i' of `newvars'
    local ord    : word `i' of `ords'

    egen `newvar' = concat(`newvar'_*) , punct(|)
    order `newvar', after(`ord')
    replace `newvar' = "" if missing(`ord')
    drop `newvar'_*
}
*/

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

**#5. Convert input number (amount of transaction) from string to int
local inpt q_1a_1 q_1b_1 q_2a_1 q_2b_1
destring `inpt', replace ignore("." "-")

**#6. Recode "I do not know" value to missing for the slider answer
destring q_1a_2 q_2a_2, replace force
recode q_1a_2 q_2a_2 (99 = .)

**#7. Convert years
* BM Agent
destring q_12a_1, replace force
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
forval i = 1/12 {
    local year : word `i' of `years'
    replace q_12a_1 = `year' if q_12a_1 == `i'
}

* Year of Birth
destring birthyear, replace force
replace birthyear = birthyear + 1899


**#9. Compensation 
replace q_13a = "Voucher Indomaret" if q_13a == "1"
replace q_13a = "Voucher Alfamart" if q_13a == "2"
replace q_13a = "Voucher Tokopedia" if q_13a == "3"

**#10. Change value labels
destring q_3b-q_3c_1_1_7 q_10e q_12h q_12i q_4a q_4b q_4e, replace force
la def yes_no 1 "Yes" 0 "No"
la val q_3b-q_3c_1_1_7 q_10e q_12h q_12i q_4a q_4b q_4e yes_no

destring q_4a q_4b q_4e, replace force
la def yes_no_2 1 "Yes" 2 "No"
la val q_4a q_4b q_4e yes_no_2

destring q_4c, replace force
la def q_4c 1 "No wait time" 2 "5-10 minutes" 3 "10-15 minutes" 4 "15-30 minutes" 5 "30-45 minutes" 6 "More than 45 minutes"
la val q_4c q_4c

destring q_4d, replace force
la def q_4d 1 "Transaction was processed on first visit" 2 "2 times" 3 "3 times" 4 "4 times" 5 "5 or more times"
la val q_4d q_4d

destring q_1a q_1b q_2a q_2b, replace force
la def last_time 1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "I have not done this transaction before"
la val q_1a q_1b q_2a q_2b last_time

destring q_1a_3 q_2a_3, replace force
la def fee_approx 1 "Rp 0 – 500" 2 "Rp 500 – 1.500" 3 "Rp 1.500 – 2.500" 4 "Rp 2.500 – 3.500" 5 "Rp 3.500 – 4.500" 6 "Rp 4.500 – 5.500" 7 "Rp 5.500 – 6.500" 8 "More than Rp. 6.500"
la val q_1a_3 q_2a_3 fee_approx

destring q_5a_1-q_5a_10, replace force
la def likert_important 1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important"
la val q_5a_1-q_5a_10 likert_important

destring q_6a q_6b, replace force
la def fairness_perception 1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair"
la val q_6a q_6b fairness_perception

destring q_8a - q_8f q_9a - q_9e, replace force 
la def likert_agree 1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree"
la val q_8a - q_8f q_9a - q_9e likert_agree

destring q_10c q_10d, replace force
la def likert_approach 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all"
la val q_10c q_10d likert_approach

destring q_7a-q_7d, replace force
la def likert_confidence 1 "A great deal of confidence" 2 "Quite a lot of confidence" 3 "Not very much confidence" 4 "No confidence at all"
la val q_7a-q_7d likert_confidence

destring q_3a q_3a, replace force 
la def q_3a 1 "There's an official price and the agent has to stick with it" 2 "There's an official price, but agent can charge more/less" 3 "No official price and agent can decide the price" 4 "The government sets the prices" 5 "I do not know"
la val q_3a q_3a

destring q_3a_1, replace force
la def q_3a_1 1 "More" 2 "Less" 3 "Depends on the client (sometimes more/less)"
la val q_3a_1 q_3a_1

destring q_5b, replace force
la def q_5b 1 "Continue doing business w/ regular agent, even if others offer lower prices" 2 "Change to other agents who offer lower prices"
la val q_5b q_5b

destring q_6c, replace force
la def q_6c 1 "Agent A" 2 "Agent B" 3 "I would be indifferent"
la val q_6c q_6c

destring q_10a, replace force
la def q_10a 1 "None at all" 2 "Some time" 3 "A lot of time"
la val q_10a q_10a

destring q_10b, replace force
la def q_10b 1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree"
la val q_10b q_10b

destring q_11a, replace force 
la def q_11a 1 "There are many agents in my area" 2 "There are limited agents in my area"
la val q_11a q_11a

destring q_12b, replace force 
la def q_12b 1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years"
la val q_12b q_12b

destring q_12c, replace force
la def q_12c 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Every 3 months" 7 "Every 6 months" 8 "Once a year"
la val q_12c q_12c

destring q_12e, replace force
la def q_12e 0 "They are honest and charge the correct prices" 1 "They are not honest and often overcharge customers"
la val q_12e q_12e

destring q_12g, replace force
la def q_12g 1 "New & don't know much about products and prices" 2 "Somewhat new, and still learning about products and prices" 3 "Somewhat experienced, and familiar with products and prices" 4 "Very experienced, and fully informed about products and prices"
la val q_12g q_12g

destring gender, replace force
la def gender 1 "Female" 0 "Male"
la val gender gender


**#11. Change variable labels
* ---- Q1: Deposits ----
la var q_1a   "When was the last time you did a cash deposit with BM Agent?"
la var q_1a_1 "In your last transaction with BM Agent, how much did you deposit?"
la var q_1a_2 "Last transaction fee charged by BM Agent for a cash deposit"
la var q_1a_3 "Approximate transaction fee charged by BM Agent for last cash deposit"
la var q_1a_4 "Last 3 months, how many deposits have you made with BM Agent?"
la var q_1b   "When was the last time you did a cash deposit with a non-BM Agent?"
la var q_1b_1 "In your last transaction with a non-BM Agent, how much did you deposit?"
la var q_1b_2 "Last 3 months, how many deposits have you made with a non-BM Agent?"

* ---- Q2: Withdrawals ----
la var q_2a   "When was the last time you did a cash withdrawal with BM Agent?"
la var q_2a_1 "In your last transaction with BM Agent, how much did you withdraw?"
la var q_2a_2 "Last transaction fee charged by BM Agent for a cash withdrawal"
la var q_2a_3 "Approximate transaction fee charged by BM Agent for last cash withdrawal"
la var q_2a_4 "Last 3 months, how many withdrawals have you made with BM Agent?"
la var q_2b   "When was the last time you did a cash withdrawal with a non-BM Agent?"
la var q_2b_1 "In your last transaction with a non-BM Agent, how much did you withdraw?"
la var q_2b_2 "Last 3 months, how many withdrawals have you made with a non-BM Agent?"

* ---- Q3: Pricing & fairness ----
la var q_3a        "How do you think banking agents set a fee for each transaction?"
la var q_3a_1      "Does the agent typically charge more or less than official price?"
la var q_3b        "Does your BM Agent display the official price at his/her shop?"
la var q_3c        "Does your BM Agent set the same price for everyone?"
la var q_3c_1_1_1  "Who pays less: friends and family"
la var q_3c_1_1_2  "Who pays less: high-value cust"
la var q_3c_1_1_3  "Who pays less: new cust"
la var q_3c_1_1_4  "Who pays less: long-time cust"
la var q_3c_1_1_5  "Who pays less: poorer cust"
la var q_3c_1_1_6  "Who pays less: cust from local area"
la var q_3c_1_1_7  "Who pays less: cust who can easily do business w/ other agents"

* ---- Q4: Agents quality ----
la var q_4 "How satisfied were you with your BM Agent service (last transaction)?"
la var q_4a "Was the agent present when you first attempted the transaction?"
la var q_4b "Was the agent able to complete the exact transaction you wanted to do?"
la var q_4c "How long did you have to wait at the agent until your transaction was processed?"
la var q_4d "How many times did you have to visit the agent until the transaction you wanted to make was successful?"
la var q_4e "Did the agent clearly tell you the amount of the fee they would charged in addition to the transaction amount?"

* ---- Q5: Important characteristics ----
la var q_5a_1   "Important characteristics: I've been a prior customer"
la var q_5a_2   "Important characteristics: agent can clearly answer question"
la var q_5a_3   "Important characteristics: agent proximity to home or workplace"
la var q_5a_4   "Important characteristics: agent has sufficient cash balance"
la var q_5a_5   "Important characteristics: price transparent and displayed on the store"
la var q_5a_6   "Important characteristics: agent always available every time needed"
la var q_5a_7   "Important characteristics: agent offers the lowest price"
la var q_5a_8   "Important characteristics: agent works w/ the bank whr I want to open acc"
la var q_5a_9   "Important characteristics: I trust the agent"
la var q_5a_10  "Important characteristics: agent charges everyone the same prices"
la var q_5b     "Which of the following statements do you agree with most?"

* ---- Q6: Reactions & preference ----
la var q_6a "My reaction if my BM Agent charged other cust a lower fee than me"
la var q_6b "My reaction if my BM Agent charged me 50% higher than other cust"
la var q_6c "Preference to do a regular transaction when there are only two agents"

* ---- Q7: Views on BM & agents ----
la var q_7a   "Views on BM Agent & BM: confidence in banks"
la var q_7b   "Views on BM Agent & BM: confidence in BM"
la var q_7c   "Views on BM Agent & BM: confidence in BM agent"
la var q_7d   "Views on BM Agent & BM: confidence that BM Agent will give the best price"

* ---- Q8: Perceptions of BM Agent ----
la var q_8a   "Agree/no: my BM Agent is honest and trustworthy"
la var q_8b   "Agree/no: my BM Agent puts cust well-being above profits"
la var q_8c   "Agree/no: my BM Agent treats all cust equally well"
la var q_8d   "Agree/no: my BM Agent is transparent about pricing"
la var q_8e   "Agree/no: my BM Agent does his/her job well"
la var q_8f   "Agree/no: my BM Agent offers reliable service"

* ---- Q9: Perceptions of BM ----
la var q_9a   "Agree/no: BM is honest and trustworthy"
la var q_9b   "Agree/no: BM puts cust well-being above profits"
la var q_9c   "Agree/no: BM treats all cust equally well"
la var q_9d   "Agree/no: BM is transparent about pricing"
la var q_9e   "Agree/no: BM offers reliable service"

* ---- Q10: Agent outreach / marketing ----
la var q_10a "How much time did your BM Agent spend advertising his services last month?"
la var q_10b "Agree/no: BM Agent did all to convince people to adopt BM Agent products last mo"
la var q_10c "Has your BM Agent approached you to do more agent transactions last month?"
la var q_10d "Has your BM Agent approached you to adopt new BM financial products last month?"
la var q_10e "Has your BM Agent approached you w/ new info abt BM transaction fees last month?"
la var q_10f "Have you ever taken any benefits* from your agent?"
la var q_10g "In the past month, how many times have you visited the store of the agent to purchase items/services other than financial services?"

* ---- Q11: Market structure ----
la var q_11a    "Which of the following statements do you agree with most?"
la var q_11b    "How many branchless banking agents are in your area?"

* ---- Q12: Relationship & profile ----
la var q_12a_1  "Since when have you been doing transactions with your BM Agent?"
la var q_12b    "For how long have you known your BM Agent?"
la var q_12c    "How often do you talk with your BM Agent?"
la var q_12d    "What % of your overall agent transactions do you do with your BM Agent?"
la var q_12e    "Which of the following best describes ur opinion abt banking agents in general?"
la var q_12f    "Imagine a ladder with 10 steps. In which step do you think you are?"
la var q_12g    "How would you describe your cust profile when it comes to financial services?"
la var q_12h    "Do you use BM Agent to send or receive business payments?"
la var q_12i    "Do you use BM Agent to receive salary payments?"

* ---- Demographics & compensation ----
la var gender              "Gender"
la var birthyear           "Birth year"
la var q_13a               "Compensation type"
la var baseline_status     "Baseline status"

drop q_3a_do_1 q_3a_do_2 q_3a_do_3 q_3a_do_4 q_3a_do_5 q_3a_1_do_1 q_3a_1_do_2 q_3a_1_do_3 q_3c_1_1_do_1 q_3c_1_1_do_2 q_3c_1_1_do_4 q_3c_1_1_do_5 q_3c_1_1_do_6 q_3c_1_1_do_7 q_3c_1_1_do_11 q_5a_do_1 q_5a_do_2 q_5a_do_10 q_5a_do_4 q_5a_do_5 q_5a_do_6 q_5a_do_12 q_5a_do_9 q_5a_do_13 q_5a_do_14 q_5b_do_1 q_5b_do_2 q_7_do_7a q_7_do_7b q_7_do_7c q_7_do_7d q_8_do_8a q_8_do_8b q_8_do_8c q_8_do_8d q_8_do_8e q_8_do_8f q_9_do_9a q_9_do_9b q_9_do_9c q_9_do_9d q_9_do_9e q_11a_do_1 q_11a_do_2 q_12e_do_0 q_12e_do_1

destring q_1a_1 q_1a_2 q_1a_4 q_1b_1 q_1b_2 q_2a_1 q_2a_2 q_2a_4 q_2b_1 q_2b_2, replace float


**#12. Save cleaned data
save "$dta/cleaned_baseline_client_survey_`date'.dta", replace
export delimited using "$dta/cleaned_baseline_client_survey_`date'.csv", replace
