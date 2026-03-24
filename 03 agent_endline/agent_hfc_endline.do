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

use "$dta/04 agent_endline/agent_endline_23032026.dta", clear

***************
*DATA ANALYSIS*
***************

local date : display %tdDNCY daily("$S_DATE", "DMY")
capture shell mkdir -p "$output/04 agent_endline/Agent Baseline - `date'"

*checking no consent and number of responses
        gen agents_n = _n  // for notes on total N agents
        drop if informed_consent == 0 // drop people who refuse to participate in the survey

***# SECTION 1: TRANSPARENCY #***

        *q_1a
        forval nmr = 0/1 {
                gen gr_1a_`nmr' = (q_1a == `nmr')
                replace gr_1a_`nmr' = . if missing(q_1a)
        }
	
	set scheme jpalfull
	qui sum agents_n if q_1a!=. 
	
	graph bar gr_1a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you charge {bf:all} clients {bf:the same fee}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
	graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1a.png", as(png) replace

        *q_1b
        forval nmr = 1/2 {
                gen gr_1b_`nmr' = (q_1b == `nmr')
                replace gr_1b_`nmr' = . if missing(q_1b)
        }
	
	set scheme jpalfull
	qui sum agents_n if q_1b!=. 
	
	graph bar gr_1b_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How well do you think customers in your area are {bf:informed}", size(medsmall)) ///
		subtitle("about {bf:the official fees} for transactions set by Bank Mandiri?", size(medsmall)) ///
		legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") size(medsmall) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
	graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1b.png", as(png) replace

        *q_1c
        forval nmr = 1/2 {
                gen gr_1c_`nmr' = (q_1c == `nmr')
                replace gr_1c_`nmr' = . if missing(q_1c)
        }

        set scheme jpalfull
        qui sum agents_n if q_1c!=.

        graph bar gr_1c_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("How do you set these fees?", size(medsmall)) ///
                subtitle(" ", size(medsmall)) ///
                legend(order(1 "I follow the official list" 2 "I set my own prices") size(medsmall) col(1)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1c.png", as(png) replace

        *q_1d
        forval nmr = 0/1 {
                gen gr_1d_`nmr' = (q_1d == `nmr')
                replace gr_1d_`nmr' = . if missing(q_1d)
        }

        set scheme jpalfull
        qui sum agents_n if q_1d !=.

        graph bar gr_1d_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Do you charge all clients the same fee?", size(medsmall)) ///
                subtitle(" ", size(medsmall)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(1)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1d.png", as(png) replace

        *q_1d_1
        forval y = 1/8 {
                gen q_1d_1_new_`y' = ///
                q_1d_1_1_1==`y' | ///
                q_1d_1_1_2==`y' | ///
                q_1d_1_1_3==`y'
        }

        set scheme jpalfull
        qui sum agents_n if q_1d_1_new_1 !=.

        graph bar q_1d_1_new_*, percentages ///
                ytitle("%", size(small)) ///
                ylabel(, labsize(small)) ///
                blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
                title("Type of client charge with low fees?", size(medsmall)) ///
                legend(order(1 "Friends and Family" 2 "High-value customers" 3 "New customers" 4 "Long-term customers" 5 "Lower-income customers" 6 "Local customers" 7 "Can switch agents") ///
                size(small) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1d_1.png", as(png) replace

        *q_1e
        forval nmr = 1/2 {
                gen gr_1e_`nmr' = (q_1e == `nmr')
                replace gr_1e_`nmr' = . if missing(q_1e)
        }

        set scheme jpalfull
        qui sum agents_n if q_1e !=.

        graph bar gr_1e_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("How well do you think customers in your area are informed", size(medsmall)) ///
                subtitle("about the official fees for transactions set by Bank Mandiri?", size(medsmall)) ///
                legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") size(medsmall) col(1)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/1 - q_1e.png", as(png) replace

***# SECTION 2: BRANCHLESS BANKING BUSINESS #***

        *q_2a -- Histogram of q_2a
        set scheme jpalfull
        destring q_2a, replace
        qui sum q_2a if q_2a !=.

        histogram q_2a, percent color(navy*0.80) ///
	        discrete ///
	        xlabel(0(20)100) ///
	        title("Over the last month, what share of your businesses' total revenues", size(medsmall)) ///
                subtitle("come from your branchless banking business?", size(medsmall)) ///
                ytitle("Perc of agents", size(medsmall)) ///
                xtitle("Perc of total revenue", size(medsmall)) ///
	        note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/2 - q_2a_hist.png", as(png) replace

        *q_2a -- Box plot of q_2a
        set scheme jpalfull
        su q_2a, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_2a,  box(1, fcolor(navy*0.80) lcolor(navy*0.80)) yline(`r(mean)', lpattern(.) lcolor(navy*0.80)) ///
	        title("% of total agent banking revenue)", size(medsmall)) ///
	        ytitle("Perc of agent banking revenue", size(medsmall)) ///
	        text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	        text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	        note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/2 - q_2a_boxplot.png", as(png) replace

        *q_2b
        forval nmr = 0/1 {
                gen gr_2b_`nmr' = (q_2b == `nmr')
                replace gr_2b_`nmr' = . if missing(q_2b)
        }

        set scheme jpalfull
        qui sum agents_n if q_2b !=.

        graph bar gr_2b_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Do you also work as an agent for other banks, besides Bank Mandiri?", size(medsmall)) ///
                subtitle(" ", size(medsmall)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(1)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/2 - q_2b.png", as(png) replace

        *q_2c -- Histogram of q_2c
        set scheme jpalfull
        destring q_2c, replace
        qui sum q_2c if q_2c !=.

        histogram q_2c, percent color(maroon*0.95) ///
	        discrete ///
	        xlabel(0(20)100) ///
	        title("Over the last month, what share of your branchless banking business' revenues come from your {bf:BM business}?", size(medsmall)) ///
                subtitle("come from your branchless banking business?", size(medsmall)) ///
                ytitle("Perc of agents", size(medsmall)) ///
                xtitle("Perc of total revenue", size(medsmall)) ///
	        note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/2 - q_2c_hist.png", as(png) replace

        *q_2c -- Box plot of q_2c
        set scheme jpalfull
        su q_2c, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_2c,  box(1, fcolor(maroon*0.95) lcolor(maroon*0.95)) yline(`r(mean)', lpattern (.) lcolor(maroon*0.95)) ///
                title("% of branchless banking revenue from BM business)", size(medsmall)) ///
                ytitle("Perc of branchless banking revenue", size(medsmall)) ///
                text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
                text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/2 - q_2c_boxplot.png", as(png) replace

***# SECTION 3: Follow-up on marketing materials #***

        *#PURE CONTROL AND T1 ONLY
        *q_3a
        forval nmr = 0/1 {
                gen gr_3a_`nmr' = (q_3a == `nmr')
                replace gr_3a_`nmr' = . if missing(q_3a)
        }

        set scheme jpalfull
        qui sum agents_n if q_3a !=.

        graph bar gr_3a_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Have any of your customers contacted you in response to the message?", size(medsmall)) ///
                subtitle("(Pure control and T1)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3a.png", as(png) replace

        *q_3a_1
        forval nmr = 1/5 {
                gen gr_3a_1_`nmr' = (q_3a_1 == `nmr')
                replace gr_3a_1_`nmr' = . if missing(q_3a_1)
        }

        set scheme jpalfull
        qui sum agents_n if q_3a_1 !=.

        graph bar gr_3a_1_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Has the customer feedback to the messages been positive or negative?", size(medsmall)) ///
                subtitle("(Pure control and T1)", size(small)) ///
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(medsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3a_1.png", as(png) replace

        *q_3a_2
        forval nmr = 0/1 {
                gen gr_3a_2_`nmr' = (q_3a_2 == `nmr')
                replace gr_3a_2_`nmr' = . if missing(q_3a_2)
        }

        set scheme jpalfull
        qui sum agents_n if q_3a_2 !=.

        graph bar gr_3a_2_*, percentages /// percent is the default
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("would you say that these marketing messages have helped you increase your business?", size(medsmall)) ///
                subtitle("(Pure control and T1)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3a_2.png", as(png) replace

        *# T2 & T3 TRANSPARENCY
        *q_3b
        forval nmr = 0/1 {
                gen gr_3b_`nmr' = (q_3b == `nmr')
                replace gr_3b_`nmr' = . if missing(q_3b)
        }

        set scheme jpalfull
        qui sum agents_n if q_3b !=.

        graph bar gr_3b_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Have any of your customers contacted you in response to the message?", size(medsmall)) ///
                subtitle("(T2 & T3: Transparency)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3b.png", as(png) replace

        *q_3b_1
        forval nmr = 1/5 {
                gen gr_3b_1_`nmr' = (q_3b_1 == `nmr')
                replace gr_3b_1_`nmr' = . if missing(q_3b_1)
        }       

        set scheme jpalfull
        qui sum agents_n if q_3b_1 !=.

        graph bar gr_3b_1_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Has the customer feedback to the messages been positive or negative?", size(medsmall)) ///
                subtitle("(T2 & T3: Transparency)", size(small)) ///
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(medsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3b_1.png", as(png) replace

        *q_3b_2
        forval nmr = 0/1 {
                gen gr_3b_2_`nmr' = (q_3b_2 == `nmr')
                replace gr_3b_2_`nmr' = . if missing(q_3b_2)
        }       

        set scheme jpalfull
        qui sum agents_n if q_3b_2 !=.

        graph bar gr_3b_2_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("would you say that these marketing messages have helped you increase your business?", size(medsmall)) ///
                subtitle("(T2 & T3: Transparency)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3b_2.png", as(png) replace

        *# T2 & T3 SHROUDING
        *q_3c
        forval nmr = 0/1 {
                gen gr_3c_`nmr' = (q_3c == `nmr')
                replace gr_3c_`nmr' = . if missing(q_3c)
        }     

        set scheme jpalfull
        qui sum agents_n if q_3c !=.   

        graph bar gr_3c_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Have any of your customers contacted you in response to the message?", size(medsmall)) ///
                subtitle("(T2 & T3: Shrouding)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Baseline - `date'/3 - q_3c.png", as(png) replace

        *q_3c_1


