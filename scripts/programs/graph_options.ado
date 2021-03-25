cap program drop graph_options
program define graph_options
	#delimit ;
	syntax [,
		scheme(string)
		labsize(string)
		bigger_labsize(string)
		ylabel_format(string)
		y_labgap(string)
		ylabel_options(string)
		ylabel_options_invis(string)
		xlabel_format(string)
		x_labgap(string)
		x_angle(string)
		xlabel_options(string)
		xlabel_options_invis(string)
		xtitle_options(string)
		xtitle_options_invis(string)
		ytitle_options(string)
		ytitle_options_invis(string)
		title_options(string)
		subtitle_options(string)
		manual_axis(string)
		plot_margin(string)
		plotregion(string)
		graph_margin(string)
		graphregion(string)
		T_line_options(string)
		estimate_options_0(string)
		estimate_options_90(string)
		estimate_options_95(string)
		rcap_options_0(string)
		rcap_options_90(string)
		rcap_options_95(string)
		fit_options(string)
	];
	#delimit cr
	
	if "`scheme'"=="" set scheme s1color
	else set scheme `scheme'
	
	if "`labsize'"=="" local labsize medlarge
	if "`bigger_labsize'"=="" local bigger_labsize `labsize'
	if "`ylabel_options'"=="" local ylabel_options nogrid notick labsize(`labsize') angle(horizontal) `ylabel_format' `y_labgap'
	if "`ylabel_options_invis'"=="" local ylabel_options_invis `ylabel_options' labcolor(white)
	if "`xlabel_options'"=="" local xlabel_options nogrid notick labsize(`labsize') valuelabels `xlabel_format' `x_angle' `x_labgap'
	if "`xlabel_options_invis'"=="" local xlabel_options_invis `xlabel_options' labcolor(white)
	if "`xtitle_options'"=="" local xtitle_options size(`labsize') color(black) margin(top) 
	if "`xtitle_options_invis'"=="" local xtitle_options_invis size(`labsize') color(white)	margin(top)
	if "`ytitle_options'"=="" local ytitle_options size(`labsize') color(black)
	if "`ytitle_options_invis'"=="" local ytitle_options_invis size(`labsize') color(white)
	if "`title_options'"=="" local title_options size(`labsize') color(black) 
	if "`subtitle_options'"=="" local subtitle_options size(`labsize') color(black) margin(bottom) 
	if "`manual_axis'"=="" local manual_axis lwidth(thin) lcolor(black) lpattern(solid)
	if "`plot_margin'"=="" local plot_margin margin(zero)
	if "`plotregion'"=="" local plotregion plotregion(`plot_margin' fcolor(white) lstyle(none) lcolor(white)) 
	if "`graph_margin'"=="" local graph_margin margin(zero)
	if "`graphregion'"=="" local graphregion graphregion(`graph_margin' fcolor(white) lstyle(none) lcolor(white)) 
	if "`T_line_options'"=="" local T_line_options lwidth(thin) lcolor(gray) lpattern(dash)
	if "`estimate_options_0'"=="" local estimate_options_0  mcolor(gs7)   msymbol(Oh) msize(medlarge)
	if "`estimate_options_90'"=="" local estimate_options_90  mcolor(gs7)   msymbol(O)  msize(medlarge)
	if "`estimate_options_95'"=="" local estimate_options_95  mcolor(black) msymbol(O)  msize(medlarge)
	if "`rcap_options_0'"==""  local rcap_options_0   lcolor(gs7)   lwidth(thin)
	if "`rcap_options_90'"=="" local rcap_options_90  lcolor(gs7)   lwidth(thin)
	if "`rcap_options_95'"=="" local rcap_options_95  lcolor(black) lwidth(thin)
	if "`fit_options'"=="" local fit_options clwidth(medthick) clcolor(blue) fcolor(none) ///
		alcolor(blue*0.5) alpattern(dash) alwidth(thin)
	
	c_local labsize `labsize'
	c_local bigger_labsize `bigger_labsize'
	c_local ylabel_options `ylabel_options'
	c_local ylabel_options_invis `ylabel_options_invis'
	c_local xlabel_options `xlabel_options'
	c_local xlabel_options_invis `xlabel_options_invis'
	c_local xtitle_options `xtitle_options'
	c_local xtitle_options_invis `xtitle_options_invis'
	c_local ytitle_options `ytitle_options'
	c_local ytitle_options_invis `ytitle_options_invis'
	c_local title_options `title_options'
	c_local subtitle_options `subtitle_options'
	c_local manual_axis `manual_axis'
	c_local plotregion `plotregion'
	c_local graphregion `graphregion'
	// To put a line right before treatment
	c_local T_line_options `T_line_options'
	// To show significance: hollow gray (gs7) will be insignificant from 0,
	//  filled-in gray significant at 10%
	//  filled-in black significant at 5%
	c_local estimate_options_0  `estimate_options_0'
	c_local estimate_options_90 `estimate_options_90'
	c_local estimate_options_95 `estimate_options_95'
	c_local rcap_options_0  `rcap_options_0'
	c_local rcap_options_90 `rcap_options_90'
	c_local rcap_options_95 `rcap_options_95'
	// Fit line
	c_local fit_options `fit_options'
end
