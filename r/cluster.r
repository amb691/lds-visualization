require(RSQLite);
require(cluster);

debug <- TRUE;
# Open a sink for logging
sink("r/cluster.log");

# Data frames
#load("data/baa.ratios.rda"); # into variable `ratios`

if (debug) print('a');

# Contants
GRAPHS_DIR <- "public/graphs";

if (debug) print('b');

# Pre-processing
  # We assume that the first argument is the type of graph,
  # and all subsequent arguments are genes
args <- commandArgs();

graph_type <- "undefined";
gene <- "undefined";

clustersString <- c();

print("args:");
for (arg in args) {
  print(arg);
  splt <- strsplit(arg, "--");
  status <- sapply(splt, function (x) if (length(x) < 2) "custom");
  if (status == 'custom') {
    splt <- unlist(strsplit(arg, "="));
    key <- splt[1];
    val <- splt[2];
    if (key == 'graph') {
      graph_type <- val;
    } else if (key == 'clusters') {
      clustersString <- val;
    }
  }
}

if (debug) print('c');

# Main DB connection
dbDriver <- dbDriver("SQLite");

if (debug) print('d');

# SQL database info
sql.info.final_clusters <- "final_clusters.sqlite";
sql.info.final_clusters.data_frames_table <- "ba_ratios";
sql.info.final_clusters.clusters_table <- "k173";

if (debug) print('e');

# If > 0, limits the DB queries to a maximum number of genes
geneLimit <- 0;
sqlLimitAppend <- "";
if (geneLimit > 0) {
  sqlLimitAppend <- paste("LIMIT", geneLimit);
}

if (debug) print('r');

sqlClusterAppend <- "";
if (length(clustersString) > 0) {
  sqlClusterAppend <- paste("WHERE out IN (", clustersString, ")", sep="");
}


if (debug) print('s');

sql.clusters <- dbConnect(dbDriver, dbname = sql.info.final_clusters);


if (debug) print('t');

if (length(clustersString) > 0) {
  sql.clusters.ratios <- dbGetQuery(
    sql.clusters,
    paste("SELECT *
        FROM ba_ratios
        INNER JOIN k173
        ON ba_ratios.row_names=k173.row_names",
      sqlClusterAppend)
  );
} else {
  sql.clusters.ratios <- dbGetQuery(sql.clusters, paste("SELECT * FROM ba_ratios", sqlLimitAppend));
}
sql.clusters.ratios <- sql.clusters.ratios[-c(1,53,54)];


if (debug) print('z');

sql.clusters.k173 <- dbGetQuery(sql.clusters, paste("SELECT out FROM k173", sqlClusterAppend));
sql.clusters.k173 <- as.vector(as.matrix(sql.clusters.k173));

sql.clusters.ratios <- sql.clusters.ratios[-c(1,53,54)];

print(paste("Number of rows in `sql.clusters.ratios`:", nrow(sql.clusters.ratios)));
print(paste("Length of `sql.clusters.ratios`:", length(sql.clusters.ratios)));
print(paste("Number of rows in `sql.clusters.k173`:", nrow(sql.clusters.k173)));
print(paste("Length of `sql.clusters.k173`:", length(sql.clusters.k173)));
print(sql.clusters.k173);

gene <- "GBAA4059";
sql.dist_db <- dbConnect(dbDriver, dbname = paste('clusters/dist/', gene, '.sqlite', sep = ""));
sql.gene_dist <- dbGetQuery(sql.dist_db, "SELECT d FROM dist");

if (debug) print('f');

# Plot graph depending on what graph type was requested

graph_path <- paste(GRAPHS_DIR, '/', sep = "");
graph_filename <- paste(unclass(Sys.time()), '.png', sep = "");

png(paste(graph_path, graph_filename, sep = ""));

if (graph_type == 'silhouette') {

  pr173 <- clara(sql.gene_dist, 173);
  str(si <- silhouette(pr173));
  (ssi <- summary(si));
  plot(si);

} else if (graph_type == 'bivariate') {

  png(paste(graph_path, graph_filename, sep = ""));
  clusplot(sql.clusters.ratios, sql.clusters.k173);
  dev.off();

}  

dev.off();

sink();

print(paste("GRAPH_PRE", graph_filename, "GRAPH_POST", sep = ""));
