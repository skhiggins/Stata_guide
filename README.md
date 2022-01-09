# Stata Guide

This guide provides instructions for using Stata on research projects. Its purpose is to use with collaborators and research assistants to make code consistent, easier to read, transparent, and reproducible.


## Style
For coding style practices, follow the [DIME Analytics Coding Guide](  https://worldbank.github.io/dime-data-handbook/coding.html).

## Packages 
Most user-written Stata packages are hosted on Boston College Statistical Software Components (SSC) archive. It easy to download packages from SSC; simply run `ssc install package` where `package` should be replaced with the name of the package you want to install. 

* Use `reghdfe` for fixed effects regressions
* Use `ftools` and `gtools` for working with large datasets 
* Use `randtreat` for randomization
* When generating tables with multiple panels, `regsave` and `texsave` are recommended. 

## Filepaths
Use forward slashes for pathnames (`$results/tables` not `$results\tables`). This ensures that the code works across multiple operating systems, and avoids issues that arise due to the backslash being used as an escape character. Avoid spaces and capital letters in file and folder names.

Never use `cd` to manually change the directory. Unfortunately Stata does not have a package to work with relative filepaths (like `here` in R or `pyprojroot` in Python). Instead, the `00_run.do` script (described below) should define a global macro for the project's root directory and (optionally) global macros for its immediate subdirectories. Then, since scripts should always be run through the `00_run.do` script, all other do files should not define full absolute paths but instead should specify absolute paths using the global macro for the root directory that was defined in `00_run.do`.

* This ensures that when others run the project code, they only need to change the file path in one place. 
* Within project teams, you can include a chunk of code in `00_run.do` that automatically determines which team member's computer or which server is running the code using `if` conditions with ``"`c(username)'"``. This is described in more detail below in the example `00_run.do` script below. 
* However, for the replication package a user outside the team would still need to manually enter the file path of the project's root directory. This should require editing only one line of code in `00_run.do` and not editing any code in any other do files.

## Folder structure

Generally, within the folder where we are doing data analysis (the project's "root folder"), we have the following files and folders. All the folders should be generated within the do file. 

  * data - only raw data go in this folder
  * documentation - documentation about the data go in this folder
  * proc - processed data sets go in this folder
  * results - results go in this folder
    * figures - subfolder for figures
    * tables - subfolder for tables
    * logs - subfolder for log files
  * scripts - code goes in this folder
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
  * Use white background for all graphs, `graphregion(color(white))`. 
  * Use white background and white boundary lines for all legends, `legend(nobox region(lcolor(white))`. 

## Tables
 * Generate every table automatically from the scripts. 
 * Generate table with `booktabs` format. 

## Saving files

#### Datasets
  * Use the Stata commands `save file.dta` and `use file.dta` when saving and reading in data 
    * To write over a file that already exists, use the `replace` option
    * To clear out memory when reading in a dataset, use the `clear` option
  
  * When dealing with large datasets, there are a couple of things that can make your life easier:
    * Stata reads faster from its native format
    * you can read only a select number of observations or variables
      * `use [varlist] [if] [in] using filename [,clear nolabel]
 * When you just want to save your files temporarily for later use, please use `tempfile`. But `tempfile` will not be saved after the program ends. 
      
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
 * To run all the commands in a do file sequentially in Stata, click the “Do” button in the top-right corner.
 * To run some but not all commands in a do file, highlight the commands that you would like to run and then press the “Do” button.


## Reproducibility
  * Start your do files by opening a log file; this records all commands and output in a session and can be helpful to look back on the work for a particular project
    * Open a log file with `log using filename, text replace` and close a log file at the end of your session with `log close`
    
  * All user written ado files should be kept in the `scripts/programs`.
  * At the beginning of the master script, `run_all.do`, add `adopath ++ "$project_dir/scripts/programs"`. Whenever you open the Stata and you know you will install packages later, you should type below code, 
    ```
    sysdir set PLUS "$project_dir/scripts/programs"
    sysdir set PERSONAL $project_dir/scripts/programs"
    ```
    The above procedures will let Stata searches for user written ado files in  the folder `scripts/programs`. But the `PLUS` and `PERSONAL` paths you set will be automatically removed when you start a new Stata session. So you need to do it every time you open the Stata and you know you will install packages. You just need to do it once in one Stata session. 

## Version control
Include `version` statement in the head of the script. Writing `version 16` makes all future versions of Stata to run your code the same way Stata 16 did. (Quoted from [Stata coding tips](https://julianreif.com/guide/#stata_coding_tips))
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

## Misc.

Some additional tips:

* Error handling: use `set trace on`. 
* You could put the code into a loop `if 1 {}`. If you do not want to run the code in this loop, you can just change it to `if 0 {}`. When the whole script is finished, you can delete all the `if 1 {}` and `if 0 {}`. 
