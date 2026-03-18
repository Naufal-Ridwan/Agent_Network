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
gl raw           "$path/06 Survey Data/rawresponses"


* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************

import excel "$raw/04 agent_endline/raw_agent_endline_17032026.xlsx", sheet("Sheet0") firstrow

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

** #3. Convert survey duration to minutes
        destring duration__in_seconds_, replace
        replace duration__in_seconds_ = round(duration__in_seconds_ / 60, .01)
        ren duration__in_seconds_ total_duration
        lab var total_duration "Durations (in minutes)"

** #4. Renaming labels
        rename externalreference unique_code_agent
        label variable unique_code_agent "Unique Code Agent"
        rename informed_consent_1 informed_consent
        label variable informed_consent "Informed Consent"

        label variable q_1a "Do you display a price list with Bank Mandiri's official prices in your shop?"
        label variable q_1b "How well do you think customers in your area are informed about the official fees for transactions set by Bank Mandiri?"
        label variable q_1c "Branchless banking agents charge a fee for each transaction made with them. How do you set these fees?"
        label variable q_1d "Do you charge all clients the same fee?"
        label variable q_1d_1_1 "Family and friends:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_2 "High-value customers:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_3 "New customers:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_4 "Long-time customer:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_5 "Poorer customer:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_6 "Customer from local area:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1d_1_7 "Customer can easily do bus w/ other agents:if not, Which types of customers do you charge the lowest fee?"
        label variable q_1e "How well do you think customers in your area are informed about the official fees for transactions set by Bank Mandiri?"

        label variable q_2a "Over the last month, what share of your businesses' total revenues come from your branchless banking business?"
        label variable q_2b "Do you also work as an agent for other banks, besides Bank Mandiri? "
        label variable q_2c "Over the last month, what share of your branchless banking business' revenues come from your Bank Mandiri business?"

        label variable q_3a "Last month, Bank Mandiri launched a marketing campaign in which messages advertising Mandiri Agen services were sent to all of your customers. Have any of your customers contacted you in response to these messages?"
        label variable q_3a_1 "[If yes] Has the customer feedback to the messages been positive or negative?"
        label variable q_3a_2 "Overall, would you say that these marketing messages advertising Mandiri Agen services to all your customers have helped you increase your business?"
        label variable q_3b "Last month, you chose to participate in a Bank Mandiri marketing plan in which messages advertising Mandiri Agen services and prices were sent to all of your customers. Have any of your customers contacted you in response to these messages?"
        label variable q_3b_1 "[If yes] Has the customer feedback to the messages been positive or negative?"
        label variable q_3b_2 "Overall, would you say that these marketing messages advertising Mandiri Agen services and official prices to all your customers have helped you increase your business?"
        label variable q_3c "Last month, you chose to participate in a Bank Mandiri marketing plan and received messages advertising Mandiri agen services and prices. Have you forwarded these marketing messages to your customers?"
        label variable q_3c_1 "[If yes] To how many of your customers have you forwarded or shown these marketing messages?"
        label variable q_3c_2_1 "Family and friends: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_2 "High-value customers: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_3 "New customers: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_4 "Long-time customer: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_5 "Poorer customer: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_6 "Customer from local area: [If yes] To which type of customer did you forward or show these marketing messages first?"
        label variable q_3c_2_7 "Customer can easily do bus w/ other agents: [If yes] To which type of customer did you forward or show these marketing messages

        label variable q_3c_3 "[If yes] Has the customer feedback to the messages been positive or negative?"
        label variable q_3d "Last month, Bank Mandiri launched a marketing plan in which messages advertising Mandiri Agen services and prices were sent to all of your customers. Have any of your customers contacted you in response to these messages?"
        label variable q_3d_1 "[If yes] Has the customer feedback to the messages been positive or negative?"
        label variable q_3d_2 "Overall, would you say that these marketing messages advertising Mandiri Agen services and official prices to all your customers have helped you increase your business?"
        label variable q_3f "Overall, would you say that these marketing messages advertising Mandiri Agen services and official prices have helped you increase your business?"
        
        label variable q_4a "Over the last month, how much time did you spend advertising your branchless banking services to increase your business?"
        label variable q_4b "Over the last month, how often have you approached customers to encourage them to do more branchless banking transactions? "
        label variable q_4c_1 "Reduced fees charged per transaction: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_2 "Having longer business hours: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_3 "Offering the option to buy on credit: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_4 "Offering complementary services or products: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_5 "Having extra cash in hand: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_6 "Cleanliness premises: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_7 "Better customer service: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_8 "Create more trust among current and potential customers: Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4c_9 "Proximity to customers (for instance, approaching customers): Over the last month, which of the following strategies have you used to encourage your customers to do more branchless banking transactions"
        label variable q_4d "Over the last month, how often do you approached customers with information about prices for BM transactions?"
        label variable q_4e "Over the last month, how often do you approached potential new customers to encourage them to adopt Bank Mandiri financial products? "
        label variable q_4f_1 "Through family contacts: Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_2 "Strategic location and signage in front of the business: Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_3 "Recommendations or referrals: Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_4 "Traveling to or calling potential customers: Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_5 "Advertising campaigns (radio, television, posters, flyers, etc.): Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_6 "Others: Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products?"
        label variable q_4f_6_text "Others_text: [If yes] Over the last month, have you tried any of the following strategies to attract potential new customers to encourage them to adopt Bank Mandiri financial products? If others, please specify:"
        
        label variable q_5a "Since when have you been an agent for Bank Mandiri?"
        label variable q_5b "What is your gender?"
        label variable q_5c "When were you born?"

