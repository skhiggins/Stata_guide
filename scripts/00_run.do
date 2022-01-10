// Run script for example project

// BOILERPLATE ---------------------------------------------------------- 
// For nearly-fresh Stata session and reproducibility
set more off
set varabbrev off
clear all
macro drop _all
version 14.2

// DIRECTORIES ---------------------------------------------------------------
// To replicate on another computer simply uncomment the following lines
//  by removing // and change the path:
// global main "/path/to/replication/folder"

if "$main"=="" { // Note this will only be untrue if line above uncommented
                 // due to the `macro drop _all` in the boilerplate
    if "`c(username)'" == "John" { // John's Windows computer
        global main "C:/Dropbox/MyProject/analysis" // Ensure no spaces 
    }
    else if "`c(username)'" == "janedoe" { // Jane's Mac laptop 
        global main "/Users/janedoe/Dropbox/MyProject/analysis"
    }
    else { // display an error 
        display as error "User not recognized."
        display as error "Specify global main in 00_run.do."
        exit 198 // stop the code so the user sees the error
    }
}

// Also create globals for each subdirectory
local subdirectories ///
    data             ///
    documentation    ///
    logs             ///
    proc             ///
    results          ///
    scripts
foreach folder of local subdirectories {
    cap mkdir "$main/`folder'" // Create folder if it doesn't exist already
    global `folder' "$main/`folder'"
}
// Create results subfolders if they don't exist already
cap mkdir "$results/figures"
cap mkdir "$results/tables"

// The following code ensures that all user-written ado files needed for
//  the project are saved within the project directory, not elsewhere.
tokenize `"$S_ADO"', parse(";")
while `"`1'"' != "" {
    if `"`1'"'!="BASE" cap adopath - `"`1'"'
    macro shift
}
adopath ++ "$scripts/programs"

// PRELIMINARIES -------------------------------------------------------------
// Control which scripts run
local 01_ex_dataprep = 1
local 02_ex_reg      = 1
local 03_ex_table    = 1
local 04_ex_graph    = 1

// RUN SCRIPTS ---------------------------------------------------------------

// Read and clean example data
if (`01_ex_dataprep' == 1) do "$scripts/01_ex_dataprep.do"
// INPUTS
//  "$data/example.csv"
// OUTPUTS
//  "$proc/example.dta"

// Regress Y on X in example data
if (`02_ex_reg' == 1) do "$scripts/02_ex_reg.do"
// INPUTS
//  "$proc/example.dta" // 01_ex_dataprep.do
// OUTPUTS 
//  "$proc/ex_reg_results.dta" // results stored as a data set

// Create table of regression results
if (`03_ex_table' == 1) do "$scripts/03_ex_table.do"
// INPUTS 
//  "$proc/ex_reg_results.dta" // 02_ex_reg.do
// OUTPUTS
//  "$results/tables/ex_reg_table.tex" // tex of table for paper

// Create scatterplot of Y and X with local polynomial fit
if (`04_ex_graph' == 1) do "$scripts/04_ex_graph.do"
// INPUTS
//  "$proc/example.dta" // 01_ex_dataprep.R
// OUTPUTS
//  "$results/figures/ex_scatter.eps" # figure
