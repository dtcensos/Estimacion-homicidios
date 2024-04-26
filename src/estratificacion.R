# ============================================
# Autora:     Maria Juliana Duran
# Dependencia: DCD
# Maintainer: 
# Dependencia: 
# Versión R:   4.3.0
# ============================================

# ----- setup
library(pacman)
pacman::p_load(dplyr, LCMCR, here, arrow, rlang, purrr, tidyr, verdata, stringr, ggplot2)

parser <- ArgumentParser()
parser$add_argument("--estimaciones",
                    default = here::here("input/estimaciones"))
parser$add_argument("--output",
                    default = here::here("output/"))

args <- parser$parse_args()

# --- Funciones

stratify <- function(replicate_data, schema) {
  
  schema_list <- unlist(str_split(schema, pattern = ","))
  
  grouped_data <- replicate_data %>%
    group_by(!!!syms(schema_list))
  
  stratification_vars <- grouped_data %>%
    group_keys() %>%
    group_by_all() %>%
    group_split()
  
  split_data <- grouped_data %>%
    group_split(.keep = FALSE)
  
  return(list(strata_data = split_data,
              stratification_vars = stratification_vars))
}

# --- Main

# Leyendo 10 primeras réplicas 
replicas <- verdata::read_replicates("~/Documents/verdata-parquet/homicidio", 
                                     "homicidio", 
                                     c(1:10))

# Creando nuevas variables, como quinquenio
replicas <- verdata::filter_standard_cev(replicas,
                                         "homicidio")
# Aplicando función stratify
schema <- ("replica,quinquenio,edad_categoria,sexo,dept_code_hecho")
listas <- stratify(replicas, schema)

# Tomando X estratos de las listas para hacer una prueba: esta parte del código 
# cambia dependiendo del computador que esté estimando.
stratum10 <- list(strata_data = listas[["strata_data"]][401:501], 
                  stratification_vars = listas[["stratification_vars"]][401:501])


# Estmación LCMCR
start <- Sys.time()
estimacion <- purrr::map2_dfr(.x = stratum10$strata_data,
                              .y = stratum10$stratification_vars,
                              .f = verdata::mse,
                              estimates_dir = "~/Documents/estimates")
finish <- Sys.time()
total_time <- round(finish - start, 2)

write_parquet(estimacion, paste(args$output, "401-501.parquet"))

# done
