*===================================================*
* PILOT - AGENT SURVEY								*
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
import delimited "B:\\raw_agent_survey_`date'.csv"



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

loc page_duration 5 6a 6b 6c 7 8a 8b 10a
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

loc page_duration 5 6a 6b 6c 7 8a 8b 10a
foreach n of loc page_duration {
	rename Q_T`n' T`n'
	}

rename (Q_StartDate Q_EndDate Q_IPAddress Q_Progress Q_total_duration Q_Finished Q_RecordedDate Q_ResponseId Q_UserLanguage Q_informed_consent) ///
(StartDate EndDate IPAddress Progress total_duration finished RecordedDate ResponseID UserLanguage informed_consent)

* Split multiple answers
loc vartosplit Q_2a Q_2b 
foreach i of loc vartosplit {
	split `i', parse (,) destring
	drop `i'
}

* Change years
local years 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023
forval i = 1/11 {
    local year : word `i' of `years'
    replace Q_10d_1 = `year' if Q_10d_1 == `i'
}

* Change value labels
label def yes_no 1 "Yes" 2 "No"
label val informed_consent Q_1a Q_1c Q_9a Q_12c_1 yes_no

label def Q_1b 1 "Most clients know the fees well" 2 "Most clients do not know the fees"
label val Q_1b Q_1b

label def Q_2a 1 "The client has been a prior customer" 2 "Can clearly answer clients' questions" ///
3 "Is within close proximity" 4 "Often has sufficient cash for transactions" ///
5 "Is transparent by displaying official price list" 6 "Is available everytime the client needs to make transactions" ///
7 "Offers the lowest transaction fees" 8 "Works with the bank where the client wants to open an account" ///
9 "Others"
label val Q_2a1 Q_2a2 Q_2a3 Q_2a

label def Q_2b 1 "The client has been a prior customer" 2 "Can clearly answer clients' questions" ///
3 "Is within close proximity" 4 "Often has sufficient cash for transactions" ///
5 "Is transparent by displaying official price list" 6 "Is available everytime the client needs to make transactions" ///
7 "Offers the lowest transaction fees" 8 "Works with the bank where the client wants to open an account" ///
9 "Others"
label val Q_2b1 Q_2b2 Q_2b3 Q_2b

label def Q_3a 1 "Many agents available in the area and clients have many options to choose from" ///
2 "Limited number of agents available in the area and clients have limited options to choose from"
label val Q_3a Q_3a

label def Q_3b 1 "Continue doing business with me, even if other agents offer lower prices" ///
2 "Change to other agents who offer lower prices"
label val Q_3b Q_3b

label def section4 1 "Indifferent" 2 "Thinks it is unfair, and will do transactions with another agent" ///
3 "Thinks it is unfair, but will continue making transactions with the same agent" ///
4 "Thinks it is fair"
label val Q_4a Q_4b section4

label def outcome_measure 1 "Plan A" 2 "Plan B"
label val Q_8a Q_8b outcome_measure

label def Q_10b 1 "High (a lot of competition)" 2 "Neither high nor low" ///
3 "Low (not much competition)"
label val Q_10b Q_10b

label def Q_10c 1 "Easy (a lot of demand from people around)" ///
2 "Neither easy nor difficult" 3 "Difficult (not much demand from people around)"
label val Q_10c Q_10c

label def gender 0 "Male" 1 "Female"
label val Q_11a gender

label def age 1 "18-25 years old" 2 "26-30 years old" ///
3 "31-40 years old" 4 "41-50 years old" 5 ">50 years old" 
label val Q_11b age

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
label val Q_12a compensation 

label def correction 1 "No correction" 2 "Phone number correction"
label val Q_12c_1 correction

* Change var labels

labvars Q_1a Q_1b Q_1c ///
"Do u think most clients know that BM has an official pricelist?" ///
"How well do u think clients are informed about the bank's official pricelist?" ///
"Do u think m-banking clients prefers agent who displays the official pricelist?"

