insheet using temp/binned_control.csv

twoway (scatter posterior_prior signal_prior, mcolor(navy) lcolor(maroon) msymbol(circle)) , graphregion(fcolor(white))  xtitle(signal_prior) ytitle(posterior_prior) legend(off order())
