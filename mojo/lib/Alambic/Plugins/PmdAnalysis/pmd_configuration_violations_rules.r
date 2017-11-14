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

file.out <- paste( project.id, "_pmd_configuration_violations_rules.svg", sep="")

priority.colours <- c("#CC0000", "#DD5500", "#EEAA00", "#FFCC66")

pmd.violations <- read.csv(file=paste("", project.id, "_pmd_analysis_violations.csv", sep=""), header=T)

svg(file.out, width=14, height=8)
ggplot(data=pmd.violations, aes(x=reorder(Mnemo, vol), y=vol+1, fill=factor(priority))) +
  geom_bar(stat='identity') +
  scale_fill_manual(values=priority.colours) +
  scale_y_log10() +
  theme(axis.text.x = element_text(angle=60, hjust=1, vjust=1)) +
  xlab("") +
  ylab('Non-conformities') +
  geom_text(aes(label=vol), vjust=-0.2, size=3) +
  labs(fill='Priority') +
  theme(
    panel.background = element_rect(fill = "transparent", colour = NA),
    plot.background = element_rect(fill = "white", colour = NA)
  )
dev.off()
