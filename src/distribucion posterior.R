library(pacman)
pacman::p_load(arrow, dplyr, purrr, ggplot2)

# ------ Functions

# Leer estimaciones en una tabla
read_estimates <- function(path){
  datos <- read_parquet(path)
}

# Evaluar distribución posterior
distribucion <- function(estratos, bandwidth = "nrd0", threshold = 0.1){
  
  filtro <- agrupada %>% 
    filter(stratum_name == estratos) %>% 
    pull(N)
  
  # Calculate kernel density estimate
  density_est <- density(filtro, bw = bandwidth)
  
  # Find peaks in the density estimate
  peaks <- which(diff(sign(diff(density_est$y))) < 0 & density_est$y[-length(density_est$y)] > 0.03) + 1
  
  # Check the number of peaks
  num_peaks <- length(peaks)
  
  # Determine if distribution is unimodal based on threshold
  is_unimodal <- num_peaks <= 1
  
  # Output results
  cat("Number of peaks:", num_peaks, "\n")
  cat("Is distribution unimodal?", is_unimodal, "\n")
  
  # Return a list with plots and boolean value
  result_list <- is_unimodal
  
  return(result_list)
}

# ------ Main
files <- list.files(path = "~/Documents/distribucion", full.names = TRUE)
tabla <- map_dfr(files, read_estimates)

agrupada <- tabla %>% 
  mutate(stratum_name = paste(pull(stratum_name, 1),
                              pull(stratum_name, 2),
                              pull(stratum_name, 3),
                              pull(stratum_name, 4),
                              pull(stratum_name, 5),
                              sep = "-")) %>% 
  filter(validated == TRUE)

estratos <- as.vector(unique(agrupada$stratum_name))

result9 <- purrr::map(estratos, distribucion)
 

