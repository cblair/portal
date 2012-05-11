Rprof(tmp <- tempfile())

is_prime <- function(i) {
	return(1)
	sleep(1.5)
}

y <- 7
sum <- 0
for(i in 1:y) {
	sum <- sum + is_prime(i)
}

print(sum)

y <- 7
sum <- 0
results <- lapply(1:y, is_prime)
print(results)
for(i in 1:length(results)) {
	sum <- sum + results[[i]][1]
}
print(sum)

stime <- proc.time()[3]
is_prime(5)
etime <- proc.time()[3]
runtime <- etime - stime
print(paste("Granularit (P) =", runtime))
print(proc.time()[3])

Rprof()
summaryRprof(tmp)
unlink(tmp)
q()

'''
require(snow)
c1 <- startCluster(4, type="MPI")

y <- 7
sum <- 0
results <- parLapply(c1, 1:y, is_prime)
print(results)
for(i in 1:length(results)) {
	sum <- sum + results[[i]][1]
}
print(sum)

stopCluster(c1)
'''
