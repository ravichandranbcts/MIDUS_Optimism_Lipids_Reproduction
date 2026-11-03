.PHONY: all analysis report demo
all: analysis report
analysis:
	Rscript R/run_analysis.R
report:
	Rscript -e 'rmarkdown::render("PROJECT_REPORT.Rmd")'
demo:
	Rscript R/toy_example.R
