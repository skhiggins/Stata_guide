# Stata Guide

This guide provides instructions for using Stata on research projects. Its purpose is to use with collaborators and research assistants to make code consistent, easier to read, transparent, and reproducible.

## Style
For coding style practices, follow the [DIME Analytics Coding Guide](  https://worldbank.github.io/dime-data-handbook/coding.html). There are a few places where I recommend deviating from this style guide:

* Use the boilerplate described below in the `00_run.do` script to ensure a fresh Stata session when running scripts, rather than using [`ieboilstart`](https://github.com/worldbank/ietoolkit/blob/master/src/ado_files/ieboilstart.ado).
* `#delimit ;` can be used when there is code that takes up many lines, such as a long local macro where it is preferable to list each element of the list vertically rather than horizontally since this is easier to read. However, this should only be used for the code that takes up many lines, and immediately afterwards `#delimit cr` should be included to go back to not needing to include `;` at the end of each line.
* Use `//` for both single-line comments and in-line comments. Using the same characters for both types of comments more closely matches what other statistical programming languages do (e.g. `#` for both types of comments in R and Python), and it ensures that various text editors' syntax highlighting can identify comments. (The problem with using `*` for single-line comments is that `*` is also used for multiplication and this can confuse some text editors' syntax highlighting.)

## Packages 
Most user-written Stata packages are hosted on Boston College Statistical Software Components (SSC) archive. It easy to download packages from SSC; simply run `ssc install package` where `package` should be replaced with the name of the package you want to install. 

* Use `reghdfe` for fixed effects regressions
* Use `ftools` and `gtools` for working with large datasets 
* Use `randtreat` for randomization
* When generating tables with multiple panels, `regsave` and `texsave` are recommended. 

## Folder structure

Generally, within a project folder, we have a subfolder called `analysis` where we are doing data analysis (and other sub-folders like `paper` where the paper draft is saved). Within the `analysis` subfolder, we have: 
  * data - only raw data go in this folder
  * documentation - documentation about the data go in this folder
    * logs - log files go in this folder
    * proc - processed data sets go in this folder
  * results - results go in this folder
    * figures - subfolder for figures
    * tables - subfolder for tables
  * scripts - code goes in this folder. The scripts needed to go from raw data to final results are stored directly in the scripts folder.
    * programs - a subfolder containing functions called by the analysis scripts. All user-written ado files should be contained in this directory.
    * old - a subfolder where old scripts are stored if there are major changes to the structure of the project. Scripts in the old subfolder are not used to go from raw data to final results, but are kept here while the project is ongoing in case they need to be used or referred back to in the future. The old subfolder is not included in the replication package since the scripts in this subfolder are not part of the process of going from raw data to final results.
        
## Filepaths
* Use forward slashes for filepath names (`$results/tables` not `$results\tables`). This ensures that the code works across multiple operating systems, and avoids issues that arise due to the backslash being used as an escape character. 
* Avoid spaces and capital letters in file and folder names.
* Never use `cd` to manually change the directory. Unfortunately Stata does not have a package to work with relative filepaths (like `here` in R or `pyprojroot` in Python). Instead, the `00_run.do` script (described below) should define a global macro for the project's root directory and (optionally) global macros for its immediate subdirectories. Then, since scripts should always be run through the `00_run.do` script, all other do files should not define full absolute paths but instead should specify absolute paths using the global macro for the root directory that was defined in `00_run.do`.
    * This ensures that when others run the project code, they only need to change the file path in one place. 
    * Within project teams, you can include a chunk of code in `00_run.do` that automatically determines which team member's computer or which server is running the code using `if` conditions with ``"`c(username)'"``. This is described in more detail below in the example `00_run.do` script below. 
    * However, for the replication package a user outside the team would still need to manually edit the file path of the project's root directory. This should require editing only __one line of code__ in `00_run.do` and not editing any code in any other do files.

## Scripts structure

### Separating scripts
Because we often work with large data sets and efficiency is important, I advocate (nearly) always separating the following three actions into different scripts:

  1. Data preparation (cleaning and wrangling)
  2. Analysis (e.g. regressions)
  3. Production of figures and tables
  
The analysis and figure/table scripts should not change the data sets at all (no pivoting from wide to long or adding new variables); all changes to the data should be made in the data cleaning scripts. The figure/table scripts should not run the regressions or perform other analysis; that should be done in the analysis scripts. This way, if you need to add a robustness check, you don't necessarily have to rerun all the data cleaning code (unless the robustness check requires defining a new variable). If you need to make a formatting change to a figure, you don't have to rerun all the analysis code (which can take awhile to run on large data sets).

### Naming scripts
* Include a 00_run.do script (described below).
* Number scripts in the order in which they should be run, starting with 01.
* Because a project often uses multiple data sources, I usually include a brief description of the data source being used as the first part of the script name (in the example below, `ex` describes the data source), followed by a description of the action being done (e.g. `dataprep`, `reg`, etc.), with each component of the script name separated by an underscore (`_`).

### 00_run.do script
Keep a "run" script, 00_run.do that lists each script in the order they should be run to go from raw data to final results. Under the name of each script should be a brief description of the purpose of the script, as well all the input data sets and output data sets that it uses. 

The 00_run.do script accomplishes three objectives:
    1. Define the global macro for the project's root directory. A code chunk that automatically identifies which user on the team is running the code can also be included so that no code needs to be edited for different team members to run 00_run.do. Nevertheless, one line of code in 00_run.do will need to be edited when someone outside the research team wants to run the replication package.
    1. Include boilerplate to mimic a fresh Stata session (e.g. clearing any data sets and locals in memory).
    1. Run particular scripts for the analysis. Which scripts are run is controlled with local macros. In the final replication package, these macros should all be set to 1.
    
Ideally, a user could run `00_run.do` to run the entire analysis from raw data to final results (although this may be infeasible for some projects, e.g. one with multiple confidential data sets that can only be accessed on separate servers).
* Also include objects that can be set to 0 or 1 to only run some of the scripts from the 00_run.R script (see the example below).

Below is a brief example of a 00_run.do script. 

```stata
// Run script for example project

// BOILERPLATE ---------------------------------------------------------- 
// For nearly-fresh Stata session and reproducibility
set more off
set varabbrev off
clear all
macro drop _all
version 14.2

// The following code ensures that all user-written ado files needed for
//  the project are saved within the project directory, not elsewhere
tokenize `"$S_ADO"', parse(";")
while `"`1'"' != "" {
    if `"`1'"'!="BASE" cap adopath - `"`1'"'
    macro shift
}
adopath ++ "$MyProject/scripts/programs"

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
```

## Graphing
  * Sean wrote an .ado file called graph_options.ado to control the formatting of graphs in stata 
    * To use this, simply write, for example: `scatter price mpg graph_options()`. The default market color is green, but you can change it manually like a normal graphing object by specifying: `scatter price mpg graph_options(), mcolor(pink)`. 
  * For reproducible graphs, always use `ysize(#)` and `xsize(#)` when exporting graphs
  * Use `spmap` for creating maps and plotting spatial data
  * Use white background for all graphs, `graphregion(color(white))`. 
  * Use white background and white boundary lines for all legends, `legend(nobox region(lcolor(white))`. 

<!---
## Tables
 * Generate every table automatically from the scripts. 
 * Generate table with `booktabs` format. 
--->

## Saving files

#### Data sets
  * Use the Stata commands `save file.dta` and `use file.dta` when saving and reading in data 
    * To write over a file that already exists, use the `replace` option
    * To clear out memory when reading in a dataset, use the `clear` option
  
  * When dealing with large datasets, there are a couple of things that can make your life easier:
    * Stata reads faster from its native format
    * you can read only a select number of observations or variables
      * `use [varlist] [if] [in] using filename [,clear nolabel]
 * When you just want to save your files temporarily for later use, please use `tempfile`. But `tempfile` will not be saved after the program ends. 
      
#### Graphs
* Save graphs with `graph export`.
    * For reproducible graphs, always specify the width and height dimensions in pixels using the `width` and `height` options (e.g. `width(600) height(400)`).
* To see what the final graph looks like, open the file that you save since its appearance will differ from what you see in Stata graphs pane when you specify the `width` and `height` arguments in `graph export`.
* For higher (in fact, infinite) resolution, save graphs as .eps files. (This is better than .pdf given that .eps are editable images, which is sometimes required by journals.)
  * I've written a Python function [`crop_eps`](https://github.com/skhiggins/PythonTools/blob/master/crop_eps.py) to crop (post-process) .eps files when you can't get the cropping just right in Stata.
      
## Randomization
When randomizing assignment in a randomized control trial (RCT):
* Seed: Use a seed from https://www.random.org/: put Min 1 and Max 100000000, then click Generate, and copy the result into your script. Towards the top of the script, assign the seed with the line
    ```stata
    local seed ... // from random.org
    ```
    where `...` is replaced with the number that you got from [random.org](https://www.random.org/)
* Make sure the Stata version is set in the `00_run.do` script, as described above. This ensures that the randomization algorithm is the same, since the randomization algorithm sometimes changes between Stata versions. 
* Use the `randtreat` package.
* Immediately before the line using a randomization function, include ``set seed `seed'``.
* Build a randomization check: create a second variable a second time with a new name, repeating ``set seed `seed'`` immediately before creating the second variable. Then check that the randomization is identical using `assert`.
* As a second randomization check, create a separate script that runs the randomization script once (using `do`) but then saves the data set with a different name, then runs it again (with `do`), then reads in the two differently-named data sets from these two runs of the randomization script and ensures that they are identical.
* Note: if creating two cross-randomized variables, you would not want to repeat ``set seed `seed'`` before creating the second one, otherwise it would use the same assignment as the first.
  
Above I described how data preparation scripts should be separate from analysis scripts. Randomization scripts should also be separate from data preparation scripts, i.e. any data preparation needed as an input to the randomization should be done in one script and the randomization script itself should read in the input data, create a variable with random assignments, and save a data set with the random assignments.

## Running scripts
Once you complete a script, which you might be running line by line while you work on it, make sure the script works on a fresh Stata session. To do this, adjust the local macros in `00_run.do` to run the appropriate scripts (i.e., set the local macros for the scripts you want to run to 1, and the local macros for the scripts you do not want to run to 0), and run the entire `00_run.do` file. The boilerplate code in `00_run.do` will ensure that you are running the code in a nearly-fresh Stata session.

## Reproducibility
* As shown above, include a `version` statement in the `00_run.do` script. For example, writing `version 16.1` makes all future versions of Stata run your code the same way Stata 16.1 did.

* Start your do files by opening a log file; this records all commands and output in a session and can be helpful to look back at the output from a particular script.
    * Name the log files using the same naming convention as you use for your scripts. For example the log file for 01_ex_dataprep.do should be 01_ex_dataprep.log.
    * Use the `text` option so that log files are saved as plain text rather than in Stata Markdown Command Language (SMCL). This ensures that they can be easily viewed in any text editor.
    * Start a log with `log using`, for example:
    ```stata
    log using "$logs/01_ex_dataprep.log", text replace
    ```
  * Close a log file at the end of the script with `log close`.
    
* All user-written ado files that are used by your scripts should be kept in the `$scripts/programs` folder.
    * The `00_run.do` script should include the following code, which will lead to an error if any of the user-written ado files needed for the project are not saved in `$scripts/programs`. After running the code below (h/t [Julian Reif](https://julianreif.com/guide/)), if you `ssc install` any programs during the same Stata session, they will correctly install in the project's `$scripts/programs` folder. If you switch to working on a different project, you should close and reopen Stata.
    ```stata
    tokenize `"$S_ADO"', parse(";")
    while `"`1'"' != "" {
        if `"`1'"'!="BASE" cap adopath - `"`1'"'
        macro shift
    }
    adopath ++ "$MyProject/scripts/programs"
    ```
        
<!---
## Version control

### GitHub
Github is an important tool to maintain version control and for reproducibility purposes. There are many tutorials online, like Grant Mcdermott's slides [here](https://raw.githack.com/uo-ec607/lectures/master/02-git/02-Git.html#9), and I will share some tips from these notes. I will provide instructions for only the most basic commands here. 

We need to first create a git repository or clone an existing one.  

* To clone an existing github repository, use `git pull repolink` where repolink is the link copied from the repository on Github. 
* To initialize a new repo, use `git init` in the project directory

Once you you have initialized a git repository and you make some local changes, you will want to update the Github repository, so that other collaborators can have access to updated files. To do so, we will use the following process:   

* Check the status: `git status`. I like to use this frequently, in order to see file you've changed and those you still need to add or commit.
* Add files for staging: `git add <filename>`. Use this to add local changes to the staging area. 
* Commit: `git commit`. This command saves your changes to the local repository. It will prompt you to add a commit message, which can be more concisley written as `git commit -m "Helpful message"`
* Push changes to github: assuming there is a Github repository created, use `git push origin master` to push your saved local changes to the Github repo. 

However, there are often times when we encounter merge conflicts. A merge conflict is an event that occurs when Git is unable to automatically resolve differences in code between two commits. For example, if a collaborator edits a piece of code, stages, commits and pushes a change, and you try to push changes for the same piece of code, you will encounter a merge conflict. We need to figure out how fix these conflicts.  

* I like to start with `git status` which shows the conflicted files.
* If you open up the conflicted files with any text editor, you will see a couple of things. 
  * `<<<<<<< HEAD` shows the start of the merge conflict.
  * `=======` shows the break point used for comparison.
  * `>>>>>>> <long string>` shows the end of merge conflict.
* You can now manually edit the code and delete whatever lines of code you don't want and the special chanracters that Git added in the file. After that you can stage, commit and push your files without conflict. 


### Dropbox
#### Linking Github and Dropbox for a project
Here I will present the best methods for linking a project on both Dropbox and Github, which is inspired, but modified from [this tutorial](https://github.com/kbjarkefur/GitHubDropBox)). The RA (or whomever is setting up the project)  should complete ALL of the following steps. Others need to do only the steps marked with (All). Before going ahead, make sure you have both a Github account, a Dropbox account, and the Dropbox app downloaded on your computer. The main idea of this setup is that our Dropbox will serve as an extra clone where we can share new raw data, but the main version control will be done on Github.

1. First, establish the Dropbox folder for the project. Create a Dropbox folder, share it with all project members, and let's call the project we are working on "SampleProject". In this step, we aren't doing anything with Github.

2. The RA will now create a github repo for the project, name it identically to the Dropbox folder and clone it locally to your computer. 

3. (All) Clone the  github repo locally by going to terminal. I will clone this in my home directory. To do so, I would type
```
cd noahforougi
git clone repolink
``` 
where repolink is the link copied from the repository page on Github.com. It is important that when you clone this repository, you are doing it in a directory that is not associated with Dropbox. 

4. The next step is to clone the repository again, but this time **in the local Dropbox directory**. So, for example, say I have cloned the project in this directory `/Users/noahforougi/SampleProject/`. I will now change the directory to my Dropbox directory and clone the Github repo to the Dropbox. 
```
cd /Dropbox/SampleProject/
git clone repolink
```

5. Now, we want to create a more formal project structure. To do so, we are going to edit the Dropbox directly (we will only be doing this once!). Follow the conventions mentioned earlier in this guide, create the project on Dropbox, but **exclude the proc** folder. The dropbox should look something like this:
- Dropbox/
  - SampleProject/
    - data/
    - documentation/
    - README.md
    - results/
    - scripts/
    
6. (All) We want the Dropbox project structure (which the RA has created) on our local repo which is synched with Github(in my case, the /Users/noahforougi/ directory). We will only have to do this once, but we are going to manually copy and paste all the folders into our local repo. Additionally, create a proc/ folder locally. This allows us to share **raw** data via Dropbox, but the **processed** data will be generated by actually running the scripts locally. Our project should look like this: 
- noahforougi/
  - SampleProject/
    - data/
    - proc/
    - documentation/
    - README.md
    - results/
    - scripts/
    
7. (All) We want to create a .gitignore file in the local directory. This means when we push our local changes to Github, we are ignoring the data/, proc/ and documentation/ folders. This is crucial because of data confidentiality reasons. There are plenty of tutorials online about how to create a .gitignore file. In the gitignore file please include the following:
 
  /documentation/* <br>
  /data/* <br>
  /proc/*
 
8. Now, go back into the Dropbox folder and repeat this step. We need to create a .gitignore file in the Dropbox as well.

Our project structure is complete. We can now make local edits to the scripts and results and push them to Github. All other project members will be able to receive these changes and update their local proc/ files by running the newly synched scripts. The main interactions should be to push local edits to Github. You should **not** be making edits to the scripts located on the Dropbox. If we want to share new raw data, we will need to copy and paste that locally, but it will not cause issues because of the .gitignore file. 
--->

## Misc.

Some additional tips:

* For debugging, use `set trace on` before running the script. This will show you how Stata is interpreting your code and can help you find the bug.
    * `set tracedepth` is also useful to control how deep into each command's code the trace feature will go. The default when you `set trace on` is `set tracedepth 32000`. If you don't want to print so much of the code Stata is interpreting as it goes through your script, you can use for example `set tracedepth 2`.
* To run portions of code while you are programming, you can set local macros at the top of the do file and then use `if` conditions to only run some of the chunks of code. This is preferable to highlighting sections of code in the do file and running just those lines. For example:
    ```stata
    // Set local macros
    local cleaning  = 0
    local reshape   = 1

    // Read in ex data
    use "$data/ex_data.dta", clear

    // Wrangle the data
    if (`cleaning' == 1) {
        // Clean the data
    }
    if (`reshape' == 1) {
        // Reshape the data
    }
    ```
    * In the final replication package, all of these local macros and `if` conditions should either be removed or all set to 1 so that all of the code runs in the replication package without the user needing to adjust the local macros.
