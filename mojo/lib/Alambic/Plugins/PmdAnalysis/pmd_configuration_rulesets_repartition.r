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

file.out <- paste( project.id, "_pmd_configuration_rulesets_repartition.svg", sep="")

priority.colours <- c("#CC0000", "#DD5500", "#EEAA00", "#FFCC66")

#project.id <- 'modeling.sirius'
pmd.rulesets <- read.csv(file=paste("", project.id, "_pmd_analysis_rulesets2.csv", sep=""), header=T)

svg(file.out, width=10, height=7)
ggplot(data=pmd.rulesets, aes(x=ruleset, y=ncc, fill=factor(priority))) +
  geom_bar(stat='identity') +
  scale_fill_manual(values=priority.colours) +
  guides(fill=guide_legend(reverse=T)) +
  labs(fill='Priority') +
  xlab("Rulesets") +
  ylab('Non-conformities') +
  theme(
    panel.background = element_rect(fill = "transparent",colour = NA),
    plot.background = element_rect(fill = "white",colour = NA))
dev.off()
