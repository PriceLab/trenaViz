# tvHelpers.R
#------------------------------------------------------------------------------------------------------------------------
setupIgvAndTableToggling <- function(session, input)
{
   observeEvent(input$trackClick, {
      printf("TrenaViz, tvHelpers, trackClickEvent seen")
      })


   observeEvent(input$currentGenomicRegion, {
       newValue <- input$currentGenomicRegion
       #printf("newValue: %s", newValue)
       #printf("input$currentGenomicRegion: %s", input$currentGenomicRegion)
       if(newValue != state$chromLocRegion){
          #printf("new genomic regions: %s", newValue)
          state$chromLocRegion <- newValue
          loc <- parseChromLocString(newValue)
          tbl.region <- with(loc, data.frame(chrom=chrom, start=start, end=end, stringsAsFactors=FALSE))
          #printf("--- calling sgr(bsm) from tvHelpers setupIgvAndTableToggling")
          setGenomicRegion(bsm, tbl.region)
          setGenomicRegion(fimoBuilder, tbl.region)
          }
       })

   observeEvent(input$igvHideButton, {
     if(input$igvHideButton %% 2 == 1){
        printf("  --- hiding igv, widening dataTable")
        shinyjs::hide(id = "igvColumn")
        shinyjs::toggleClass("dataTableColumn", "col-sm-3")
        shinyjs::toggleClass("dataTableColumn", "col-sm-12")
      } else {
        printf("  --- showing igv, narrowing dataTable")
        shinyjs::toggleClass("dataTableColumn", "col-sm-12")
        shinyjs::toggleClass("dataTableColumn", "col-sm-3")
        shinyjs::show(id = "igvColumn")
        }
      printf("--- calling redrawIgvWidget after igv toggle button")
      redrawIgvWidget(session)
      redrawModelDataTable()
      })

   observeEvent(input$tableHideButton, {
      if(input$tableHideButton %% 2 == 1){
         shinyjs::hide(id = "modelSelectorColumn")
         shinyjs::hide(id = "dataTableColumn")
         shinyjs::toggleClass("igvColumn", "col-sm-9")
         shinyjs::toggleClass("igvColumn", "col-sm-12")
      } else {
         shinyjs::toggleClass("igvColumn", "col-sm-12")
         shinyjs::toggleClass("igvColumn", "col-sm-9")
         shinyjs::hide(id = "modelSelectorColumn")
         shinyjs::hide(id = "dataTableColumn")
         shinyjs::show(id = "dataTableColumn")
         shinyjs::show(id = "modelSelectorColumn")
         }
      printf("--- calling redrawIgvWidget after table toggle button")
      redrawIgvWidget(session)
      redrawModelDataTable()
      })

} # setupIgvAndTableToggling
#------------------------------------------------------------------------------------------------------------------------
redrawModelDataTable <- function()
{
      # columns.adjust not actually needed, except perhaps if the column names have changed
      # jQuery.string <- "$('#table table.dataTable[id]').DataTable().columns.adjust().draw();"
      # it is not at all clear where and how [id] is resolved by the js interpreter in the browser

  jQuery.string <- "$('#table table.dataTable[id]').DataTable().draw();"
  shinyjs::runjs(jQuery.string)

} # redrawModelDataTable
#------------------------------------------------------------------------------------------------------------------------
# buildFootprintModel <- function(upstream, downstream)
# {
#    tbl.gene <- subset(getTranscriptsTable(trenaProject), moleculetype=="gene")[1,]
#    tss <- tbl.gene$start
#    min.loc <- tss - upstream
#    max.loc <- tss + downstream
#
#    if(tbl.gene$strand == "-"){
#       tss <- tbl.gene$endpos
#       min.loc <- tss - downstream
#       max.loc <- tss + upstream
#       }
#
#    chrom <-tbl.gene$chr
#    tbl.regions <- data.frame(chrom=chrom, start=min.loc, end=max.loc, stringsAsFactors=FALSE)
#    mtx <- loadExpressionData(trenaProject, "FilteredLengthScaledTPM8282018-vsn")
#
#    build.spec <- list(title=sprintf("%s model %d", getTargetGene(trenaProject), 1),
#                       type="footprint.database",
#                       regions=tbl.regions,
#                       geneSymbol=getTargetGene(trenaProject),
#                       tss=tss,
#                       matrix=mtx,
#                       db.host="khaleesi.systemsbiology.net",
#                       databases=list("brain_hint_20"),
#                       motifDiscovery="builtinFimo",
#                       tfPool=allKnownTFs(identifierType="geneSymbol"),
#                       tfMapping="MotifDB",
#                       tfPrefilterCorrelation=0.05,
#                       annotationDbFile=dbfile(org.Hs.eg.db),
#                       orderModelByColumn="pearsonCoeff",
#                       solverNames=c("lasso", "lassopv", "pearson", "randomForest", "ridge", "spearman"))
#
#      #------------------------------------------------------------
#      # use the above build.spec: a small region, high correlation
#      # required, MotifDb for motif/tf lookup
#      #------------------------------------------------------------
#
#    fpBuilder <- FootprintDatabaseModelBuilder("hg38", getTargetGene(trenaProject), build.spec, quiet=TRUE)
#    x <- build(fpBuilder)
#    xyz <- "back from build"
#
# } # buildFootprintModel
#------------------------------------------------------------------------------------------------------------------------
setupAddTrack <- function(trenaProject, session, input, output)
{
   observeEvent(input$addTrack, {
      newTrackName <- input$addTrack
      if(newTrackName == "") return()
      printf(" addTrack event: %s", newTrackName);
      displayTrack(trenaProject, session, newTrackName)
      later(function() {updateSelectInput(session, "addTrack", selected=character(0))}, 1)
      })


} # setupAddTrack
#------------------------------------------------------------------------------------------------------------------------
displayTrack <- function(trenaProject, session, trackName)
{
   printf("--- displayTrack('%s')", trackName)

   #browser()
   #xyz <- "tvHelpers::displayTrack"
   #loc <- parseChromLocString(state$chromLocRegion)

   targetGene <- getTargetGene(trenaProject)

   if(trackName %in% names(state$dataManifest)){
      if(trackName == "tbl.hiC.psychEncode.RData"){
         tbl.hiC <- get(load(system.file(package="TrenaProjectAD", "extdata", "genomeAnnotation", "tbl.hiC.psychEncode.RData")))
         tbl.subC <- subset(tbl.hiC, toupper(geneSymbol) == toupper(targetGene))
         printf("--- loading %d rows from tbl.hiC for gene %s", nrow(tbl.subC), targetGene)
         title <- sprintf("PsychENCODE enhancers for %s", targetGene)
         msg <- sprintf("count: %d", nrow(tbl.subC))
         showModal(modalDialog(title=title, msg))
         if(nrow(tbl.subC) > 0)
            loadBedTrack(session, "HiC", tbl.subC, color="magenta")
         } # psychEncode
      if(trackName == "geneHancer.v4.7.allGenes.RData"){
         f <- system.file(package="TrenaProject", "extdata", "genomeAnnotation", "geneHancer.v4.7.allGenes.RData")
         tbl.gh <- get(load(f))
         tbl.ghSub <- subset(tbl.gh, toupper(geneSymbol) == toupper(targetGene))
         loadBedGraphTrack(session, "GeneHancer", tbl.ghSub[, c(1:3,5)], color="maroon", autoscale=FALSE, min=0, max=50)
         } # genehancer
      return()
      } # if trackName in dataManifest

   if(grepl(".variants", trackName, ignore.case=TRUE))
      displayBedTrack(trenaProject, session, trackName)

   if(grepl("gwas", trackName, ignore.case=TRUE))
      displayBedTrack(trenaProject, session, trackName)

   if(grepl("^ATAC", trackName, ignore.case=TRUE))
      displayGenomicRegionsTrack(trenaProject, session, trackName)

   if(trackName == "enhancers")
      displayEnhancersTrack(trenaProject, session)

   if(trackName == "dhs")
      displayEncodeDhsTrack(trenaProject, session)

   if(trackName == "phast7")
      displayPhast7ConservationTrack(trenaProject, session)

} # displayTrack
#------------------------------------------------------------------------------------------------------------------------
displayEnhancersTrack <- function(trenaProject, session)
{
   tbl.enhancers <- getEnhancers(trenaProject)
   tbl.tmp <- tbl.enhancers[, c("chrom", "start", "end", "combinedScore")]
   loadBedGraphTrack(session, "GeneHancer", tbl.tmp, color="black", trackHeight=25, autoscale=FALSE, min=0, max=20)

} # displayEnhancersTrack
#------------------------------------------------------------------------------------------------------------------------
displayEncodeDhsTrack <- function(trenaProject, session)
{
   tbl.dhs <- getEncodeDHS(trenaProject)
   tbl.tmp <- tbl.dhs[, c("chrom", "chromStart", "chromEnd", "score")]
   colnames(tbl.tmp) <- c("chrom", "start", "end", "score")
   loadBedGraphTrack(session, "DHS", tbl.tmp, color="black", trackHeight=25, autoscale=TRUE)

} # displayEncodeDhsTrack
#------------------------------------------------------------------------------------------------------------------------
displayPhast7ConservationTrack <- function(trenaProject, session)
{
   printf("--- displayPhast7ConservationTrack")
   new.region <- state[["chromLocRegion"]]
   chromLoc <- trena::parseChromLocString(new.region)

   starts <- with(chromLoc, seq(start, end, by=5))
   ends <- starts + 5
   count <- length(starts)
   tbl.blocks <- data.frame(chrom=rep(chromLoc$chrom, count), start=starts, end=ends,
                            stringsAsFactors=FALSE)
   tbl.cons7 <- as.data.frame(gscores(phastCons7way.UCSC.hg38,
                                      GRanges(tbl.blocks)),
                              stringsAsFactors=FALSE)
   tbl.cons7$chrom <- as.character(tbl.cons7$seqnames)
   tbl.cons7 <- tbl.cons7[, c("chrom", "start", "end", "default")]
   colnames(tbl.cons7) <- c("chrom", "start", "end", "score")
   loadBedGraphTrack(session, "phast7", tbl.cons7, color="black", trackHeight=25, autoscale=TRUE)

} # displayPhast7ConservationTrack
#------------------------------------------------------------------------------------------------------------------------
displayGenomicRegionsTrack <- function(trenaProject, session, trackName)
{
   tbl <- getGenomicRegionsDataset(trenaProject, trackName)
   tbl.bg <- tbl[, c("chrom", "start", "end", "c7")]
   colnames(tbl.bg) <- c("chrom", "start", "end", "value")
   tbl.bg <- subset(tbl.bg, chrom=="chr3")
   loadBedGraphTrack(session, trackName, tbl.bg, color="red", trackHeight=25, autoscale=TRUE)

} # displayGenomicRegionsTrack
#------------------------------------------------------------------------------------------------------------------------
displayGWASTrack <- function(trenaProject, session, trackName)
{
   variantDatasetNames <- getVariantDatasetNames(trenaProject)
   printf("want to see trackName (%s) among variantDatasetNames", trackName)
   print(paste(variantDatasetNames, collapse=", "))

   if(trackName %in% variantDatasetNames){
      printf("  --- found %s to display", trackName)
      #browser()
      printf(" want to restrict variant table to this region: %s", state$chromLocRegion)
      loc <- parseChromLocString(state$chromLocRegion)
      tbl.variant <- getVariantDataset(trenaProject, trackName)
      if(trackName == "GWAS.snps"){
         tbl.variant <- tbl.variant[, c("chrom", "start", "end", "pScore")]
         colnames(tbl.variant) <- c("chrom", "start", "end", "value")
        }
      tbl.variant <- subset(tbl.variant, chrom==loc$chrom & start >= loc$start & end <= loc$end)
      printf("%d regions in %s", nrow(tbl.variant), trackName)
      showNotification(sprintf("%s: %d genomic features", trackName, nrow(tbl.variant)))
      if(nrow(tbl.variant) > 0)
         loadBedGraphTrack(session, trackName, tbl.variant, color="red", trackHeight=25, autoscale=TRUE) # , min=0, max=10)
      } # trackName found in variant data sets

} # displayGWASTrack
#------------------------------------------------------------------------------------------------------------------------
displayBedTrack <- function(trenaProject, session, trackName)
{
   variantDatasetNames <- getVariantDatasetNames(trenaProject)
   printf("want to see trackName (%s) among variantDatasetNames", trackName)
   print(paste(variantDatasetNames, collapse=", "))

   if(trackName %in% variantDatasetNames){
      printf("  --- found %s to display", trackName)
      printf(" want to restrict variant table to this region: %s", state$chromLocRegion)
      loc <- parseChromLocString(state$chromLocRegion)
      tbl.variant <- getVariantDataset(trenaProject, trackName)
      tbl.variant <- subset(tbl.variant, chrom==loc$chrom & start >= loc$start & end <= loc$end)
      printf("%d regions in %s", nrow(tbl.variant), trackName)
      showNotification(sprintf("%s: %d genomic features", trackName, nrow(tbl.variant)))
      if(nrow(tbl.variant) > 0)
         loadBedTrack(session, trackName, tbl.variant, color="red", trackHeight=25)
      } # trackName found in variant data sets

} # displayBedTrack
#------------------------------------------------------------------------------------------------------------------------
setupDisplayRegion <- function(trenaProject, session, input, output)
{
   observeEvent(input$displayGenomicRegion, {
      requestedRegion <- input$displayGenomicRegion
      if(requestedRegion == "") return()
      printf(" displayRegion: %s", requestedRegion)
      margin <- 5000
      loc.string <-switch(requestedRegion,
                          fullEnhancerRegion = {getGeneEnhancersRegion(trenaProject, 10)$chromLocString},
                          fullGeneRegion = {getGeneRegion(trenaProject, 20)$chromLocString},
                          proximal.promoter.2500.500 = {getProximalPromoter(trenaProject, 2500, 500)$chromLocString})

      printf("--- new region: %s", loc.string)
      showGenomicRegion(session, loc.string);
      later(function() {updateSelectInput(session, "displayGenomicRegion", selected=character(0))}, 1)
      })

   observeEvent(input$removeUserAddedTracks, {
      removeUserAddedTracks(session)
      })

} # setupDisplayRegion
#------------------------------------------------------------------------------------------------------------------------
setupBuildModel <- function(trenaProject, session, input, output)
{
   observeEvent(input$modelSelector, ignoreInit=TRUE, {
       modelName <- isolate(input$modelSelector)
       printf("--- new model selected: %s", modelName)
       new.table <- state$models[[modelName]]$model
       displayModel(session, input, output, new.table, modelName)
       })

   observe({
      x <- input$sidebarCollapsed;
      redrawIgvWidget(session)
      })

   observe({
       currentName <- input$modelNameTextInput
       expressionMatrixName <- input$expressionSet
       allInputsSpecified <- nchar(currentName) >= 1 & nchar(expressionMatrixName) > 2
       if(allInputsSpecified)
          shinyjs::enable("buildModelButton")
       else
          shinyjs::disable("buildModelButton")
       })

   observeEvent(input$buildModelButton, {
      getGenomicRegion(session)
      state$tbl.chipSeq <- NULL   # this will force a fresh database query after model is built
      shinyjs::html(id="console", html="", add=FALSE)  # clear the console
      tryCatch({
          withCallingHandlers({buildModel(trenaProject, session, input, output);
                               model.count <- length(state$models)
                               new.model.name <- names(state$models)[model.count]
                               new.table <- state$models[[model.count]]$model
                               displayModel(session, input, output, new.table, new.model.name)
                               updateTabItems(session, "sidebarMenu", select="igvAndTable")
                               },
             message=function(m){
                shinyjs::html(id="console", html=m$message, add=TRUE)
                })
          }, error=function(e){
               msg <- e$message
               print(msg)
               showModal(modalDialog(title="trena model building error", msg))
               }) # tryCatch
      }) # observe buildModelButton

} # setupBuildModel
#------------------------------------------------------------------------------------------------------------------------
buildModel <- function(trenaProject, session, input, output)
{
   model.name <- sprintf("trena.model.%s", input$modelNameTextInput)
   message(sprintf("about to build '%s'", model.name))
   # browser()
   # xyz <- "tvHelpders::buildModel"
   footprint.database.host <- getFootprintDatabaseHost(trenaProject)
   footprint.database.names <- input$footprintDatabases
   tracks.to.intersect.with <- input$intersectWithRegions
   motifMapping <- isolate(input$motifMapping)
   if(tolower(motifMapping) == "motifdb + tfclass")
      motifMapping <- c("MotifDb", "TFClass")
   expressionMatrixName <- input$expressionSet
   message(sprintf("   mtx: %s", expressionMatrixName))
   full.roi <- state$chromLocRegion
   message(sprintf("   roi: %s", full.roi))
   chrom.loc <- trena::parseChromLocString(full.roi)
   message(sprintf("  fpdb: %s", paste(footprint.database.names, collapse=", ")))
   message(sprintf("   roi: %s", full.roi))
   message(sprintf("   mtx: %s", expressionMatrixName))
   message(printf("  intersect with: %s", paste(tracks.to.intersect.with, collapse=",")))

   #browser()
   tbl.gene <- subset(state$tbl.transcripts)[1,]
   strand <- tbl.gene$strand
   tss <- tbl.gene$start
   if(strand == "-")
      tss <- tbl.gene$endpos

   run.trenaSGM(trenaProject,
                model.name,
                chrom.loc$chrom, chrom.loc$start, chrom.loc$end,
                tss,
                expressionMatrixName,
                tracks.to.intersect.with,
                footprint.database.host,
                footprint.database.names,
                motifMapping)

} # buildModel
#------------------------------------------------------------------------------------------------------------------------
run.trenaSGM <- function(trenaProject,
                         model.name,
                         chromosome, start.loc, end.loc,
                         tss,
                         expression.matrix.name,
                         tracks.to.intersect.with,
                         footprint.database.host,
                         footprint.database.names,
                         motifMapping)
{
   message(sprintf("--- entering run.trenaSGM"))
      # no search for overlaps just yet: ignore "tracks.to.intersect.with"
   tbl.regions <- buildRegionsTable(tracks.to.intersect.with, chromosome, start.loc, end.loc,
                                    state$tbl.enhancers, state$tbl.dhs)
   #tbl.regions <- data.frame(chrom=chromosome, start=start.loc, end=end.loc, stringsAsFactors=FALSE)
   mtx <- getExpressionMatrix(trenaProject, expression.matrix.name)
   geneSymbol <- getTargetGene(trenaProject)
   for(r in seq_len(nrow(tbl.regions))){
      message(sprintf("tbl.regions, width: %d", with(tbl.regions[r,], end - start)))
      }

   build.spec <- list(title=model.name,
                      type="footprint.database",
                      regions=tbl.regions,
                      geneSymbol=getTargetGene(trenaProject),
                      tss=tss,
                      matrix=mtx,
                      db.host=footprint.database.host,
                      db.port=getFootprintDatabasePort(trenaProject),
                      databases=footprint.database.names,
                      motifDiscovery="builtinFimo",
                      tfPool=allKnownTFs(identifierType="geneSymbol"),
                      tfMapping=motifMapping,
                      tfPrefilterCorrelation=0.0,
                      annotationDbFile=dbfile(org.Hs.eg.db),
                      orderModelByColumn="pearsonCoeff",
                      solverNames=c("lasso", "lassopv", "pearson", "randomForest", "ridge", "spearman"))
     build.spec.filename <- sprintf("%s.buildSpec.RData", model.name)
     save(build.spec, file=build.spec.filename)
     printf("--- saving build.spec: %s", build.spec.filename)

     #------------------------------------------------------------
     # use the above build.spec: a small region, high correlation
     # required, MotifDb for motif/tf lookup
     #------------------------------------------------------------

   fpBuilder <- FootprintDatabaseModelBuilder("hg38", getTargetGene(trenaProject), build.spec, quiet=FALSE)
   x <- build(fpBuilder)
   message(sprintf("back from build, top 10 tfs:"))
   message(head(x$model, n=10))
   #save(x, file=sprintf("%s.results.RData", model.name))
   state$models[[model.name]] <- x

} # run.trenaSGM
#------------------------------------------------------------------------------------------------------------------------
buildRegionsTable <- function(tracks.to.intersect.with, chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
{
   if(tracks.to.intersect.with == "allDNAForFootprints")
      return(data.frame(chrom=chromosome, start=start.loc, end=end.loc, stringsAsFactors=FALSE))

   gr.region <- GRanges(seqnames=chromosome, IRanges(start.loc, end.loc))
   gr.enhancers <- GRanges(tbl.enhancers)
   gr.dhs <- GRanges(tbl.dhs)
     # strip off metadata so that the regions can be combined
   mcols(gr.region) <- NULL
   mcols(gr.enhancers) <- NULL
   mcols(gr.dhs) <- NULL
   gr.enhancers.or.dhs <- c(gr.enhancers, gr.dhs)
   gr.enhancers.and.dhs <- GenomicRanges::intersect(gr.enhancers, gr.dhs)

   tbl.out  <- switch(tracks.to.intersect.with,
                  genehancer = {
                     tbl.ov <- as.data.frame(findOverlaps(gr.enhancers, gr.region, type="any"))
                     indices <- unique(tbl.ov[,1])
                     as.data.frame(gr.enhancers[indices])
                     },
                  encodeDHS = {
                     tbl.ov <- as.data.frame(findOverlaps(gr.dhs, gr.region, type="any"))
                     indices <- unique(tbl.ov[,1])
                     as.data.frame(gr.dhs[indices])
                     },
                  geneHancerOrEncode = {
                     tbl.ov <- as.data.frame(findOverlaps(gr.enhancers.or.dhs, gr.region, type="any"))
                     indices <- unique(tbl.ov[,1])
                     as.data.frame(gr.enhancers.or.dhs[indices], row.names=NULL)
                     },
                  geneHancerAndEncode = {
                     tbl.ov <- as.data.frame(findOverlaps(gr.enhancers.and.dhs, gr.region, type="any"))
                     indices <- unique(tbl.ov[,1])
                     as.data.frame(gr.enhancers.and.dhs[indices], row.names=NULL)
                     })

   tbl.out <- tbl.out[, 1:3]
   colnames(tbl.out) <- c("chrom", "start", "end")
   tbl.out$chrom <- as.character(tbl.out$chrom)
   tbl.out$start <- as.numeric(tbl.out$start)
   tbl.out$end <- as.numeric(tbl.out$end)

   return(tbl.out)

} # buildRegionsTable
#------------------------------------------------------------------------------------------------------------------------
test_buildRegionsTable <- function()
{
   library(RUnit)
   variables.loaded <- load("buildRegionsTable.sampleData.RData")
   stopifnot(all(c("chromosome", "start.loc", "end.loc", "tbl.dhs", "tbl.enhancers") %in% variables.loaded))
   intersection.options <- c("genehancer", "encodeDHS", "geneHancerOrEncode",
                             "geneHancerAndEncode", "allDNAForFootprints")

   tbl.regions <- buildRegionsTable("allDNAForFootprints", chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
   checkEquals(colnames(tbl.regions), c("chrom", "start", "end"))
   checkEquals(unlist(lapply(tbl.regions, class), use.names=FALSE), c("character", "numeric", "numeric"))
   checkEquals(dim(tbl.regions), c(1, 3))

   tbl.regions <- buildRegionsTable("genehancer", chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
   checkEquals(colnames(tbl.regions), c("chrom", "start", "end"))
   checkEquals(unlist(lapply(tbl.regions, class), use.names=FALSE), c("character", "numeric", "numeric"))
   checkEquals(dim(tbl.regions), c(32, 3))

   tbl.regions <- buildRegionsTable("encodeDHS", chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
   checkEquals(colnames(tbl.regions), c("chrom", "start", "end"))
   checkEquals(unlist(lapply(tbl.regions, class), use.names=FALSE), c("character", "numeric", "numeric"))
   checkEquals(dim(tbl.regions), c(2541, 3))

   tbl.regions <- buildRegionsTable("geneHancerOrEncode", chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
   checkEquals(colnames(tbl.regions), c("chrom", "start", "end"))
   checkEquals(unlist(lapply(tbl.regions, class), use.names=FALSE), c("character", "numeric", "numeric"))
   checkEquals(dim(tbl.regions), c(2573, 3))

   tbl.regions <- buildRegionsTable("geneHancerAndEncode", chromosome, start.loc, end.loc, tbl.enhancers, tbl.dhs)
   checkEquals(colnames(tbl.regions), c("chrom", "start", "end"))
   checkEquals(unlist(lapply(tbl.regions, class), use.names=FALSE), c("character", "numeric", "numeric"))
   checkEquals(dim(tbl.regions), c(341, 3))

} # test_buildRegionsTable
#------------------------------------------------------------------------------------------------------------------------
# beautify the data.frame, display it in the UI DataTable, update the modelSelector pulldown
displayModel <- function(session, input, output, tbl.model, new.model.name)
{
   printf("--- entering displayModel: %s (%d rows)", new.model.name, nrow(tbl.model))
   print(dim(tbl.model))
   tf.names <- tbl.model$gene
   tbl.model <- tbl.model[, -1]
   if("lassoPValue" %in% colnames(tbl.model))
       tbl.model <- roundNumericColumns(tbl.model, 4, "lassoPValue")
   rownames(tbl.model) <- tf.names
   max.model.rows <- MAX.TF.COUNT
   if(nrow(tbl.model) > max.model.rows)
      tbl.model <- tbl.model[1:max.model.rows,]

   output$table = DT::renderDataTable(tbl.model,
                                      width="800px",
                                      class='nowrap display',
                                      selection="single",
                                      extensions="FixedColumns",
                                      options=list(scrollX=TRUE,
                                                   scrollY="500px",
                                                   dom='t',
                                                   paging=FALSE,
                                                   autowWdth=FALSE,
                                                   fixedColumns=list(leftColumns=1)
                                                   ))

   updateSelectInput(session, "modelSelector",
                     choices=names(state$models),
                     selected=new.model.name)

} # displayModel
#------------------------------------------------------------------------------------------------------------------------
dispatch.rowClickInModelTable <- function(trenaProject, session, input, output, selectedTableRow)
{
      #current.model.name <- isolate(input$modelSelector)
      #if(current.model.name %in% ls(state$models)){
      #   printf("tf: %s", tf.name)

   current.model.name <- isolate(input$modelSelector)
   tf.names <- state$models[[current.model.name]]$model$gene
   if(length(tf.names) > MAX.TF.COUNT) tf.names <- tf.names[1:MAX.TF.COUNT]
   tf.name <- tf.names[selectedTableRow]
   action.name     <- isolate(input$selectRowAction)
   expression.matrix.name <- isolate(input$expressionSet)
   #printf("%s of model %s, expression.set %s: %s", tf.name, current.model.name, expression.matrix.name, action.name)
   xyz <- "botton of dispatch.rowClick"

   full.roi <- state$chromLocRegion
   chrom.loc <- trena::parseChromLocString(full.roi)

      #     "Motif matched regulatory regions",
      #     "Calculate Binding Sites",
      #     "ChIP-seq hits"))


   if(action.name == "Motif-matched regulatory regions"){
      tbl.motifs <- state$models[[current.model.name]]$regulatoryRegions
      tbl.motifs.std <- standardizeMotifMatchedTable(tbl.motifs)
      tbl.trimmed <-  subset(tbl.motifs.std, tf==tf.name)
      state$colorNumber <- (state$colorNumber %% totalColorCount) + 1
      next.color <- colors[state$colorNumber]
      loadBedTrack(session, sprintf("motif-%s", tf.name), tbl.trimmed, color=next.color, trackHeight=25)
      } # if footprints

   if(action.name == "Calculate Binding Sites"){
      displayPage(bsm, tf.name)
      } # if footprints

   if(action.name == "ChIP-seq hits"){
      if(is.null(state$tbl.chipSeq)){
         showNotification("retrieving ChIP-seq data from database...", duration=10, closeButton=TRUE)
         tbl.chipSeq <- with(chrom.loc, getChipSeq(trenaProject, chrom, start, end,  tf.names))
         #save(tbl.chipSeq, file="tbl.chipSeq.RData")
         state$tbl.chipSeq <- tbl.chipSeq
         hit.count <- nrow(state$tbl.chipSeq)
         printf("chipSeq hit.count: %d", hit.count)
         showNotification(sprintf("ChIP-seq hits across all TFs in this model: %d", hit.count))
         }
      tbl.hits <- subset(state$tbl.chipSeq, tf == tf.name)
      showNotification(sprintf("ChIP-seq hits for %s: %d", tf.name, nrow(tbl.hits)), type="message")
      if(nrow(tbl.hits) > 0){
         tbl.tmp <- tbl.hits[, c("chrom", "start", "endpos", "name")]
         colnames(tbl.tmp) <- c("chrom", "start", "end", "name")
         state$colorNumber <- (state$colorNumber %% totalColorCount) + 1
         next.color <- colors[state$colorNumber]
         loadBedTrack(session, sprintf("Cs-%s", tf.name), tbl.tmp, color=next.color, trackHeight=25)
         }
      } # ChIP-seq hits

} # dispatch.rowClickInModelTable
#------------------------------------------------------------------------------------------------------------------------
display.chipseq.track <- function(session, input, output, tf)
{

} # display.chipseq.track
#------------------------------------------------------------------------------------------------------------------------
display.footprint.track <- function(session, input, output, tf)
{
   model.name <- isolate(input$modelSelector)

} # display.footprint.track
#------------------------------------------------------------------------------------------------------------------------
loadAndDisplayRelevantVariants <- function(trenaProject, session, newGene)
{
   variant.filenames <- getVariantDatasetNames(trenaProject)
   short.names <- names(variant.filenames)
   file.paths <- unlist(variant.filenames, use.names=FALSE)
   vcf.file.indices <- grep(".vcf", short.names, ignore.case=TRUE)
   thisGene.indices <- grep(newGene, short.names, ignore.case=TRUE)
   final.indices <- intersect(vcf.file.indices, thisGene.indices)

   if(length(final.indices) == 0)
      return()

   current.gene.vcf.files <- file.paths[final.indices]
   for(i in seq_len(length(current.gene.vcf.files))){
      vcfFile <- current.gene.vcf.files[i]
      vcfData <- readVcf(vcfFile)
      loadVcfTrack(session, "vcf", vcfData)
      }

} # loadAndDisplayRelevantVariants
#------------------------------------------------------------------------------------------------------------------------
setupDisplayMotifs <- function(trenaProject, session, input, output)
{
  observeEvent(input$displayMotifButton2, ignoreInit=TRUE, {
     output$motifRenderingPanel2 <- renderPlot({
        pwm <- query(MotifDb, "MA0048.2", "jaspar2018")[[1]]
        lyl1.motifs <- geneToMotif(MotifDb, "LYL1", source="TFClass")$motif
        xx <- head(lyl1.motifs, n=8)
        x <- lapply(xx, function(motif) query(MotifDb, motif)[[1]])
        names(x) <- xx
        ggseqlogo(x, ncol=4)
        #ggseqlogo(pwm)
        #tbl <- data.frame(x=runif(10), y=runif(10))
        #ggplot(tbl, aes(x=x, y=y)) + geom_point()
        })
     })

  #output$motifPlotRenderingPanel <- renderPlot({
  #   input$displayMotifButton
  #   ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
  #   })

}
#------------------------------------------------------------------------------------------------------------------------
bindingSitesOptionsDialog <- function(tf.name)
{
   lyl1.motifs <- geneToMotif(MotifDb, "LYL1", source="TFClass")$motif
   xx <- head(lyl1.motifs, n=8)
   x <- lapply(xx, function(motif) query(MotifDb, motif)[[1]])
   names(x) <- xx
   ggseqlogo(x, ncol=4)

   modalDialog("myTitle", mainPanel(
                             actionButton(inputId = "displayMotifButton2", label = "Display Motif"),
                             h3("fu"),
                             h5("bar"),
                             plotOutput("motifRenderingPanel2"),
                             "my message"))

} # bindingSitesOptionsDialog
#------------------------------------------------------------------------------------------------------------------------