** #5. Labelling variables

        *label define yes_no questions
        label define yes_no_lbl 0 "No" 1 "Yes"
        destring informed_consent q_1a q_1d q_2b q_3a q_3a_2 q_3b q_3b_2 q_3c q_3d q_3d_2 q_3f, replace
        label values informed_consent q_1a q_1d q_2b q_3a q_3a_2 q_3b q_3b_2 q_3c q_3d q_3d_2 q_3f yes_no_lbl

        *label define q_1b & q_1e
        label define q_1b_lbl 1 "Most clients know the fees well" 2 "Most clients do not know the fees well"
        destring q_1b q_1e, replace
        label values q_1b q_1e q_1b_lbl

        *label define q_1c
        label define q_1c_lbl 1 "I follow the official list" 2 "I set my own prices"
        destring q_1c, replace
        label values q_1c q_1c_lbl

        *label define q_3a_1 q_3b_1 q_3c_3 q_3d_1
        label define positive_negative_lbl 1 "Very positive" 2 "Somewhat positive" 3 "Neutral" 4 "Somewhat negative" 5 "Very negative"
        destring q_3a_1 q_3b_1 q_3c_3 q_3d_1, replace
        label values q_3a_1 q_3b_1 q_3c_3 q_3d_1 positive_negative_lbl

        label define q_4a_lbl 1 "None at all" 2 "Some time" 3 "A lot of time"
        destring q_4a, replace
        label values q_4a q_4a_lbl

        label define q_4b_lbl 1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times a month" 5 "Once a month" 6 "Not at all"
        destring q_4b q_4d q_4e, replace
        label values q_4b q_4d q_4e q_4b_lbl

        rename q_5b gender
        destring gender, replace
        label define gender_lbl 1 "Female" 2 "Male"
        label values gender gender_lbl

        destring compensation_option, replace
        label define compensation_option_lbl 1 "Indomaret" 2 "Alfamart" 3 "Tokopedia"
        label values compensation_option compensation_option_lbl

