*===================================================*
* Benchtest - Agent Survey (Baseline)				*
* Purpose       : Balance checks					*
* Stata ver.    : 17                             	*
* Last modified : 23 December 2024					*
*===================================================*

clear 		all
capture: 	log close
set more off

/*** PATH SET-UP ***/

gl user = c(username)

*Set user
if "$user" == "Riko"{
	gl path "C:\Users\Riko\Dropbox\17 Large-Scale RCT"
	}


*Set folder path
		gl do			"$path\dofiles"
		gl dta			"$path\dtafiles"
		gl output		"$path\output"

loc date : di %tdDNCY daily("$S_DATE", "DMY")
shell mkdir "$output\\[Balance check] Agent Baseline (Benchtest) - `date'"

*Import data (adjust the DTA based on the latest data)
use "$dta\cleaned_baseline_agent_survey_09122024", clear

********************************************************************************
//# 1. Short cleaning (setup the variables)
** Only keep completed responses and agree to participate in the survey
keep if finished == 1
keep if informed_consent == 1

** Generate treatment status (pooled)
gen treatment_pooled = 1 if inlist(treatment_status, 1, 2, 3, 4)
replace treatment_pooled = 0 if treatment_status == 0
order treatment_pooled, after(treatment_status)

la def treatment_pooled 1 "Treatment" 0 "Control"
la val treatment_pooled treatment_pooled

** Convert YYYY to a numerical value (current year is 2024)
gen year_agent = 2024 - q_10a_1
order year_agent, after(q_10a_1)

gen year_age = 2024 - birthyear
order year_age, after(birthyear)

** Convert the values of single-answer categorical questions with 2 options to 0 if the val == 2
foreach var of varlist q_4a q_4b {
	replace `var' = 0 if `var' == 2
}

** Create a dummy for each category of responses (in single-answer categorical questions, with >2 options)
loc var_list q_2a_1 q_2a_2 q_2a_3 q_2a_4 q_2a_5 q_2a_6 q_2a_7 q_2a_8 q_2a_9 q_2a_10 q_3a q_3c q_9b q_9c q_9g q_9h q_9i q_9j

	foreach var of loc var_list {
		su `var', meanonly
		loc n_categories = r(max)

		* Loop through each category and create a dummy
		forval i = 1/`n_categories' {
		    * Create a new dummy variable for the i-th category
		    gen `var'_`i'_dummy = `var' == `i'
		}
	}

//# 2. Shorten Variable Labels for the Balance Table
la var year_age						"Age"
la var gender						"Female (\%)"

** Section 1
la var q_1a							"Agents follow the official fees (\%)"
la var q_1b							"Agents equally charge all clients (\%)"
la var q_1b_1						"Agents have specific cust types to charge the lowest fees (\%)"

la var q_1b_1_a						"\hspace{20pt} Friends and family (\%)"
la var q_1b_1_b						"\hspace{20pt} High-value customer (\%)"
la var q_1b_1_c						"\hspace{20pt} New customer (\%)"
la var q_1b_1_d						"\hspace{20pt} Long-time customer (\%)"
la var q_1b_1_e						"\hspace{20pt} Poorer customer (\%)"
la var q_1b_1_f						"\hspace{20pt} Customer from local area (\%)"
la var q_1b_1_g						"\hspace{20pt} Easy to switch to other agents (\%)"

la var q_1c							"Most clients know the fees well (\%)"

** Section 2
forval cat = 1/10 {
	la var q_2a_`cat'_1_dummy "\hspace{40pt} Not important at all (\%)"
	la var q_2a_`cat'_2_dummy "\hspace{40pt} Not very important (\%)"
	la var q_2a_`cat'_3_dummy "\hspace{40pt} Important (\%)"
	la var q_2a_`cat'_4_dummy "\hspace{40pt} Very important (\%)"
}

** Section 3
la var q_3a_1_dummy					"\hspace{20pt} Indifferent (\%)"
la var q_3a_2_dummy					"\hspace{20pt} Unfair, switch to other agents (\%)"
la var q_3a_3_dummy					"\hspace{20pt} Unfair, stay loyal (\%)"
la var q_3a_4_dummy					"\hspace{20pt} Fair (\%)"

la var q_3b							"Estimated revenue reduced: Scenarios as above (\%)"

la var q_3c_1_dummy					"\hspace{20pt} Indifferent (\%)"
la var q_3c_2_dummy					"\hspace{20pt} Unfair, switch to other agents (\%)"
la var q_3c_3_dummy					"\hspace{20pt} Unfair, stay loyal (\%)"
la var q_3c_4_dummy					"\hspace{20pt} Fair (\%)"

la var q_3d							"Estimated revenue reduced: Scenarios as above (\%)"
la var q_3e							"Estimated revenue reduced: Scenarios as above (\%)"

** Section 4
la var q_4a							"Many number of agents to choose (\%)"
la var q_4b							"Clients prefer to stay even if other agents offer lower prices (\%)"
la var q_4c							"Estimated revenue reduced: Scenarios as above (\%)"
la var q_4d							"Prior: Estimated change in the number of agents (\%)"

** Posterior Beliefs
la var q_6							"Posterior: Estimated change in the number of agents (\%)"

** Section 7
la var q_7a							"Send the marketing campaign to the agent (\%)"

** Section 8
la var q_8a							"Agents share of revenues from branchless banking business (\%)"
la var q_8b							"Agents also work for other banks besides BM (\%)"
la var q_8b_1						"Agents share of revenues from BM business (\%)"

** Section 9
la var q_9a							"Number of branchless banking agents in the area"

la var q_9b_1_dummy					"\hspace{20pt} High (\%)"
la var q_9b_2_dummy					"\hspace{20pt} Neither high nor low  (\%)"
la var q_9b_3_dummy					"\hspace{20pt} Low (\%)"

la var q_9c_1_dummy					"\hspace{20pt} Easy (\%)"
la var q_9c_2_dummy					"\hspace{20pt} Neither easy nor difficult (\%)"
la var q_9c_3_dummy					"\hspace{20pt} Difficult (\%)"

la var q_9d							"Agents display BM's price list in their shop (\%)"

foreach a in q_9e q_9f {
	la var `a'_1					"\hspace{20pt} Reduced fees charged per transaction (\%)"
	la var `a'_2					"\hspace{20pt} Longer business hours (\%)"
	la var `a'_3					"\hspace{20pt} Offer to buy on credit (\%)"
	la var `a'_4					"\hspace{20pt} Offer complementary services/products (\%)"
	la var `a'_5					"\hspace{20pt} Having extra cash in hand (\%)"
	la var `a'_6					"\hspace{20pt} Cleanliness premises (\%)"
	la var `a'_7					"\hspace{20pt} Better customer service (\%)"
	la var `a'_8					"\hspace{20pt} Create more trust (\%)"
	la var `a'_9					"\hspace{20pt} Proximity to customers (\%)"
}

