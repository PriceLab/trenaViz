library(RUnit)
library(TrenaViz)
#------------------------------------------------------------------------------------------------------------------------
# cribbed from trena/inst/unitTests/test_MotifMatcher.R
#    jaspar.human.pfms <- as.list(query (query(MotifDb, "sapiens"), "jaspar2016"))
#    motifMatcher <- MotifMatcher(genomeName="hg38", pfms=jaspar.human.pfms, quiet=TRUE)
tbl.regions <- data.frame(chrom=rep("chr2",2),
                          start=c(88874736, 88879024),
                            end=c(88876958, 88880191),
                          stringsAsFactors=FALSE)
motif <- as.list(query(MotifDb, c("NFE2", "sapiens"), "hocomoco"))[1]
m4.biostrings <- MultiMethodMotifMatcher("hg38", motif, tbl.regions, "Biostrings matchPWM", .9)
m4.moods <- MultiMethodMotifMatcher("hg38", motif, tbl.regions, "MOODS matchMotifs", 4)
#------------------------------------------------------------------------------------------------------------------------
demo_trenaMotifMatcher <- function()
{
   library(trena)
   motifs <- query(MotifDb, "sapiens", "jaspar2018")
   motif <- query(MotifDb, c("NFE2", "sapiens"), "hocomoco")
   mm <- MotifMatcher(genomeName="hg38", as.list(motif), quiet=TRUE)
   tbl <-findMatchesByChromosomalRegion(mm, tbl.regions, pwmMatchMinimumAsPercentage=90)

} # demo_trenaMotifMatcher
#------------------------------------------------------------------------------------------------------------------------
demo_motifmatchr <- function()
{
   library(universalmotif)
   library(TFBSTools)
   library(motifmatchr)
   motif.tfbs <- convert_motifs(motif, "TFBSTools-PWMatrix")
   gr.regions <- GRanges(tbl.regions)
   tbl.hits <- as.data.frame(matchMotifs(motif.tfbs[[1]], gr.regions, genome="hg38", out="positions"))

} # demo_motifmatchr
#------------------------------------------------------------------------------------------------------------------------
runTests <- function()
{
   test_constructor()
   test_biostringsAlgorithm()
   test_moodsAlgorithm()
   test_both_MZF1_31kb()

   test_mouse()

} # runTests
#------------------------------------------------------------------------------------------------------------------------
test_constructor <- function()
{
   checkEquals(is(m4.biostrings), "MultiMethodMotifMatcher")

} # test_constructor
#------------------------------------------------------------------------------------------------------------------------
test_biostringsAlgorithm <- function()
{
   printf("--- test_biostringsAlgorithm")

   tbl.hits.b <- matchMotifInSequence(m4.biostrings)
   checkEquals(nrow(tbl.hits.b), 1)
   checkEquals(tbl.hits.b$chrom, "chr2")
   checkEquals(tbl.hits.b$start, 88875627)
   checkEquals(tbl.hits.b$end, 88875640)
   checkEquals(tbl.hits.b$width, 14)
   checkEquals(tbl.hits.b$strand, "+")
   checkTrue(tbl.hits.b$score > 9.5)


} # test_biostringsAlgorithm
#------------------------------------------------------------------------------------------------------------------------
test_moodsAlgorithm <- function()
{
   printf("--- test_moodsAlgorithm")

   tbl.hits.m <- matchMotifInSequence(m4.moods)
   dim(tbl.hits.m)
   checkEquals(nrow(tbl.hits.m), 1)
   checkEquals(tbl.hits.m$chrom, "chr2")
   checkEquals(tbl.hits.m$start, 88875627)
   checkEquals(tbl.hits.m$end, 88875640)
   checkEquals(tbl.hits.m$width, 14)
   checkEquals(tbl.hits.m$strand, "+")
   checkTrue(tbl.hits.m$score > 17)

} # test_moodsAlgorithm
#------------------------------------------------------------------------------------------------------------------------
test_both_MZF1_31kb <- function()
{
   printf("--- test_both_MZF1_31kb")
   tbl.regions <- data.frame(chrom="chr19", start=1036725, end=1068265, stringsAsFactors=FALSE)
   motif <- as.list(query(MotifDb, c("MZF1", "sapiens"), "hocomoco"))[1]
   m4.biostrings <- MultiMethodMotifMatcher("hg38", motif, tbl.regions, "Biostrings matchPWM", .9)
   m4.moods <- MultiMethodMotifMatcher("hg38", motif, tbl.regions, "MOODS matchMotifs", 4)

   tbl.hits.biostrings <- matchMotifInSequence(m4.biostrings)
   tbl.hits.moods <- matchMotifInSequence(m4.moods)
   checkTrue(nrow(tbl.hits.biostrings) > 50)
   checkTrue(nrow(tbl.hits.moods) < 20)
     # make sure that the moods matches are among the best reported by biostrings
   matched.starts <- base::match(tbl.hits.moods$start, tbl.hits.biostrings$start)
   checkTrue(length(matched.starts) < 20)

} # test_both_MZF1_31kb
#------------------------------------------------------------------------------------------------------------------------
test_mouse <- function()
{
   printf("--- test_mouse")
   runx1.mouse.hocomoco <- as.list(query(MotifDb, c("RUNX1", "musculus"), "hocomoco"))[1]

      # Mmusculus-HOCOMOCOv10-RUNX1_MOUSE.H10MO.B`

   tbl.regions <- data.frame(chrom="chr4", start=53158836, end=53160990, stringsAsFactors=FALSE)
       # chr4:53158836-53160990
   m4.1 <- MultiMethodMotifMatcher("mm10", runx1.mouse.hocomoco, tbl.regions, "Biostrings matchPWM", .9)
   tbl.bioc <- matchMotifInSequence(m4.1)
   checkEquals(dim(tbl.bioc), c(2,6))

   m4.2 <- MultiMethodMotifMatcher("mm10", runx1.mouse.hocomoco, tbl.regions, "MOODS matchMotifs", 4)
   tbl.mood <- matchMotifInSequence(m4.2)
   checkEquals(dim(tbl.bioc), c(2,6))

   sigs.bioc <- sort(with(tbl.bioc, sprintf("%s:%d-%d", chrom, start, end)))
   sigs.mood <- sort(with(tbl.mood, sprintf("%s:%d-%d", chrom, start, end)))

   checkTrue(all(sigs.bioc == sigs.mood))  # "chr4:53159788-53159797" "chr4:53160752-53160761"

} # test_mouse
#------------------------------------------------------------------------------------------------------------------------