***#6. Discrete option with mup to three answer
       
       *q_1d_1_1
       destring q_1d_1_1 q_1d_1_2 q_1d_1_3 q_1d_1_4 q_1d_1_5 q_1d_1_6 q_1d_1_7, replace
        forvalues i = 2/7 {
                replace q_1d_1_`i' = `i' if q_1d_1_`i' == 1
        }
        lab define q_1d_1_lbl 1 "Family and friends" 2 "High-value customers" 3 "New customers" 4 "Long-time customer" 5 "Poorer customer" 6 "Customer from local area" 7 "Customer can easily do bus w/ other agents"
        lab values q_1d_1_1 q_1d_1_2 q_1d_1_3 q_1d_1_4 q_1d_1_5 q_1d_1_6 q_1d_1_7 q_1d_1_lbl

        gen q_1d_1_1_1 = .
        gen q_1d_1_1_2 = .
        gen q_1d_1_1_3 = .

        gen count = 0

        forvalues i = 1/7 {
                replace count = count + 1 if q_1d_1_`i' == `i' & count < 3
                replace q_1d_1_1_1 = `i' if q_1d_1_`i' == `i' & count == 1
                replace q_1d_1_1_2 = `i' if q_1d_1_`i' == `i' & count == 2
                replace q_1d_1_1_3 = `i' if q_1d_1_`i' == `i' & count == 3
        }

        drop count
        lab values q_1d_1_1_1 q_1d_1_lbl
        lab values q_1d_1_1_2 q_1d_1_lbl
        lab values q_1d_1_1_3 q_1d_1_lbl
        drop q_1d_1_1 q_1d_1_2 q_1d_1_3 q_1d_1_4 q_1d_1_5 q_1d_1_6 q_1d_1_7

        *q_3c_2
        destring q_3c_2_1 q_3c_2_2 q_3c_2_3 q_3c_2_4 q_3c_2_5 q_3c_2_6 q_3c_2_7, replace
        forvalues i = 2/7 {
                replace q_3c_2_`i' = `i' if q_3c_2_`i' == 1
        }
        lab values q_3c_2_1 q_3c_2_2 q_3c_2_3 q_3c_2_4 q_3c_2_5 q_3c_2_6 q_3c_2_7 q_1d_1_lbl
        gen q_3c_2_1_1 = .
        gen q_3c_2_1_2 = .
        gen q_3c_2_1_3 = .

        gen count = 0
        forvalues i = 1/7 {
                replace count = count + 1 if q_3c_2_`i' == `i' & count < 3
                replace q_3c_2_1_1 = `i' if q_3c_2_`i' == `i' & count == 1
                replace q_3c_2_1_2 = `i' if q_3c_2_`i' == `i' & count == 2
                replace q_3c_2_1_3 = `i' if q_3c_2_`i' == `i' & count == 3
        }
        drop count
        lab values q_3c_2_1_1 q_1d_1_lbl
        lab values q_3c_2_1_2 q_1d_1_lbl
        lab values q_3c_2_1_3 q_1d_1_lbl
        drop q_3c_2_1 q_3c_2_2 q_3c_2_3 q_3c_2_4 q_3c_2_5 q_3c_2_6 q_3c_2_7

        *q_4c_1
        destring q_4c_1 q_4c_2 q_4c_3 q_4c_4 q_4c_5 q_4c_6 q_4c_7 q_4c_8 q_4c_9, replace
        forvalues i = 2/9 {
                replace q_4c_`i' = `i' if q_4c_`i' == 1
        }
        lab define q_4c_lbl 1 "Reduced fees charged per transaction" 2 "Having longer business hours" 3 "Offering the option to buy on credit" ///
        4 "Offering complementary services or products" 5 "Having extra cash in hand" 6 "Cleanliness premises" 7 "Better customer service" ///
        8 "Create more trust among current and potential customers" 9 "Proximity to customers (for instance, approaching customers)"
        lab values q_4c_1 q_4c_2 q_4c_3 q_4c_4 q_4c_5 q_4c_6 q_4c_7 q_4c_8 q_4c_9 q_4c_lbl

        gen q_4c_1_1 = .
        gen q_4c_1_2 = .
        gen q_4c_1_3 = .

        gen count = 0
        forvalues i = 1/9 {
                replace count = count + 1 if q_4c_`i' == `i' & count < 3
                replace q_4c_1_1 = `i' if q_4c_`i' == `i' & count == 1
                replace q_4c_1_2 = `i' if q_4c_`i' == `i' & count == 2
                replace q_4c_1_3 = `i' if q_4c_`i' == `i' & count == 3
        }
        drop count
        lab values q_4c_1_1 q_4c_lbl
        lab values q_4c_1_2 q_4c_lbl
        lab values q_4c_1_3 q_4c_lbl
        drop q_4c_1 q_4c_2 q_4c_3 q_4c_4 q_4c_5 q_4c_6 q_4c_7 q_4c_8 q_4c_9

        *4f_1
        destring q_4f_1 q_4f_2 q_4f_3 q_4f_4 q_4f_5 q_4f_6, replace
        forvalues i = 2/6 {
                replace q_4f_`i' = `i' if q_4f_`i' == 1
        }
        lab define q_4f_lbl 1 "Through family contacts" 2 "Strategic location and signage in front of the business" 3 "Recommendations or referrals" ///
        4 "Word of mouth" 5 "Advertising campaigns (radio, television, posters, flyers, etc.)" 6 "Others"
        lab values q_4f_1 q_4f_2 q_4f_3 q_4f_4 q_4f_5 q_4f_6 q_4f_lbl
        gen q_4f_1_1 = .
        gen q_4f_1_2 = .
        gen q_4f_1_3 = .

        gen count = 0
        forvalues i = 1/6 {
                replace count = count + 1 if q_4f_`i' == `i' & count < 3
                replace q_4f_1_1 = `i' if q_4f_`i' == `i' & count == 1
                replace q_4f_1_2 = `i' if q_4f_`i' == `i' & count == 2
                replace q_4f_1_3 = `i' if q_4f_`i' == `i' & count == 3
        }
        drop count
        lab values q_4f_1_1 q_4f_lbl
        lab values q_4f_1_2 q_4f_lbl
        lab values q_4f_1_3 q_4f_lbl
        drop q_4f_1 q_4f_2 q_4f_3 q_4f_4 q_4f_5 q_4f_6

save "$dta/04 agent_endline/agent_endline_`date'.dta", replace