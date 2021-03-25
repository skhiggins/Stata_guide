# Stata Guide

This guide provides instructions for using Stata on research projects. Its purpose is to use with collaborators and research assistants to make code consistent, easier to read, transparent, and reproducible.


## Style
[The DIME Analytics Data Handbook](https://worldbank.github.io/dime-data-handbook/#download-the-book-in-pdf-format) from the World Bank is an excellent resource for standardization of Stata code (see pages 131 to 146). This a good resources for commenting, whether to abbreviate commands, indendation and more. 

	* Unfortunately, I am not aware of any Stata packages like `styler:style_file()` in R. 

## Packages 
Most Stata packages are hosted on Boston College Statistical Software Components (SSC) archive. It easy to download packages from SSC; simply write `ssc install package` where `package` refers to the package you want to install. 

* Use `reghdfe` for fixed effects regressions
* Use `ftools` and `gtools` for working with large datasets 
* Use `randtreat` for randomization
* There is no package equivalent to the `here()` package in R, but we can use global macros so that our file paths are all relative to global paths. Example below and in the World Bank DIME Handbook: 
```
global project_dir = "C:/User/username/Project_Example"
use "$project_dir/proc/processed.dta" , clear
```

## Folder structure
Generally, within the folder where we are doing data analysis (the project's "root folder"), we have the following files and folders.


  * data - only raw data go in this folder
  * documentation - documentation about the data go in this folder
  * proc - processed data sets go in this folder
  * results - results go in this folder
    * figures - subfolder for figures
    * tables - subfolder for tables
  * scripts - code goes in this folder
    * Number scripts in the order in which they should be run
    * programs - a subfolder containing functions called by the analysis scripts. All user-written ado files should be contained in this directory.
    * old - a subfolder where old scripts from previous versions are stored if there are major changes to the structure of the project for cleanliness

## Scripts structure
Because we often work with large data sets and efficiency is important, I advocate (nearly) always separating the following three actions into different scripts:

  1. Data preparation (cleaning and wrangling)
  2. Analysis (e.g. regressions)
  3. Production of figures and tables
  
The analysis and figure/table scripts should not change the data sets at all (no pivoting from wide to long or adding new variables); all changes to the data should be made in the data cleaning scripts. The figure/table scripts should not run the regressions or perform other analysis; that should be done in the analysis scripts. This way, if you need to add a robustness check, you don't necessarily have to rerun all the data cleaning code (unless the robustness check requires defining a new variable). If you need to make a formatting change to a figure, you don't have to rerun all the analysis code (which can take awhile to run on large data sets).


## Graphing
  * Sean wrote an .ado file called graph_options.ado to control the formatting of graphs in stata 
    * To use this, simply write, for example: `scatter price mpg graph_options()`. The default market color is green, but you can change it manually like a normal graphing object by specifying: `scatter price mpg graph_options(), mcolor(pink)`. 
  * For reproducible graphs, always use `ysize(#)` and `xsize(#)` when exporting graphs
  * Use `spmap` for creating maps and plotting spatial data

## Saving files

#### Datasets
  * Use the Stata commands `save file.dta` and `use file.dta` when saving and reading in data 
    * To write over a file that already exists, use the `replace` option
    * To clear out memory when reading in a dataset, use the `clear` option
  
  * When dealing with large datasets, there are a couple of things that can make your life easier:
    * Stata reads faster from its native format
    * you can read only a select number of observations or variables
      * `use [varlist] [if] [in] using filename [,clear nolabel]`
      
#### Graphs
 * Save graphs with `graph export mygraph.eps, repalce`.
    * Set graph width and height dimensions in pixes with width and height options (i.e width(600)  height(400))
      
## Randomization
When randomizing assignment in a randomized control trial (RCT):
* Seed: Use a seed from https://www.random.org/: put Min 1 and Max 100000000, then click Generate, and copy the result into your script. Towards the top of the script, assign the seed with the line
`set seed ... # from random.org`
* Set Stata version: this ensures that the randomization algorithm is the same, since the randomization algorithm sometimes changes between Stata versions. See [`ieboilstart`](https://dimewiki.worldbank.org/wiki/Ieboilstart) for boilerplate code that standardizes Stata version within do files.

* Use `randtreat` for randomization 
  * You can install the most up to date version of the program directly from github: `net install randtreat, from("https://raw.github.com/acarril/randtreat/master/") replace`
  
Above I described how data preparation scripts should be separate from analysis scripts. Randomization scripts should also be separate from data preparation scripts, i.e. any data preparation needed as an input to the randomization should be done in one script and the randomization script itself should read in the input data, create a variable with random assignments, and save a data set with the random assignments.


## Running scripts
 * To run all the commands in a do file sequentially in Stata, click the “Do” button in the top-right corner
 * To run some but not all commands in a do file, highlight the commands that you would like to run and then press the “Do” button


## Reproducibility
  * Start your do files by opening a log file; this records all commands and output in a session and can be helpful to look back on the work for a particular project
    * Open a log file with `log using filename, text replace` and close a log file at the end of your session with `log close`
    
  * All user written ado files should be kept in the scripts/programs/ folder.