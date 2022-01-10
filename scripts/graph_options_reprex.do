// Simple example of using graph_options to standardize graph formatting
//  Sean Higgins

// Note: I recommend saving figures as .eps, but here I save as .png so that 
//  the figures are easier to view on GitHub.

// DATA ----------------------------------------------------------------------
sysuse "auto2.dta", clear

// ANALYSIS ------------------------------------------------------------------
// Use the defaults
graph_options

#delimit ;
graph twoway scatter mpg trunk, 
	title("Cars with more trunk space have worse mpg", `title_options')
	ytitle("Miles per gallon (mpg)", `ytitle_options')
    ylabel(, `ylabel_options') 
	xtitle("Trunk space (cubic inches)", `xtitle_options')
	xlabel(, `xlabel_options') 
	xscale(noline)
    yscale(noline)
    `marker_options'
	`plotregion' `graphregion'
	legend(off)
;
#delimit cr
graph export "results/figures/graph_options_defaults.png", ///
    width(2400) height(1600) replace
    // Normally you should use absolute paths with globals (eg "$results");
    //  For the purposes of this reproducible example I do not.

// Add x and y axes at 0, add more margin to the right of the graph
//  (useful for example if the x-axis numbers are a few digits each), 
//  and increase the size of the points.
graph_options, ///
    graph_margin(l=0 t=0 b=0 r=5) ///
    marker_size(medlarge)
#delimit ;
graph twoway scatter mpg trunk, 
	title("Cars with more trunk space have worse mpg", `title_options')
	ytitle("Miles per gallon (mpg)", `ytitle_options')
    ylabel(0(10)40, `ylabel_options') 
	xtitle("Trunk space (cubic feet)", `xtitle_options')
	xlabel(0(5)25, `xlabel_options') 
    yscale(noline range(0 .))
    yline(0, `manual_axis')
	xscale(noline range(0 .))
    xline(0, `manual_axis')
    `marker_options'
	`plotregion' `graphregion'
	legend(off)
;
#delimit cr
graph export "results/figures/graph_options_with_axes.png", ///
    width(2400) height(1600) replace
    // Normally you should use absolute paths with globals (eg "$results");
    //  For the purposes of this reproducible example I do not.
    
// Add colors and a legend
graph_options, legend_position(3) // legend on right rather than below
    // Note that 3 is the clock position; see help legend_options
// To get the labels for the legend, which are the values of rep78:
local legend_labels ""
local rep78_value_label `: value label rep78' 
summarize rep78, meanonly
forval status = `r(min)'/`r(max)' {
    local legend_labels `legend_labels' ///
        `status' "`: label `rep78_value_label' `status''"
}
#delimit ;
graph twoway 
    (scatter mpg trunk if rep78 == 1, mcolor("`cblind1'"))
    (scatter mpg trunk if rep78 == 2, mcolor("`cblind2'"))
    (scatter mpg trunk if rep78 == 3, mcolor("`cblind3'"))
    (scatter mpg trunk if rep78 == 4, mcolor("`cblind4'"))
    (scatter mpg trunk if rep78 == 5, mcolor("`cblind5'"))
  , 
	title("Cars with more trunk space have worse mpg", `title_options')
	ytitle("Miles per gallon (mpg)", `ytitle_options')
    ylabel(0(10)40, `ylabel_options') 
	xtitle("Trunk space (cubic feet)", `xtitle_options')
	xlabel(0(5)25, `xlabel_options') 
    yscale(noline range(0 .))
    yline(0, `manual_axis')
	xscale(noline range(0 .))
    xline(0, `manual_axis')
	`plotregion' `graphregion'
	legend(`legend_options' 
        title("Repair record", `legend_title_options')
        order(`legend_labels')
    )
;
#delimit cr
// Note: all the locals used above are defined by graph_options, including
//  the colorblind palette locals `cblind1' through `cblind9'.
graph export "results/figures/graph_options_with_colors.png", ///
    width(2400) height(1600) replace

// Histogram
#delimit ;
histogram trunk, width(1) frequency
    `bar_options'
	ytitle("Count", `ytitle_options')
    ylabel(, `ylabel_options') 
    yscale(noline)
    yline(0, `manual_axis') /* x-axis line at y=0 */
	xtitle("Trunk space (cubic feet)", `xtitle_options')
    xlabel(, `xlabel_options')
	xscale(noline) 
	`plotregion' `graphregion'
	legend(off)
;
#delimit cr
graph export "results/figures/graph_options_histogram.png", ///
    width(2400) height(1600) replace

