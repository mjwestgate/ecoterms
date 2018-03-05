library(googlesheets)

run_googlesheets<-function(x, worksheet, word_input){
	# work out which row to sample
    row_lookup<-gs_read(x, ws=worksheet, 
		range="A1:A1000", 
		verbose=FALSE, progress=FALSE)
    info_row<-min(which(row_lookup$selected==FALSE))+1
    gs_edit_cells(x, ws= worksheet,  # allocate this location as taken
      input="TRUE",
      anchor=paste0("A", info_row)
    )
	# get and reshape relevant data
	row_data<-gs_read(x, ws= worksheet, 
		range=paste0("B", info_row), 
		col_names=FALSE,
		verbose=FALSE, progress=FALSE)
	row_data<-as.numeric(strsplit(as.character(row_data), ";")[[1]])
	words_tr<-word_input[row_data]
	word_dframe<-as.data.frame(
		matrix(data=words_tr, nrow=10, ncol=3, byrow=TRUE),
		stringsAsFactors=FALSE)
	colnames(word_dframe)<-paste0("word", c(1:3))
	word_dframe$selected<-0
	return(list(df=word_dframe, row= info_row))
}


server <- function(input, output, session) {

  # import data
  ordered_terms<-read.csv("./data/ordered_terms.csv", stringsAsFactors=FALSE)
  words_all<-ordered_terms$term
  key_string<-"ENTER KEY STRING HERE"

  # reactive values
  words<-reactiveValues(x= NA) # list of all words in the game
  gs_row<-reactiveValues(x=1) # googlesheets row - where to send/receive data
  row_number<-reactiveValues(d=1) # in-game progress

  # to start game
  observeEvent(input$start, {
    hide("start_page")
	show("loading_page")
	sheet<-gs_key(key_string)
	data_tr<-run_googlesheets(sheet,
		worksheet="ecoterms_v2", 
		word_input= words_all)
	words$x<-data_tr$df
	gs_row$x<-data_tr$row
	hide("loading_page")
	show("game")
  })

  observeEvent(input$restart, {
    hide("end_page")
	row_number$d<-1
	show("loading_page")
	sheet<-gs_key(key_string)
	data_tr<-run_googlesheets(sheet,
		worksheet="ecoterms_v2", 
		word_input= words_all)
	words$x<-data_tr$df
	gs_row$x<-data_tr$row
	hide("loading_page")
	show("game")
  })


  # game
  output$mid_text <-renderText({"Which is the odd one out?<br><br>"})
  output$progress_tracker <-renderText({
	paste0("progress: page ", row_number$d, " of 10")
  })

# in-game buttons
  output$b1<-renderUI({
    actionButton("select_1", words$x$word1[row_number$d], 
      width="350px", style="color: #fff; background-color: #428bca;"
    )
  })
  output$b2<-renderUI({
    actionButton("select_2", words$x$word2[row_number$d], 
      width="350px", style="color: #fff; background-color: #428bca;"
    )
  })
  output$b3<-renderUI({
    actionButton("select_3", words$x$word3[row_number$d], 
      width="350px", style="color: #fff; background-color: #428bca;"
    )
  })
  output$unknown<-renderUI({
    actionButton("select_none", "Unclear (skip)", 
      width="350px", style="color: #fff; background-color: #616161;"
    )
  })

  # and their effects
  observeEvent(input$select_1, {
    words$x$selected[row_number$d]<- 1
    if(row_number$d == 10){
      hide("game")
      show("save_page")
      gs_edit_cells(gs_key(key_string), ws="ecoterms_v2",
        input=paste(words$x$selected, collapse=";"),
        anchor=paste0("C", gs_row$x),
	    byrow=TRUE)
      hide("save_page")
      show("end_page")
    }else{row_number$d <- (row_number$d + 1)}
  })

  observeEvent(input$select_2, {
    words$x$selected[row_number$d]<- 2
    if(row_number$d == 10){
      hide("game")
      show("save_page")
      gs_edit_cells(gs_key(key_string), ws="ecoterms_v2",
        input=paste(words$x$selected, collapse=";"),
        anchor=paste0("C", gs_row$x),
	    byrow=TRUE)
      hide("save_page")
      show("end_page")
    }else{row_number$d <- (row_number$d + 1)}
  })

  observeEvent(input$select_3, {
    words$x$selected[row_number$d]<- 3
    if(row_number$d == 10){
      hide("game")
      show("save_page")
      gs_edit_cells(gs_key(key_string), ws="ecoterms_v2",
        input=paste(words$x$selected, collapse=";"),
        anchor=paste0("C", gs_row$x),
	    byrow=TRUE)
      hide("save_page")
      show("end_page")
    }else{row_number$d <- (row_number$d + 1)}
  })

  observeEvent(input$select_none, {
    words$x$selected[row_number$d]<- NA
    if(row_number$d == 10){
      hide("game")
      show("save_page")
      gs_edit_cells(gs_key(key_string), ws="ecoterms_v2",
        input=paste(words$x$selected, collapse=";"),
        anchor=paste0("C", gs_row$x),
	    byrow=TRUE)
      hide("save_page")
      show("end_page")
    }else{row_number$d <- (row_number$d + 1)}
  })



  # end
  output$end_text<-renderText({"Thanks for playing!<br><br>"})
  observeEvent(input$end, {stopApp()})

  output$final_results<-renderPlot({
	continue_test<-all(is.na(words$x$selected))==FALSE
    if(continue_test){
		# extract connection data
		data_tr<-isolate(words$x)
		word_check<-lapply(data_tr$selected, function(a, lookup){
			if(is.na(a)){return(rep(NA, 2))
			}else{
				result<-apply(lookup, 2, function(b, n){any(b==n)==FALSE}, n=a)
				lookup[, which(result)]
			}
			}, lookup=combn(c(1:3), 2))
		selected<-do.call(rbind, word_check)
		colnames(selected)<-c("sel1", "sel2")
		data_tr<-as.data.frame(cbind(data_tr, selected))
		network_tr<-data.frame(
			word1=unlist(lapply(split(data_tr[, c(1:3, 5)], c(1:nrow(data_tr))), 
				function(a){as.character(a[1, 1:3])[as.numeric(a[1, 4])]})),
			word2=unlist(lapply(split(data_tr[, c(1:3, 6)], c(1:nrow(data_tr))), 
				function(a){as.character(a[1, 1:3])[as.numeric(a[1, 4])]})),
			stringsAsFactors=FALSE)
		network_tr<-network_tr[which(unlist(lapply(split(network_tr, c(1:nrow(network_tr))),
			function(a){all(is.na(a))==FALSE}))), ]
		
		# add ordination x, y
		vals1<-lapply(network_tr$word1, function(a, lookup){lookup[which(lookup$term==a), 3:4]}, 
			lookup=ordered_terms)
		vals1<-do.call(rbind, vals1)
		colnames(vals1)<-c("x0", "y0")
		network_tr<-cbind(network_tr, vals1)
		vals2<-lapply(network_tr$word2, function(a, lookup){lookup[which(lookup$term==a), 3:4]}, 
			lookup=ordered_terms)
		vals2<-do.call(rbind, vals2)
		colnames(vals2)<-c("x1", "y1")
		network_tr<-cbind(network_tr, vals2)

		# check which words are in the point list
		unique_terms<-sort(unique(c(network_tr$word1, network_tr$word2)))
		rows<-which(ordered_terms$term %in% unique_terms)
		ordered_terms$group<-1 #"grey70"
		ordered_terms$group[rows]<-2 #"grey30"
		terms_tr<-ordered_terms$term[which(ordered_terms$group==2)]
		terms_tr<-unlist(lapply(strsplit(terms_tr, " "), function(a){
			if(length(a)==1){return(a)}else{paste(a[1:2], collapse=" ")}}))

		# plot
		par(mar=rep(0, 4))
		plot(y ~ x, data=ordered_terms, type="n", ann=FALSE, axes=FALSE)
		points(y ~ x, data=ordered_terms[which(ordered_terms$group==1), ], pch=16, col="grey70")
		line_list<-split(network_tr[, 3:6], c(1:nrow(network_tr)))
		invisible(lapply(line_list, function(a){lines(x=c(a$x0, a$x1), y=c(a$y0, a$y1), col="grey30")}))
		points(y ~ x, data=ordered_terms[which(ordered_terms$group==2), ], pch=16, col="grey30")
		text(y ~ x, data=ordered_terms[which(ordered_terms$group==2), ], 
			labels= terms_tr, 
			cex=0.8, pos=3, pch=16, col="grey30")
	}else{
		plot(y ~ x, data=ordered_terms, type="n", ann=FALSE, axes=FALSE)
		points(y ~ x, data=ordered_terms, pch=16, col="grey70")
	}
})

} # end server