# Standalone TOY (SIMULATED) example only; no MIDUS data and no published figures.
# The original paper does not provide an executable toy example.
set.seed(2013)
n <- 120
optimism <- pmin(30, pmax(6, round(rnorm(n, 24, 4.7))))
age <- round(runif(n, 35, 84))
sex <- rbinom(n, 1, .55)
hdl <- 50 + 1.2*as.numeric(scale(optimism)) - 5*sex + rnorm(n, 0, 17)
fit <- lm(hdl ~ scale(optimism) + age + sex)
cat("SIMULATED example only (not MIDUS or Boehm's reported result):\n")
print(summary(fit)$coefficients)
