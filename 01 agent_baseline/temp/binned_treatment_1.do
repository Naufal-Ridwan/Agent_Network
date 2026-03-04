insheet using temp/binned_treatment_1.csv

twoway (scatter posterior_prior signal_prior, mcolor(navy) lcolor(maroon) msymbol(circle)) , graphregion(fcolor(white))  xtitle(signal_prior) ytitle(posterior_prior) legend(off order())
