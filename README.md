ecoterms
==========

# what is ecoterms?
ecoterms is a shiny app designed to run a series of triad tasks; survey questions where the user is presented with three words, and asked to remove the outlying term. 

# why doesn't this code work?
This repo stores the code needed to run ecoterms, and all the files and folders are named correctly and are in the correct locations. BUT it won't work perfectly in it's current form. That is, this code...
```
runGitHub( "ecoterms", "mjwestgate")
```
...shouldn't work. Sorry about that; but there is a reason!

ecoterms is unusual because it was built to show a different combination of words to each user. This meant having some way to check which combinations of words had already been used. To do this, I linked two data sources. One is the 'master' list of terms that are available in the game, which is built in to the app (in the 'data' folder). The second is a google sheet with three columns. The following code builds a data.frame with the correct properties:

```
example_data<-data.frame(
  selected=FALSE,
  word_index=paste(sample.int(100,30), sep=";"),
  result=0,
  stringsAsFactors=FALSE)
```

The app doesn't work because I've disabled the link to the google sheet used to run the original version of the app.

# How can I get it to work again?
If you build an google sheet with the properties given in the last code block (but with 1 row for every possible user), you can link the app to the sheet by adding the key string to to app . You can see how to get the key string [on the google sheets vignette](https://cran.r-project.org/web/packages/googlesheets/vignettes/basic-usage.html#register-a-sheet). Once you've done that, you can enter it in server.r at the line that reads:

```
key_string<-"ENTER KEY STRING HERE"
```

When the game is set up properly, it will query the google sheet, find the first row where selected=FALSE, and use the value of 'word_index' for that row to parameterise the game. By default it runs 10 screens, each containing 3 words. When the user is finished, the selections that user has made are saved to the 'result' column of the linked spreadsheet.