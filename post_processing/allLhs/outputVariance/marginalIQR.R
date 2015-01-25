require(squash)
require(akima)
require(gplots)
joint = as.matrix(results[,c('space_infiltration_reduction','standard_report_legacy.total_electricity')])
X <- as.matrix(joint[, 1])
Y <- as.matrix(joint[, 2])
N <- length(joint)
xm <- mean(X)
sigx <- sd(X)
ym <- mean(Y)
sigy <- sd(Y)
rho <- cor(X, Y)
nx <- 60
ny <- 50
nxy <- nx * ny
xeval <- seq(min(X), max(X), length = nx)
yeval <- seq(min(Y), max(Y), length = ny)
xyeval <- matrix(0, nrow = nxy, ncol = 2)
k <- 0
for(j in 1:nx){
  for(i in 1:ny){
    k <- k + 1
    xyeval[k, 1] <- xeval[j]
    xyeval[k, 2] <- yeval[i]
  }
}
jpdf3 <- sm.density(joint, eval.points = xyeval, eval.grid = FALSE, display = "none")
zz3 = interp(xyeval[,1],xyeval[,2],jpdf3$estimate)
persp(zz3, ticktype = "simple", theta = 210, phi = 30, expand = 0.5, shade = 0.5,
      col = "cyan", ltheta = -30, xlab = "ParameterValue", ylab = "Electricity EUI", zlab = "PDF",
      main = "Non-Parametric PDF")