order Q_2a1 Q_2a2 Q_2a3, before(Q_2a_9_TEXT)
labvars Q_2a1 Q_2a2 Q_2a3 Q_2a_9_TEXT Q_2a_DO ///
"When deciding to open a new acc (1): Most important agent's characteristics" ///
"When deciding to open a new acc (2): Most important agent's characteristics" ///
"When deciding to open a new acc (3): Most important agent's characteristics" ///
"When deciding to open a new acc (Others): Most important agent's characteristics" ///
"When deciding to open a new acc (DO): Most important agent's characteristics"

order Q_2b1 Q_2b2 Q_2b3, before(Q_2b_9_TEXT)
labvars Q_2b1 Q_2b2 Q_2b3 Q_2b_9_TEXT Q_2b_DO ///
"When selecting a regular agent (1): Most important agent's characteristics" ///
"When selecting a regular agent (2): Most important agent's characteristics" ///
"When selecting a regular agent (3): Most important agent's characteristics" ///
"When selecting a regular agent (Others): Most important agent's characteristics" ///
"When selecting a regular agent (DO): Most important agent's characteristics"

labvars Q_3a Q_3b Q_4a Q_4a_DO Q_4b Q_4b_DO ///
"Agreement w/ statement on agent options that clients have" ///
"Agreement w/ statement on clients' sensitivity to prices" ///
"How client'd react if the agent charges a higher fee than the bank's prices" ///
"How client'd react if the agent charges a higher fee than the bank's prices (DO)" ///
"How client'd react if the agent charges a lower fee to other clients" ///
"How client'd react if the agent charges a lower fee to other clients (DO)"

labvars Q_5 Q_6a Q_6b Q_6c Q_7 Q_8a Q_8a_DO Q_8b Q_8b_DO ///
"Estimated change in the number of agents (in %)" ///
"Treatment group: Information on high level of competition" ///
"Treatment group: Information on low level of competition" ///
"Control" ///
"Treatment groups only: Estimated change in the number of agents (in %)" ///
"Outcome measure for the treatment groups" ///
"Outcome measure for the treatment groups (DO)" ///
"Outcome measure for the control group" ///
"Outcome measure for the control group (DO)" 

labvars Q_9a Q_9b_1 Q_10a Q_10b Q_10b_DO Q_10c Q_10c_DO Q_10d_1 ///
"Do you also work as an agent for other banks?" ///
"% of revenue from transactions using BM EDC within the last 1 year" ///
"How many agents are in your area? (BM agents and agents from other banks" ///
"Current level of competition with other agents in your area" ///
"Current level of competition with other agents in your area (DO)" ///
"How easy for you to attract new clients?" ///
"How easy for you to attract new clients? (DO)" ///
"Since when have you been an agent for BM?" 

labvars Q_11a Q_11b Q_12a Q_12b Q_12c_1 Q_12c_2 ///
"Gender" ///
"Age category" ///
"Compensation type" ///
"Active phone numbers for compensation distribution" ///
"Confirmation on the inputted phone number for compensation distribution" ///
"Revision: Active phone numbers for compensation distribution"

gen treatment_control = 0 if Q_6c!=. & Q_6b==. & Q_6a==.
replace treatment_control = 1 if Q_6b!=. & Q_6c==. & Q_6a==.
replace treatment_control = 2 if Q_6a!=. & Q_6b==. & Q_6c==.

drop if informed_consent==2

label def treatment_control 0 "Control group" 1 "Treatment group (low level)" 2 "Treatment group (high level)"
label val treatment_control treatment_control

gen outcome_measures_all = Q_8a
replace outcome_measures_all = Q_8b if Q_8b != .
label val outcome_measures_all outcome_measure

drop if Progress==0

labvars group treatment_control outcome_measures_all agent_codes ///
"Strata group" ///
"Treatment groups" ///
"Choice of marketing plans for all groups" ///
"Agent codes"

* Convert survey duration to minutes
replace total_duration = round(total_duration / 60, .01)


* Save cleaned data
save "A:\\cleaned_agent_survey_`date'.dta", replace
