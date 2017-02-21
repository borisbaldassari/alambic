
require(ggplot2)

variables <- commandArgs(trailingOnly=TRUE)
project.id <- variables[1]
plugin.id <- variables[2]

file.out <- paste( project.id, "_so_plot.svg", sep="")

file.csv = paste(project.id, '_so.csv', sep="")
project <- read.csv(file=file.csv, header=TRUE)

binary.colours <- c("#325d88", "#d9534f") # "#325d88" green = #3e9c1a)

project$c.date <- as.POSIXct(project$creation_date, origin="1970-01-01")

svg(file.out, width=18, height=7)
ggplot(project, aes(x=c.date, y=answer_count, fill=factor(!is_answered))) +
  geom_point(aes(size=score), shape=21, colour='black', alpha=0.5) +
  scale_size(range=c(1,30)) + 
  theme(
    panel.background=element_blank(),
    axis.line=element_line(colour='black')
  ) +
  ggtitle('Questions on StackOverflow across years') +
  xlab("Time") +
  ylab("Number of answers") +
  scale_fill_manual(values=binary.colours) +
  labs( fill="Has an accepted answer", size="Number of votes" ) +
  guides(fill=guide_legend(override.aes=list(size=5)))
dev.off()

