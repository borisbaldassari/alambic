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

variables <- commandArgs(trailingOnly=TRUE)
project.id <- variables[1]
plugin.id <- variables[2]

require(tm)
require(wordcloud)
require(SnowballC)

file.out <- paste( project.id, "_so_tm.svg", sep="")

file.csv = paste("../../../../projects/", project.id, "/output/", project.id, '_so.csv', sep="")
project <- read.csv(file=file.csv, header=TRUE)

test <- as.vector(project$title)
Encoding(test)  <- "UTF-8"
mysrc <- VectorSource(test)
corpus <- VCorpus(mysrc)
#mydict <- corpus

corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, content_transformer(removePunctuation))
corpus <- tm_map(corpus, content_transformer(removeNumbers))
corpus <- tm_map(corpus, removeWords, stopwords("english"))
a <- tm_map(corpus, stemDocument)
#a <- sapply(a, stemCompletion_mod, dict=mydict)[[1]]
#stemCompletion_mod(docs[[1]],dictCorpus)
#a <- tm_map(a, content_transformer(stemCompletion))

svg(file.out, width=10, height=6)
wordcloud(a, scale=c(12,1), max.words=50, random.order=FALSE, rot.per=0.15, use.r.layout=FALSE, colors=brewer.pal(8, "Dark2"))
dev.off()

