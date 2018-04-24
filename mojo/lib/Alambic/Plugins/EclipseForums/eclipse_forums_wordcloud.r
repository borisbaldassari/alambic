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

file.out.svg <- paste( project.id, "_eclipse_forums_wordcloud.svg", sep="")
file.out.png <- paste( project.id, "_eclipse_forums_wordcloud.png", sep="")

file.csv = paste("../../../../projects/", project.id, "/output/", project.id, '_eclipse_forums_posts.csv', sep="")
posts <- read.csv(file=file.csv, header=TRUE)

posts.vector <- as.vector(posts$subject)
Encoding(posts.vector)  <- "UTF-8"
mysrc <- VectorSource(posts.vector)
corpus <- VCorpus(mysrc)

corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, content_transformer(removePunctuation))
corpus <- tm_map(corpus, content_transformer(removeNumbers))
corpus <- tm_map(corpus, removeWords, stopwords("english"))
a <- tm_map(corpus, stemDocument)

svg(file.out.svg, width=10, height=6)
wordcloud(a, scale=c(12,1), max.words=50, random.order=FALSE, rot.per=0.15, use.r.layout=FALSE, colors=brewer.pal(8, "Dark2"))
dev.off()


png(file.out.png, width=800, height=600)
wordcloud(a, scale=c(12,1), max.words=50, random.order=FALSE, rot.per=0.15, use.r.layout=FALSE, colors=brewer.pal(8, "Dark2"))
dev.off()

