<img width="1147" height="451" alt="image" src="https://github.com/user-attachments/assets/69bd2766-3ab8-4ae9-b7a9-bd575927cb46" />

## Repository Structure
All of the in-class exercises and assignments in this class rely on a similar project structure to help you organize your data analysis. It also provides me a way to include any necessary utility scripts for your assignment.


```    
    - AssignmentRoot/
        - data/
            - original/
            - processed/
        - docs/
            - assignment.qmd
        - output/
        - scripts/
            - test/
            - final/
            - utilities/
        - README.md
        - .gitignore
        - _quarto.yml
```


The main folder contains the `README.md` with basic repository structure information, git reminders, and assignment information (due dates etc). In addition, you'll notice a `.gitignore` file. This tells `git` which files are exempt from tracking. For this class, that is mostly focused on large datafiles (which can't be uploaded to github) and intermediate processing files that show up when you render a Quarto document. Finally, you'll see a `_quarto.yml` document. This file contains a series of `.yaml` instructions that `Quarto` uses to render your entire project. **You shouldn't need to change the `.gitignore` or `_quarto.yml` files.** 

Beyond those 3 files, you'll notice a `data`, `docs`, `output`, and `scripts` folder. Inside each subfolder is an empty file called `.gitkeep`. This is just there to make sure that everyone ends up with exactly the same folder structure. The important things to note here are that the `original` folder is for data downloaded externally. Once any processing has been done, you should save it to the `processed` folder. This facilitates reproducibility by ensuring that a person can begin with the exact original data, run any processing scripts (stored in your `scripts/final` or `scripts/utilities/` folders, and get the same outputs (stored in the `outputs` folder) that you obtained. The `test` folder is a sandbox where you can store your tidbits of code that are still being developed. The `docs` folder will contain the actual Quarto document with the assignment requirements listed in it. Once you've completed the assignment, you should be able to render the `.qmd` file and push the repository up the classroom.


---

## Committing, Pushing, and Pulling Changes

Effective version control is essential for tracking changes, collaborating with others, and ensuring your project evolves in an organized manner. Follow these GitHub best practices:

### Committing Changes
- Commit your changes regularly with clear, descriptive commit messages.
- Each commit should represent a logical unit of work, such as a completed feature or a fixed bug.
- Example:
```r
git commit -m "Added function for data cleaning"
```

### Pushing Changes:
- Push your changes to the remote repository after committing them locally.
- Example:
```r
git push origin main
```

### Pulling Changes:
- Before starting work each day, pull the latest changes from the main branch to keep your local repository up to date.
- Example: 
```r
git pull origin main
```

### Branching:
- Use branches to develop new features or fix bugs. Once a branch is complete, merge it back into the main branch.

---

## Using `.gitignore`

You can configure Git to ignore files you don't want to check in to GitHub.

- The `.gitignore` file in you repository's root directory will tell Git which files and directories to ignore when you make a commit.


Here is an example of how it can be used, by adding this into the `.gitignore` file... 
```r
data/original/*
```
... it tells Git to ignore everying inside the `data/original` directory when commiting. 

### Using `.gitkeep` with `.gitignore`:
However, Git doesn't track empty folders. 
If you want to ensure the `data/original` directory still exists in the repository, while still ignoring it's contents, you will first need to create a `.gitkeep` file.
You can do so like this in the terminal...
```r
touch data/original/.gitkeep
```
... and then add the following lines in the `.gitignore` file...
```r
# ignore files in the folder
data/original/*

# but keep the folder
!data/original/.gitkeep
```
... the `!` negates the ignore rule, meaning Git will track the `.gitkeep` file inside the `data/original/` directory. 
- This is helpful when you want to ignore everything inside a directory, but at the same time want to check-in the folder and keep the directory structure.

### For Mac Users: What are the `.DS_Store` Files?

The `.DS_Store` (Desktop Service Store) file is a hidden macOS system file that appears in every directory that a Mac user opens. It is automatically created by Finder, to store the metadata about the folder it is in, things like; icon positions, view options, window size and position, sorting preferences, etc.. 

They are not needed for most projects and can be ignored in Git by adding these lines to your `.gitignore` file...
```r
# simple approach for ignoring .DS_Store files everywhere in the repository
.DS_Store

# more explicit approach for ignoring .DS_Store file in all subdrectories
**/.DS_Store
```
... I suggest adding both lines, as it just enures all `.DS_Store` files, even deepy nested ones, will be ignored, as sometimes `.gitignore` can have unusual rules affecting recursion. 


---



