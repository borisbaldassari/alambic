#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

require(ggplot2)

variables <- commandArgs(trailingOnly=TRUE)
project.id <- variables[1]
plugin.id <- variables[2]

file.out <- paste(project.id, "_pmd_analysis_files_ncc1.svg", sep="")

priority.colours <- c("#CC0000", "#DD5500", "#EEAA00", "#FFCC66")

#project.id <- "modeling.sirius"
file.files = paste("../../../../projects/", project.id, "/output/", project.id, "_pmd_analysis_files.csv", sep="")
pmd.files <- read.csv(file=file.files, header=T)

pmd.files.list <- pmd.files[pmd.files$NCC_1 > 0 | pmd.files$NCC_2 > 0,c("File", "NCC_1", "NCC_2")]

mystr <- as.character(pmd.files.list$File)
pmd.files.list$File <- paste('. . ', substr(pmd.files.list[,1], start=nchar(mystr)-60, nchar(mystr)), sep="")
rm(mystr)


pmd.files.list$NCC_12 <- pmd.files.list$NCC_1 + pmd.files.list$NCC_2
pmd.files.list <- pmd.files.list[order(pmd.files.list$NCC_12, pmd.files.list$NCC_1, decreasing=T),-4]

pmd.files.list.50 <- head(pmd.files.list, n=50)

names(pmd.files.list.50) <- c("File", "NCC P1", "NCC P2")

pmd.files.list.30 <- head(pmd.files.list, n=30)
names(pmd.files.list.30) <- c("File", "NCC P1", "NCC P2")


pmd.files.ncc1 <- pmd.files.list.30[,c(1,2)]
pmd.files.ncc1$Priority <- 1
names(pmd.files.ncc1) <- c("File", "NCC", "Priority")

pmd.files.ncc2 <- pmd.files.list.30[,c(1,3)]
pmd.files.ncc2$Priority <- 2
names(pmd.files.ncc2) <- c("File", "NCC", "Priority")

pmd.files.ncc <- rbind(pmd.files.ncc1, pmd.files.ncc2)

myfiles <- lapply(
    X=as.vector(pmd.files.ncc$File),
    FUN=function(x) tail(gregexpr(pattern ='/', text=x)[[1]], n=1)
)
myfiles.stop <- lapply( X=as.vector(pmd.files.ncc$File), FUN=function(x) nchar(x) )
pmd.files.ncc$File <- paste("...", substr(pmd.files.ncc$File, start=myfiles, stop=myfiles.stop), sep="")

svg(file.out, width=14, height=8)
ggplot(pmd.files.ncc, aes(x=reorder(File, -NCC), y=NCC, fill=factor(Priority))) +
    geom_bar(stat="identity") +
    scale_fill_manual(values=priority.colours) +
    labs(fill='Priority') +
    xlab("Files") +
    ylab('Non-conformities') +
    theme(
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "white",colour = NA),
        axis.text.x = element_text(angle=30, hjust=1, vjust=1, size=11))
dev.off()

