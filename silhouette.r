> library(cluster)
> library(RSQLite)
> dbFile <- "GBAA0001.sqlite"
>   conin<<- dbConnect(dbDriver("SQLite"), dbname = dbFile)
> 
> clstr <- dbReadTable(conin, "dist")
> disdf <- dbGetQuery(conin, "select d from dist")
> pr173 <- clara(disdf,173)
> str(si <- silhouette(pr173))
> (ssi <- summary(si))
> plot (si)