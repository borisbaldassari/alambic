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

require(xts)
require(ggplot2)

variables <- commandArgs(trailingOnly=TRUE)
project.id <- variables[1]
plugin.id <- variables[2]

file.out <- paste( project.id, "_so_evolution.svg", sep="")

file.csv = paste("../../../../projects/", project.id, "/output/", project.id, '_so.csv', sep="")
project <- read.csv(file=file.csv, header=TRUE)

binary.colours <- c("#325d88", "#d9534f") # "#325d88" green = #3e9c1a)

project$c.date <- as.POSIXct(project$creation_date, origin="1970-01-01")
project$m.date <- as.POSIXct(project$last_activity_date, origin="1970-01-01")
project$url <- paste("http://stackoverflow.com/questions/", project$id, sep="")

project.xts <- xts(project[,c("answer_count", "is_answered", "url", "title", "c.date", "m.date", "score", "views")], project$c.date)


project.xts.yearly.answered <- data.frame(
  apply.yearly(x=project.xts[project.xts$is_answered != 0,], FUN=nrow),
  "Accepted answer"
)
project.xts.yearly.answered$year <- as.Date(rownames(project.xts.yearly.answered))
names(project.xts.yearly.answered) <- c("question", "type")

project.xts.yearly.notanswered <- data.frame(
  apply.yearly(x=project.xts[project.xts$is_answered == 0,], FUN=nrow),
  "No accepted answer"
)
project.xts.yearly.notanswered$year <- as.Date(rownames(project.xts.yearly.notanswered))
names(project.xts.yearly.notanswered) <- c("question", "type")

project.xts.yearly <- rbind(project.xts.yearly.answered, project.xts.yearly.notanswered)

myplot.yearly <- data.frame(as.Date(paste(format(as.Date(rownames(project.xts.yearly)), format="%Y"), "-01-01", sep="")),
                            coredata(project.xts.yearly))

names(myplot.yearly) <- c("date", "vol", "type")

svg(file.out, width=10, height=6)
ggplot(myplot.yearly, aes(x=date, y=vol, fill=type)) +
  geom_bar(stat='identity', colour='black', size=0.5) +
  theme(
    panel.background=element_blank(),
    axis.line=element_line(colour='black')
  ) +
  ggtitle(paste('Number of', project.id, 'questions on StackOverflow')) +
  xlab("Years") +
  ylab("Number of Questions") +
  #geom_text(aes(label=vol), vjust=-0.2, size=3) +
  guides(fill=guide_legend(reverse=T)) +
  scale_fill_manual(values=binary.colours)
dev.off()
