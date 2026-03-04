*===================================================*
* PILOT - CLIENT SURVEY (BASELINE)					*
* By            : Saskia Maulida					*
* Last Modified : 12 September 2023	              	*
* Stata Ver     : 15                               	*
*===================================================*

clear
set more off

***********
*DATA PATH*
***********

gl user = c(username)

*Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

*Saskia
if "$user" == "ASUS"{
	gl path "C:\Users\ASUS\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\11 Test Runs for Pilot"
	loc initials "sm"
	}


*Set the path (do not meddle with this) 
		gl do			"$path\dofiles"
		gl dta			"$path\dtafiles"
		gl log			"$path\logfiles"
		gl output		"$path\output"
		gl raw			"$path\rawresponses"
	
***IMPORTANT***

*Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************
// ssc install veracrypt // only activate this code if you have yet to install veracrypt command

// veracrypt "$raw\\agentsurvey", mount // only activate this code if you haven't manually mounted the veracrypt

*Import csv 
clear
import delimited "B:\\raw_client_survey_baseline_`date'.csv"
*---------------------------------------------------------------------*

*Create log file
// log using ${log}\log_datachecks_`date'_`initials'

**********
*CLEANING*
**********

drop *firstclick
drop *lastclick
drop *clickcount
drop status recipientlastname recipientfirstname recipientemail externalreference locationlatitude locationlongitude distributionchannel

loc page_duration 1a 1b_1 1b_2 2a 2b_1 2b_2 6b 7a 8b
foreach n of loc page_duration {
	label variable t`n'_pagesubmit "T`n'"
	}
	
* Change var name to label name
labvars durationinseconds informed_consent_1 "total_duration" "informed_consent" 

foreach var of varlist * {
    loc label : variable label `var'
    if ("`label'" != "") {
        local oldnames `oldnames' `var'
        local newnames `newnames' Q_`label'
    }
}

