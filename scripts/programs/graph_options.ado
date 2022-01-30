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
        marker_color(string)
        marker_symbol(string)
        marker_size(string)
        marker_options(string)
        bar_options(string)
        estimate_options_0(string)
        estimate_options_90(string)
        estimate_options_95(string)
        rcap_options_0(string)
        rcap_options_90(string)
        rcap_options_95(string)
        fit_options(string)
        legend_cols(string)
        legend_position(string)
        legend_margin(string)
        legend_title_options(string)
        legend_options(string)
    ];
    #delimit cr
    
    if "`scheme'"=="" set scheme s1color
    else set scheme `scheme'
    
    if "`labsize'"=="" local labsize medlarge
    if "`bigger_labsize'"=="" local bigger_labsize `labsize'
    if "`ylabel_options'"=="" local ylabel_options nogrid notick labsize(`labsize') angle(horizontal) format(`ylabel_format') labgap(`y_labgap')
    if "`ylabel_options_invis'"=="" local ylabel_options_invis `ylabel_options' labcolor(white)
    if "`xlabel_options'"=="" local xlabel_options nogrid notick labsize(`labsize') valuelabels format(`xlabel_format') angle(`x_angle') labgap(`x_labgap')
    if "`xlabel_options_invis'"=="" local xlabel_options_invis `xlabel_options' labcolor(white)
    if "`xtitle_options'"=="" local xtitle_options size(`labsize') color(black) margin(top) 
    if "`xtitle_options_invis'"=="" local xtitle_options_invis size(`labsize') color(white) margin(top)
    if "`ytitle_options'"=="" local ytitle_options size(`labsize') color(black)
    if "`ytitle_options_invis'"=="" local ytitle_options_invis size(`labsize') color(white)
    if "`title_options'"=="" local title_options size(`labsize') color(black) 
    if "`subtitle_options'"=="" local subtitle_options size(`labsize') color(black) margin(bottom) 
    if "`manual_axis'"=="" local manual_axis lwidth(thin) lcolor(black) lpattern(solid)
    if "`plot_margin'"=="" local plot_margin l=0 r=2 b=0 t=2
    if "`plotregion'"=="" local plotregion plotregion(margin(`plot_margin') fcolor(white) lstyle(none) lcolor(white)) 
    if "`graph_margin'"=="" local graph_margin zero
    if "`graphregion'"=="" local graphregion graphregion(margin(`graph_margin') fcolor(white) lstyle(none) lcolor(white)) 
    if "`T_line_options'"=="" local T_line_options lwidth(thin) lcolor(gray) lpattern(dash)
    if "`marker_color'" == "" local marker_color "black"
    if "`marker_symbol'" == "" local marker_symbol "O"
    if "`marker_size'" == "" local marker_size "medium"
    if "`marker_options'"=="" local marker_options mcolor(`marker_color') msymbol(`marker_symbol') msize(`marker_size')
    if "`bar_options'"=="" local bar_options lwidth(none) lcolor(gs7) fcolor(gs7)
    if "`estimate_options_0'"=="" local estimate_options_0  mcolor(gs7)   msymbol(Oh) msize(medlarge)
    if "`estimate_options_90'"=="" local estimate_options_90  mcolor(gs7)   msymbol(O)  msize(medlarge)
    if "`estimate_options_95'"=="" local estimate_options_95  mcolor(black) msymbol(O)  msize(medlarge)
    if "`rcap_options_0'"==""  local rcap_options_0   lcolor(gs7)   lwidth(thin)
    if "`rcap_options_90'"=="" local rcap_options_90  lcolor(gs7)   lwidth(thin)
    if "`rcap_options_95'"=="" local rcap_options_95  lcolor(black) lwidth(thin)
    if "`fit_options'"=="" local fit_options clwidth(medthick) clcolor(blue) fcolor(none) ///
        alcolor(blue*0.5) alpattern(dash) alwidth(thin)
    if "`legend_cols'"=="" local legend_cols 1
    if "`legend_position'"=="" local legend_position 6
    if "`legend_margin'"=="" local legend_margin zero
    if "`legend_title_options'"=="" local legend_title_options size(`labsize') color(black) margin(l=0 r=0 b=1 t=0) 
    if "`legend_options'"=="" local legend_options region(lwidth(none)) bmargin(`legend_margin') position(`legend_position') cols(`legend_cols') size(`labsize')
    
    c_local labsize `labsize'
    c_local bigger_labsize `bigger_labsize'
    // Axes
    c_local ylabel_options `ylabel_options'
    c_local ylabel_options_invis `ylabel_options_invis'
    c_local xlabel_options `xlabel_options'
    c_local xlabel_options_invis `xlabel_options_invis'
    c_local xtitle_options `xtitle_options'
    c_local xtitle_options_invis `xtitle_options_invis'
    c_local ytitle_options `ytitle_options'
    c_local ytitle_options_invis `ytitle_options_invis'
    // Titles
    c_local title_options `title_options'
    c_local subtitle_options `subtitle_options'
    // Misc
    c_local manual_axis `manual_axis'
    c_local plotregion `plotregion'
    c_local graphregion `graphregion'
    // To put a line right before treatment
    c_local T_line_options `T_line_options'
    // Bars
    c_local bar_options `bar_options'
    // General markers
    c_local marker_color `marker_color'
    c_local marker_symbol `marker_symbol'
    c_local marker_size `marker_size'
    c_local marker_options `marker_options'
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
    // Legend
    c_local legend_cols `legend_cols'
    c_local legend_position `legend_position'
    c_local legend_margin `legend_margin'
    c_local legend_title_options `legend_title_options'
    c_local legend_options `legend_options'
    // Colorblind colors
    c_local cblind1 "0 0 0" // Black
    c_local cblind2 "153 153 153" // Gray
    c_local cblind3 "230 159 0" // Orange
    c_local cblind4 "86 180 233" // Sky Blue
    c_local cblind5 "0 158 115" // bluish Green
    c_local cblind6 "240 228 66" // Yellow
    c_local cblind7 "0 114 178" // Blue
    c_local cblind8 "213 94 0" // Vermillion
    c_local cblind9 "204 121 167" // reddish Purple
end
