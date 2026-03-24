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

use "$dta/04 agent_endline/agent_endline_24032026.dta", clear

***************
*DATA ANALYSIS*
***************

        local date : display %tdDNCY daily("$S_DATE", "DMY")
        capture shell mkdir -p "$output/04 agent_endline/Agent Endline - `date'"

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
	graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1a.png", as(png) replace

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
	graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1b.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1c.png", as(png) replace

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
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1d.png", as(png) replace

        *q_1d_1
        forval y = 1/7 {
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
        graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1d_1.png", as(png) replace

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
                title("How well do you think customers in your area are {bf:informed}", size(medsmall)) ///
                subtitle("about {bf:the official fees} for transactions set by Bank Mandiri?", size(medsmall)) ///
                legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") size(medsmall) col(1)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/1 - q_1e.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/2 - q_2a_hist.png", as(png) replace

        *q_2a -- Box plot of q_2a
        set scheme jpalfull
        su q_2a, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_2a,  box(1, fcolor(navy*0.80) lcolor(navy*0.80)) yline(`r(mean)', lpattern(.) lcolor(navy*0.80)) ///
	        title("% of total agent banking revenue", size(medsmall)) ///
	        ytitle("Perc of agent banking revenue", size(medsmall)) ///
	        text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	        text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	        note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Endline - `date'/2 - q_2a_boxplot.png", as(png) replace

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
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/2 - q_2b.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/2 - q_2c_hist.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/2 - q_2c_boxplot.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3a.png", as(png) replace

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
                title("Has the customer {bf:feedback} to the messages been positive or negative?", size(medsmall)) ///
                subtitle("(Pure control and T1)", size(small)) ///
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(vsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3a_1.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3a_2.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3b.png", as(png) replace

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
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(vsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3b_1.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3b_2.png", as(png) replace

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
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3c.png", as(png) replace

        *q_3c_1 -- histogram of q_3c_1
        set scheme jpalfull
        destring q_3c_1, replace
        qui sum q_3c_1 if q_3c_1 !=.

        histogram q_3c_1, percent color(emerald*0.95) ///
                discrete ///
                xlabel(0(10)50) ///
                title("To how many of your customers have you {bf:forwarded or shown} these marketing messages?", size(medsmall)) ///
                subtitle("(T2 & T3: Shrouding)", size(small)) ///
                ytitle("Perc of agents", size(medsmall)) ///
                xtitle("Number of customers", size(medsmall)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3c_1_hist.png", as(png) replace

        *q_3c_1 -- box plot of q_3c_1
        set scheme jpalfull
        su q_3c_1, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_3c_1,  box(1, fcolor(emerald*0.95) lcolor(emerald*0.95)) yline(`r(mean)', lpattern (.) lcolor(emerald*0.95)) ///
                title("Number of customers forwarded/shown the marketing messages", size(medsmall)) ///
                ytitle("Number of customers", size(medsmall)) ///
                text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
                text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3c_1_boxplot.png", as(png) replace

        *q_3c_2
        forval y = 1/7 {
                gen q_3c_2_new_`y' = ///
                q_3c_2_1_1==`y' | ///
                q_3c_2_1_2==`y' | ///
                q_3c_2_1_3==`y'
        }

        set scheme jpalfull
        qui sum agents_n if q_3c_2_new_1 !=.

        graph bar q_3c_2_new_*, percentages ///
                ytitle("%", size(small)) ///
                ylabel(, labsize(small)) ///
                blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
                title("Type of client charge with low fees?", size(medsmall)) ///
                legend(order(1 "Friends and Family" 2 "High-value customers" 3 "New customers" 4 "Long-term customers" 5 "Lower-income customers" 6 "Local customers" 7 "Can switch agents") ///
                size(small) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3c_2.png", as(png) replace

        *q_3c_3
        forval nmr = 1/5 {
                gen gr_3c_3_`nmr' = (q_3c_3 == `nmr')
                replace gr_3c_3_`nmr' = . if missing(q_3c_3)
        }

        set scheme jpalfull
        qui sum agents_n if q_3c_3 !=.

        graph bar gr_3c_3_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Has the customer feedback to the messages been positive or negative?", size(medsmall)) ///
                subtitle("(T2 & T3: Shrouding)", size(small)) ///
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(vsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3c_3.png", as(png) replace

        *# T4 TRANSPARENCY
        *q_3d
        forval nmr = 0/1 {
                gen gr_3d_`nmr' = (q_3d == `nmr')
                replace gr_3d_`nmr' = . if missing(q_3d)
        }       

        set scheme jpalfull
        qui sum agents_n if q_3d !=.

        graph bar gr_3d_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("would you say that these marketing messages have helped you increase your business?", size(medsmall)) ///
                subtitle("(T4: Transparency)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3d.png", as(png) replace

        *q_3d_1
        forval nmr = 1/5 {
                gen gr_3d_1_`nmr' = (q_3d_1 == `nmr')
                replace gr_3d_1_`nmr' = . if missing(q_3d_1)
        }

        set scheme jpalfull
        qui sum agents_n if q_3d_1 !=.

        graph bar gr_3d_1_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Has the customer feedback to the messages been positive or negative?", size(medsmall)) ///
                subtitle("(T4: Transparency)", size(small)) ///
                legend(order(1 "Very positive" 2 "Somewhat positive" 3 "Neither positive nor negative" 4 "Somewhat negative" 5 "Very negative") size(vsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3d_1.png", as(png) replace

        *q_3d_2
        forval nmr = 0/1 {
                gen gr_3d_2_`nmr' = (q_3d_2 == `nmr')
                replace gr_3d_2_`nmr' = . if missing(q_3d_2)
        }

        set scheme jpalfull
        qui sum agents_n if q_3d_2 !=.

        graph bar gr_3d_2_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Would you say that these marketing messages have helped you increase your business?", size(medsmall)) ///
                subtitle("(T4: Transparency)", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3d_2.png", as(png) replace

        *q_3f
        forval nmr = 0/1 {
                gen gr_3f_`nmr' = (q_3f == `nmr')
                replace gr_3f_`nmr' = . if missing(q_3f)
        }

        set scheme jpalfull
        qui sum agents_n if q_3f !=.

        graph bar gr_3f_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Would you say that these marketing messages advertising services and official prices", size(small)) ///
                subtitle("have helped you increase your business?", size(small)) ///
                legend(order(1 "No" 2 "Yes") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/3 - q_3f.png", as(png) replace


***# SECTION 4: Agent Effort and Business Strategy #***

        *q_4a
        forval nmr = 1/3 {
                gen gr_4a_`nmr' = (q_4a == `nmr')
                replace gr_4a_`nmr' = . if missing(q_4a)
        }

        set scheme jpalfull
        qui sum agents_n if q_4a !=.

        graph bar gr_4a_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Over the last month, how much time did you spend advertising ", size(small)) ///
                subtitle("your branchless banking services to increase your business?", size(small)) ///
                legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4a.png", as(png) replace

        *q_4b
        forval nmr = 1/6 {
                gen gr_4b_`nmr' = (q_4b == `nmr')
                replace gr_4b_`nmr' = . if missing(q_4b)
        }       

        set scheme jpalfull
        qui sum agents_n if q_4b !=.

        graph bar gr_4b_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Over the last month, how often have you approached customers", size(small)) ///
                subtitle("to encourage them to do more branchless banking transactions?", size(small)) ///
                legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4b.png", as(png) replace

        *q_4c
        forval y = 1/9 {
                gen q_4c_1_new_`y' = ///
                q_4c_1_1==`y' | ///
                q_4c_1_2==`y' | ///
                q_4c_1_3==`y'
        }

        set scheme jpalfull
        qui sum agents_n if q_4c_1_new_1 !=.

        graph bar q_4c_1_new_*, percentages ///
                ytitle("%", size(small)) ///
                ylabel(, labsize(small)) ///
                blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
                title("Type of client charge with low fees?", size(medsmall)) ///
                legend(order(1 "Reduced fees" 2 "Longer business hours" 3 "Offering credit option" 4 "Offering complementary services/products" ///
                         5 "Extra cash" 6 "Cleanliness" 7 "Better service" 8 "Create more trust" 9 "Proximity to customers") ///
                size(vsmall) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4c.png", as(png) replace

        *q_4d
        forval nmr = 1/6 {
                gen gr_4d_`nmr' = (q_4d == `nmr')
                replace gr_4d_`nmr' = . if missing(q_4d)
        }

        set scheme jpalfull
        qui sum agents_n if q_4d !=.

        graph bar gr_4d_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Over the last month, how often do you approached customers", size(small)) ///
                subtitle("with information about prices for BM transactions?", size(small)) ///
                legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4d.png", as(png) replace

        *q_4e
        forval nmr = 1/6 {
                gen gr_4e_`nmr' = (q_4e == `nmr')
                replace gr_4e_`nmr' = . if missing(q_4e)
        }

        set scheme jpalfull
        qui sum agents_n if q_4e !=.

        graph bar gr_4e_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Over the last month, how often do you approached new customers", size(small)) ///
                subtitle("to encourage them to adopt Bank Mandiri financial products?", size(small)) ///
                legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4e.png", as(png) replace

        *q_4f
        forval y = 1/9 {
                gen q_4f_1_new_`y' = ///
                q_4f_1_1==`y' | ///
                q_4f_1_2==`y' | ///
                q_4f_1_3==`y'
        }

        set scheme jpalfull
        qui sum agents_n if q_4f_1_new_1 !=.


        graph bar q_4f_1_new_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Over the last month, how often do you approached existing customers", size(small)) ///
                subtitle("to encourage them to do more transactions?", size(small)) ///
                legend(order(1 "Through family contacts" 2 "Strategic location and signage" 3 "Recommendations or referrals" 4 "Traveling to or calling potential customers" 5 "Advertising campaigns" 6 "Others") size(small) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_4f.png", as(png) replace

***# SECTION 5: Agent Profile #***

        *q_5a -- histogram of q_5a
        set scheme jpalfull
        destring q_5a, replace
        qui sum q_5a if q_5a !=.

        histogram q_5a, percent color(maroon*0.80) ///
                discrete ///
                xlabel(0(20)100) ///
                title("Since when you have been working as an agent for Bank Mandiri?", size(medsmall)) ///
                subtitle("", size(medsmall)) ///
                ytitle("Perc of agents", size(medsmall)) ///
                xtitle("Perc of total revenue", size(medsmall)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_5a_hist.png", as(png) replace

        *q_5a -- box plot of q_5a
        set scheme jpalfull
        su q_5a, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_5a,  box(1, fcolor(maroon*0.80) lcolor(maroon*0.80)) yline(`r(mean)', lpattern (.) lcolor(maroon*0.80)) ///
                title("Since when you have been working as an agent for Bank Mandiri?", size(medsmall)) ///
                ytitle("Perc of total revenue", size(medsmall)) ///
                text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
                text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_5a_boxplot.png", as(png) replace

        *q_5b
        forval nmr = 1/2 {
                gen gender_`nmr' = (gender == `nmr')
                replace gender_`nmr' = . if missing(gender)
        }       

        set scheme jpalfull
        qui sum agents_n if gender !=.

        graph bar gender_*, percentages /// 
                ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
                ylabel(0(25)100) ///
                blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
                title("Do you also work as an agent for other banks, besides Bank Mandiri?", size(medsmall)) ///
                subtitle("(Pure control and T1)", size(small)) ///
                legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_5b.png", as(png) replace

        *q_5c -- histogram of q_5c
        set scheme jpalfull
        destring q_5c, replace
        qui sum q_5c if q_5c !=.

        histogram q_5c, percent color(emerald*0.80) ///
                discrete ///
                xlabel(0(20)100) ///
                title("When were you were born?", size(medsmall)) ///
                subtitle("", size(medsmall)) ///
                ytitle("Perc of agents", size(medsmall)) ///
                xtitle("Perc of total revenue", size(medsmall)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_5c_hist.png", as(png) replace

        *q_5c -- box plot of q_5c
        set scheme jpalfull
        su q_5c, detail
        return list
        local mean_rounded = round(`r(mean)', 1)
        graph box q_5c,  box(1, fcolor(emerald*0.80) lcolor(emerald*0.80)) yline(`r(mean)', lpattern (.) lcolor(emerald*0.80)) ///
                title("When were you were born?", size(medsmall)) ///
                ytitle("Perc of agent banking revenue", size(medsmall)) ///
                text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
                text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
                text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
                text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
                note("Total agents = `: di %6.0fc `r(N)''", size(small))
        graph export "$output/04 agent_endline/Agent Endline - `date'/4 - q_5c_boxplot.png", as(png) replace
