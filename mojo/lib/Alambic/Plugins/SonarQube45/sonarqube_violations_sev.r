require(ggplot2)

variables <- commandArgs(trailingOnly=TRUE)
project.id <- variables[1]
plugin.id <- variables[2]

file.metrics <- paste("", project.id, "_sq_metrics.csv", sep="")
sq.metrics <- read.csv(file=file.metrics, header=T)

violations <- as.data.frame(t(sq.metrics[,c('SQ_VIOLATIONS_BLOCKER', 'SQ_VIOLATIONS_CRITICAL', 'SQ_VIOLATIONS_MAJOR', 'SQ_VIOLATIONS_MINOR', 'SQ_VIOLATIONS_INFO')]))
violations$names <- rownames(violations)
names(violations) <- c('Values', 'Severity')

file.out <- paste( project.id, "_sq_violations_repartitions.svg", sep="")

svg(file.out, width=10, height=8)
ggplot(violations, aes(x=reorder(Severity, Values), y=Values)) +
    geom_bar(stat='identity') +
    geom_text(aes(label=vol), vjust=-0.2, size=4) +
#    scale_fill_manual(values=priority.colours) +
    labs(fill='Priority') +
    xlab("") +
    ylab('Violations') +
    theme(
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "white",colour = NA),
        axis.text.x = element_text(angle=30, hjust=1, vjust=1, size=12))
dev.off()