rename (`oldnames')(`newnames')

loc page_duration 1a 1b_1 1b_2 2a 2b_1 2b_2 6b 7a 8b
foreach n of loc page_duration {
	rename Q_T`n' T`n'
	}

rename (Q_StartDate Q_EndDate Q_IPAddress Q_Progress Q_total_duration Q_Finished Q_RecordedDate Q_ResponseId Q_UserLanguage Q_informed_consent) ///
(StartDate EndDate IPAddress Progress total_duration finished RecordedDate ResponseID UserLanguage informed_consent)

* Split multiple answers
loc vartosplit Q_5a
foreach i of loc vartosplit {
	split `i', parse (,) destring
	drop `i'
}

order Q_5a1 Q_5a2 Q_5a3, before(Q_5a_9_TEXT)

* Change value labels

label def yes_no 1 "Yes" 2 "No"
label val informed_consent Q_3a_2 Q_3b Q_11b Q_11c_1 Q_12c Q_12d_1 Q_12d_2 Q_13c_1 yes_no

label def yes_no_idk 1 "Yes" 2 "No" 3 "I don't know"
label val Q_3a_1 yes_no_idk

label def time_period_n 1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "I haven't done this transaction with BM agent"
label val Q_1a Q_2a time_period_n

label def time_period 1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 
label val Q_11c_2 time_period

label def fee 1 "Rp 0 – 750" 2 "Rp 750 – 1.500" 3 "Rp 1.500 – 2.250" 4 "Rp 2.250 – 3.000" 5 "Rp 3.000 – 3.750" 6 "Rp 3.750 – 4.500" 7 "> Rp 4.500"
label val Q_1b_2 Q_2b_2 fee

label def Q_4b 1 "BM agent charged me more than the official fee" 2 "BM agent charged me exactly the official fee" 3 "BM agent charged me less than the official fee"
label val Q_4b Q_4b

label def Q_4c 1 "The agent was happy to help me" 2 "The agent didn't have time & couldn't help" 3 "The agent asked me to do transaction with another agent"
label val Q_4c Q_4c

label def Q_5a 1 "I have been a prior customer" 2 "Can clearly answer my questions" ///
3 "Is within close proximity" 4 "Often has sufficient cash for transactions" ///
5 "Is transparent by displaying official price list" 6 "Is available everytime I need to make transactions" ///
7 "Offers the lowest transaction fees" 8 "Works with the bank where I want to open an account" ///
9 "Others"
label val Q_5a1 Q_5a2 Q_5a3 Q_5a

label def Q_5b 1 "Continue transacting with my regular agent, even if other agents offer lower prices" 2 "Switch to transact with other agents who offer lower prices"
label val Q_5b Q_5b

label def Q_6b 1 "More than agents from other banks" 2 "Same as agents from other banks" 3 "Less than agents from other banks"
label val Q_6b_1 Q_6b_2 Q_6b_3 Q_6b_4 Q_6b_5 Q_6b

label def Q_7a 1 "More than other banks" 2 "Same as other banks" 3 "Less than other banks"
label val Q_7a_1 Q_7a_2 Q_7a_3 Q_7a_4 Q_7a_5 Q_7a_6 Q_7a 

label def Q_8a 1 "Many agents available in my area, and I have a lot of options" 2 "Limited number of agents available in my area, and I have a limited number of options"
label val Q_8a Q_8a

label def Q_9d_1 1 "Yes, the agent approached me first" 2 "No, I was interested in signing myself up" 3 "I don't remember"
label val Q_9d_1 Q_9d_1

label def Q_9d_2 1 "Trustworthiness of the agent" ///
2 "Quality of products and services they offer" ///
3 "Reliability and availability of sufficient cash balance for withdrawals" ///
4 "Convenience and proximity to your location" ///
5 "Low fees for transactions" ///
6 "Help they provide with transactions"
label val Q_9d_2 Q_9d_2

label def Q_9e 1 "More honest & transparent" ///
2 "No difference" ///
3 "Less honest & transparent"
label val Q_9e Q_9e

label def Q_10a_10b 1 "I'd be indifferent" ///
2 "I'd think it is unfair, and switch to transact with another agent" ///
3 "I'd think it is unfair, but continue transacting with my regular agent" ///
4 "I'd think it is fair"
label val Q_10a Q_10b Q_10a_10b

label def Q_10c 1 "Agent A, who charges an official fee of 2k" ///
2 "Agent B, who charges an official fee of 1k + interest fee of 1k" ///
3 "I am indifferent"
label val Q_10c Q_10c

label def gender 0 "Male" 1 "Female"
label val Q_12a gender

label def age 1 "18-25 years old" 2 "26-30 years old" ///
3 "31-40 years old" 4 "41-50 years old" 5 ">50 years old" 
label val Q_12b age

label def compensation 1 "Phone credit Telkomsel" ///
2 "Phone credit 3 (Three)" ///
3 "Phone credit XL" ///
4 "Phone credit Axis" ///
5 "Phone credit Indosat" ///
6 "E-money OVO" ///
7 "E-money Go-Pay" ///
8 "E-Money LinkAja" ///
9 "E-Money DANA" ///
10 "E-money ShopeePay" 
label val Q_13a compensation 

label def correction 1 "No correction" 2 "Phone number correction"
label val Q_13c_1 correction

* Change years
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023
forval i = 1/11 {
    local year : word `i' of `years'
    replace Q_9b_1 = `year' if Q_9b_1 == `i'
}

* Change var labels

labvars Q_1a Q_1b_1_1 Q_1b_2 Q_2a Q_2b_1_1 Q_2b_2 ///
"Cash deposit: When was your last transaction with BM agent?" ///
"Cash deposit: Amount of fee charged by BM agent" ///
"Cash deposit: Approx range of fee charged by BM agent" ///
"Cash withdrawal: When was your last transaction with BM agent?" ///
"Cash withdrawal: Amount of fee charged by BM agent" ///
"Cash withdrawal: Approx range of fee charged by BM agent" 

labvars Q_3a_1 Q_3a_2 Q_3b Q_4b Q_4b_DO Q_4c Q_4c_DO Q_4d_1 ///
"Is there an official pricelist from BM that agents must follow?" ///
"Does your regular BM agent display the official pricelist from the bank?" ///
"Most agents charge higher fees than the bank's official pricelist" ///
"Latest transaction with regular BM agent: Perceived charged fees" ///
"Latest transaction with regular BM agent: Perceived charged fees (DO)" ///
"Latest transaction with regular BM agent: Agent's treatment" ///
"Latest transaction with regular BM agent: Agent's treatment (DO)" ///
"Latest transaction with regular BM agent: Satisfaction with agent's services"

labvars Q_5a1 Q_5a2 Q_5a3 Q_5a_9_TEXT Q_5a_DO Q_5b ///
"When selecting a regular agent (1): Important characteristics" ///
"When selecting a regular agent (2): Important characteristics" ///
"When selecting a regular agent (3): Important characteristics" ///
"When selecting a regular agent (Others): Important characteristics" ///
"When selecting a regular agent (DO): Important characteristics" ///
"Agreement with a statement on price sensitivity"

labvars Q_6b_1 Q_6b_2 Q_6b_3 Q_6b_4 Q_6b_5 Q_6b_DO ///
"Regular BM agent vs agents from other banks: Honest or fair" ///
"Regular BM agent vs agents from other banks: Competent" ///
"Regular BM agent vs agents from other banks: Socially minded" ///
"Regular BM agent vs agents from other banks: Trustworthy" ///
"Regular BM agent vs agents from other banks: Interested in helping clients" ///
"Regular BM agent vs agents from other banks (DO)"

labvars Q_7a_1 Q_7a_2 Q_7a_3 Q_7a_4 Q_7a_5 Q_7a_6 Q_7a_DO ///
"BM vs other banks: Cares about building long-term relationship" ///
"BM vs other banks: Cares about well-being of clients" ///
"BM vs other banks: Honest and trustworthy" ///
"BM vs other banks: Cares about educating clients" ///
"BM vs other banks: Cares about benefitting society" ///
"BM vs other banks: Cares about clients new to banking" ///
"BM vs other banks (DO)" 

labvars Q_8a Q_8b Q_9b_1 Q_9c_1 Q_9d_1 Q_9d_1_DO Q_9d_2 Q_9d_2_DO Q_9e Q_9e_DO ///
"Agreement with a statement on availability of agents in the area" ///
"How many agents are in your area? (BM agents and agents from other banks)" ///
"Since when you've been transacting with your regular BM agent?" ///
"What % of ur branchless banking transactions you do with ur regular BM agent?" ///
"Did your regular BM agent approach you to sign up for BM products?" ///
"Did your regular BM agent approach you to sign up for BM products? (DO)" ///
"When your regular BM agent approached you, what was her main strategy?" ///
"When your regular BM agent approached you, what was her main strategy? (DO)" ///
"Regular BM agent vs agents from other banks: Honesty & transparency" ///
"Regular BM agent vs agents from other banks: Honesty & transparency (DO)"

labvars Q_10a Q_10a_DO Q_10b Q_10b_DO Q_10c Q_10c_DO Q_10d_1 Q_11b Q_11c_1 Q_11c_2 ///
"How you'd react if ur regular agent charges a higher fee than the bank's prices" ///
"How you'd react if ur regular agent charges a higher fee than the bank's prices (DO)" ///
"How you'd react if ur regular agent charges a lower fee to other clients" ///
"How you'd react if ur regular agent charges a lower fee to other clients (DO)" ///
"Who'd you choose between agents who both charge 2k?" ///
"Who'd you choose between agents who both charge 2k? (DO)" ///
"Percentage of the total charged fees for agent's commission" ///
"Outside your regular BM agent, do you transact with other BM agents?" ///
"Outside your regular BM agent, do you transact with agents from other banks?" ///
"When was the last time you transacted with agents from other banks?"

labvars Q_12a Q_12b Q_12c Q_12d_1 Q_12d_2 Q_13a Q_13b Q_13c_1 Q_13c_2 ///
"What is your gender?" ///
"How old are you?" ///
"Are you self-employed?" ///
"Do you use agent banking services for your business?" ///
"Do you use agent banking services to receive your salary?" ///
"Compensation type" ///
"Active phone numbers for compensation distribution" ///
"Confirmation on the inputted phone number for compensation distribution" ///
"Revision: Active phone numbers for compensation distribution"

drop if informed_consent==2

replace Q_1b_1_1 = ceil(Q_1b_1_1 / 100) * 100
replace Q_2b_1_1 = ceil(Q_2b_1_1 / 100) * 100

* Convert survey duration to minutes
replace total_duration = round(total_duration / 60, .01)

* Save cleaned data
save "A:\\cleaned_client_survey_baseline_`date'.dta", replace