la var q_9g_1_dummy					"\hspace{20pt} None at all (\%)"
la var q_9g_2_dummy					"\hspace{20pt} Some time (\%)"
la var q_9g_3_dummy					"\hspace{20pt} A lot of time (\%)"

foreach b in q_9h q_9i q_9j {
	la var `b'_1_dummy				"\hspace{20pt} Every day (\%)"
	la var `b'_2_dummy				"\hspace{20pt} A few times a week (\%)"
	la var `b'_3_dummy				"\hspace{20pt} Once a week (\%)"
	la var `b'_4_dummy				"\hspace{20pt} A few times per month (\%)"
	la var `b'_5_dummy				"\hspace{20pt} Once a month (\%)"
	la var `b'_6_dummy				"\hspace{20pt} Not at all (\%)"
}

** Section 10
la var year_agent					"Year(s) of being an agent"

//# 3. Create Balance Table
//# Table 1. Whole Section 1

	* Set locals for panels
	loc panel1	=	"year_age gender"
	loc panel2	=	"q_1a q_1b q_1b_1"
	loc panel3	=	"q_1b_1_a q_1b_1_b q_1b_1_c q_1b_1_d q_1b_1_e q_1b_1_f q_1b_1_g q_1c"
	
	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_1.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_1.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 panel3 {

		if "`tabnum'" == "panel2" file write sumstat _n "{\textbf{SECTION 1. TRANSACTION FEES}} \\ [1.0ex]" // The [1.0ex] specifies additional vertical space
		
		if "`tabnum'" == "panel3" file write sumstat _n "{Types of customers which agent charge the lowest fees} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 2-4. Looped for Section 2

	* Set locals for panels
	loc panel1	=	"q_2a_1_1_dummy q_2a_1_2_dummy q_2a_1_3_dummy q_2a_1_4_dummy"
	loc panel2	=	"q_2a_2_1_dummy q_2a_2_2_dummy q_2a_2_3_dummy q_2a_2_4_dummy"
	loc panel3  =   "q_2a_3_1_dummy q_2a_3_2_dummy q_2a_3_3_dummy q_2a_3_4_dummy"
	
	loc panel4	=	"q_2a_4_1_dummy q_2a_4_2_dummy q_2a_4_3_dummy q_2a_4_4_dummy"
	loc panel5	=	"q_2a_5_1_dummy q_2a_5_2_dummy q_2a_5_3_dummy q_2a_5_4_dummy"
	loc panel6  =   "q_2a_6_1_dummy q_2a_6_2_dummy q_2a_6_3_dummy q_2a_6_4_dummy"
	
	loc panel7  =   "q_2a_7_1_dummy q_2a_7_2_dummy q_2a_7_3_dummy q_2a_7_4_dummy"
	loc panel8  =   "q_2a_8_1_dummy q_2a_8_2_dummy q_2a_8_3_dummy q_2a_8_4_dummy"
	loc panel9  =   "q_2a_9_1_dummy q_2a_9_2_dummy q_2a_9_3_dummy q_2a_9_4_dummy"
	
	loc a = 1
	loc b = 2
	loc c = 3
	
	* Loop to create 3 tables for option 1-3, 4-6, and 7-9 of q_2a
	forval z = 2/4 {
		
	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_`z'.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_`z'.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel`a' panel`b' panel`c' {
		** Table 2: Option 1-3
			if "`tabnum'" == "panel1" file write sumstat _n "{\textbf{SECTION 2. CLIENT PREFERENCES}} \\ [1.0ex]"
			if "`tabnum'" == "panel1" file write sumstat _n "{Important characteristics to be a regular customer of an agent} \\ [1.0ex]"
			if "`tabnum'" == "panel1" file write sumstat _n "{\hspace{20pt} 1. Client has been a prior customer} \\ [1.0ex]"
			if "`tabnum'" == "panel2" file write sumstat _n "{\hspace{20pt} 2. Agent can clearly answer customers' questions} \\ [1.0ex]"
			if "`tabnum'" == "panel3" file write sumstat _n "{\hspace{20pt} 3. Agent is within a close proximity} \\ [1.0ex]"
			
		** Table 3: Option 4-6
			if "`tabnum'" == "panel4" file write sumstat _n "{\hspace{20pt} 4. Agent has sufficient cash to perform transactions} \\ [1.0ex]"
			if "`tabnum'" == "panel5" file write sumstat _n "{\hspace{20pt} 5. Agent is transparent and displays official fees} \\ [1.0ex]"
			if "`tabnum'" == "panel6" file write sumstat _n "{\hspace{20pt} 6. Agent is available every time needed} \\ [1.0ex]"
		
		** Table 4: Option 7-9
			if "`tabnum'" == "panel7" file write sumstat _n "{\hspace{20pt} 7. Agent offers the lowest fee} \\ [1.0ex]"
			if "`tabnum'" == "panel8" file write sumstat _n "{\hspace{20pt} 8. Agent is affiliated with the bank to open acc} \\ [1.0ex]"
			if "`tabnum'" == "panel9" file write sumstat _n "{\hspace{20pt} 9. Client trust the agent} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}
 

	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
	loc a = `a' + 3
	loc b = `b' + 3
	loc c = `c' + 3
}

//# Table 5. Section 2 (option 10) and Section 3 (3a - 3d)

	* Set locals for panels
	loc panel1	=	"q_2a_10_1_dummy q_2a_10_2_dummy q_2a_10_3_dummy q_2a_10_4_dummy"
	loc panel2	=	"q_3a_1_dummy q_3a_2_dummy q_3a_3_dummy q_3a_4_dummy q_3b"
	loc panel3  =   "q_3c_1_dummy q_3c_2_dummy q_3c_3_dummy q_3c_4_dummy q_3d"
	
	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_5.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_5.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 panel3 {

		if "`tabnum'" == "panel1" file write sumstat _n "{\hspace{20pt} 10. Agent charges everyone the same prices} \\ [1.0ex]"
	
		if "`tabnum'" == "panel2" file write sumstat _n "{\textbf{SECTION 3. CLIENT PERCEPTIONS ON FAIRNESS}} \\ [1.0ex]"
		if "`tabnum'" == "panel2" file write sumstat _n "{Agent charged 50\% higher than official fee} \\ [1.0ex]"
		
		if "`tabnum'" == "panel3" file write sumstat _n "{Agent charged 50\% higher than another customer} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 6. Section 3 (3e), Section 4, Section 8, Section 9 (9a 9b)

	* Set locals for panels
	loc panel1	=	"q_3e"
	
	loc panel2	=	"q_4a q_4b"
	loc panel3  =   "q_4c q_4d"
	
	loc panel4  =   "q_8a q_8b q_8b_1"
	
	loc panel5  =   "q_9a"
	loc panel6  =   "q_9b_1_dummy q_9b_2_dummy q_9b_3_dummy"
	
	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_6.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_6.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 panel3 panel4 panel5 panel6 {

		if "`tabnum'" == "panel1" file write sumstat _n "{Withdrawal fee increases from IDR3,000 to IDR4,500} \\ [1.0ex]"
	
		if "`tabnum'" == "panel2" file write sumstat _n "{\textbf{SECTION 4. COMPETITION STRATEGY}} \\ [1.0ex]"
		if "`tabnum'" == "panel3" file write sumstat _n "{New agent charges 50\% cheaper} \\ [1.0ex]"
		
		if "`tabnum'" == "panel4" file write sumstat _n "{\textbf{SECTION 8. BRANCHLESS BANKING BUSINESS}} \\ [1.0ex]"
		
		if "`tabnum'" == "panel5" file write sumstat _n "{\textbf{SECTION 9. MARKET CONDITIONS}} \\ [1.0ex]"
		if "`tabnum'" == "panel6" file write sumstat _n "{The current level of competition with other agent} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 7. Section 9 (9c - 9e)

	* Set locals for panels
	loc panel1	=	"q_9c_1_dummy q_9c_2_dummy q_9c_3_dummy q_9d"
	loc panel2	=	"q_9e_1 q_9e_2 q_9e_3 q_9e_4 q_9e_5 q_9e_6 q_9e_7 q_9e_8 q_9e_9"

	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_7.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_7.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 {

		if "`tabnum'" == "panel1" file write sumstat _n "{Easiness level to attract new customers} \\ [1.0ex]"
		if "`tabnum'" == "panel2" file write sumstat _n "{Expected new competitor's main strategy to attract cust} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 8. Section 9 (9f 9g)

	* Set locals for panels
	loc panel1	=	"q_9f_1 q_9f_2 q_9f_3 q_9f_4 q_9f_5 q_9f_6 q_9f_7 q_9f_8 q_9f_9"
	loc panel2	=	"q_9g_1_dummy q_9g_2_dummy q_9g_3_dummy"

	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_8.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_8.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 {

		if "`tabnum'" == "panel1" file write sumstat _n "{Agent strategies to increase business} \\ [1.0ex]"
		if "`tabnum'" == "panel2" file write sumstat _n "{Time spent to advertise agent services} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 9. Section 9 (9h 9i)

	* Set locals for panels
	loc panel1	=	"q_9h_1_dummy q_9h_2_dummy q_9h_3_dummy q_9h_4_dummy q_9h_5_dummy q_9h_6_dummy"
	loc panel2	=	"q_9i_1_dummy q_9i_2_dummy q_9i_3_dummy q_9i_4_dummy q_9i_5_dummy q_9i_6_dummy"

	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_9.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_9.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 {

		if "`tabnum'" == "panel1" file write sumstat _n "{Approach cust freq to do more transactions} \\ [1.0ex]"
		if "`tabnum'" == "panel2" file write sumstat _n "{Approach cust freq to adopt new BM financial products} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file
	
//# Table 10. Section 9 (9j) & Section 10 (year_agent)

	* Set locals for panels
	loc panel1	=	"q_9j_1_dummy q_9j_2_dummy q_9j_3_dummy q_9j_4_dummy q_9j_5_dummy q_9j_6_dummy"
	loc panel2  =   "year_agent"

	* Create a tex file
	cap erase "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_10.tex"
	cap file close sumstat
	file open sumstat using "$output\\[Balance check] Agent Baseline (Benchtest) - `date'\agent_table_balance_10.tex", write replace
	
	*Create a tabulat environment in the tex file
	file write sumstat _n "\begin{table}[H]\centering"  
	file write sumstat _n "\caption{\text{Balance Table}}" // Put a title for the table
	file write sumstat _n "\begin{tabular}{l*{15}{c}}" // Create a 16-column table, with 1 left-aligned column and 15 center-aligned columns
	
	*Draw a line at the top of the table
	file write sumstat _n "\toprule"
	
	*Create table headers
	file write sumstat _n " & \multicolumn{15}{c}{Baseline} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16} \cmidrule(lr){2-16}"
	file write sumstat _n " & \multicolumn{2}{c}{Full Sample} & \multicolumn{2}{c}{Control} & \multicolumn{2}{c}{Treatment (Pooled)} & \multicolumn{2}{c}{T1} & \multicolumn{2}{c}{T2} & \multicolumn{2}{c}{T3} & \multicolumn{2}{c}{T4} & \multicolumn{1}{c}{Difference} \\" _n
	file write sumstat _n "\cmidrule(lr){2-16}"
	file write sumstat _n " & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & N & Mean(std) & (C - T Pooled) \\" _n
	file write sumstat _n "\midrule"

	foreach tabnum in panel1 panel2 {

		if "`tabnum'" == "panel1" file write sumstat _n "{Approach cust freq to inform prices for BM transactions} \\ [1.0ex]"
		if "`tabnum'" == "panel2" file write sumstat _n "{\textbf{SECTION 10. AGENT PROFILE}} \\ [1.0ex]"
	         
	    foreach var of local `tabnum' {
	        local varlab: variable label `var'

	        quietly summarize `var'                      		   // Obtain summary stats for the full sample
	        local col1 = string(r(N),"%15.0fc")					   // Store the N of obs, as a string rounded to 2 decimal places
	        local col2 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col3 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
	      
	        quietly summarize `var' if treatment_pooled == 0       // Obtain summary stats for the control group
	        local col4 = string(r(N),"%15.0fc")  			  	   // Store the N of obs, as a string rounded to 2 decimal places
	        local col5 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col6 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places

	        quietly summarize `var' if treatment_pooled == 1       // Obtain summary stats for the treatment group (pooled)
	        local col7 = string(r(N),"%15.0fc")        			   // Store the N of obs, as a string rounded to 2 decimal places
	        local col8 = string(round(r(mean), 0.01), "%9.2f")     // Store the mean value as a string, rounded to 2 decimal places
	        local col9 = string(round(r(sd), 0.01), "%9.2f")       // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 1       // Obtain summary stats for T1
	        local col10 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col11 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col12 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 2       // Obtain summary stats for T2
	        local col13 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col14 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col15 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 3       // Obtain summary stats for T3
	        local col16 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col17 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col18 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places
			
	        quietly summarize `var' if treatment_status == 4       // Obtain summary stats for T4
	        local col19 = string(r(N),"%15.0fc")        		   // Store the N of obs, as a string rounded to 2 decimal places
	        local col20 = string(round(r(mean), 0.01), "%9.2f")    // Store the mean value as a string, rounded to 2 decimal places
	        local col21 = string(round(r(sd), 0.01), "%9.2f")      // Store the sd value as a string, rounded to 2 decimal places

	        quietly ttest `var', by(treatment_pooled)
	        quietly return list
	        local col22 = string(round(r(mu_1) - r(mu_2), 0.01), "%9.2f") 
	        local col23 = string(round(r(sd), 0.01), "%9.2f") 

	        local pvalue = string(round(r(p), 0.01), "%9.2f")      // Store the difference as a string, formatted to 2 decimal places
			local stars = ""
			if `pvalue' < 0.01 {
			    local stars = "***"
			} 
			else if `pvalue' < 0.05 {
			    local stars = "**"
			} 
			else if `pvalue' < 0.1 {
			    local stars = "*"
			} 

	        file write sumstat " `varlab' \hspace{20pt} & `col1' & `col2' & `col4' & `col5' & `col7' & `col8' & `col10' & `col1' & `col13' & `col14' & `col16' & `col17' & `col19' & `col20' & `col22'`stars' \\" _n
	        file write sumstat " & & (`col3') & & (`col6') & & (`col9') & & (`col12') & & (`col15') & & (`col18') & & (`col21') & (`col23') & \\ [1.0ex]" _n
	    }
	}


	*Draw a line to make a separate section
	file write sumstat _n "\hline"

	*Draw a line at the bottom of the table
	file write sumstat _n "\bottomrule"


	*Signal the end of a table environment in the tex file
	file write sumstat _n "\end{tabular}"   

	file write sumstat _n "\end{table}"  				// Signal the end of a table environment in the tex file
	file close sumstat 									// Close the tex file