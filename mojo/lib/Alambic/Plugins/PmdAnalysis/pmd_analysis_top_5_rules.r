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

file.out <- paste(project.id, "_pmd_analysis_top_5_rules.svg", sep="")

priority.colours <- c("#CC0000", "#DD5500", "#EEAA00", "#FFCC66")

#project.id <- "modeling.sirius"
file.violations = paste("../../../../projects/", project.id, "/output/", project.id, "_pmd_analysis_violations.csv", sep="")
pmd.violations <- read.csv(file=file.violations, header=T)

myrules <- pmd.violations[pmd.violations$priority == 1 | pmd.violations$priority == 2,c(1,2,4)]
myrules5 <- head(myrules[order(myrules$vol),], n=5)

svg(file.out, width=10, height=8)
ggplot(myrules5, aes(x=reorder(Mnemo, vol), y=vol, fill=factor(priority))) +
    geom_bar(stat='identity') +
    geom_text(aes(label=vol), vjust=-0.2, size=4) +
    scale_fill_manual(values=priority.colours) +
    labs(fill='Priority') +
    xlab("") +
    ylab('Non-conformities') +
    theme(
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "white",colour = NA),
        axis.text.x = element_text(angle=30, hjust=1, vjust=1, size=12))
dev.off()

