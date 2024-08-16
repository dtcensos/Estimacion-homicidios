# ============================================
# Autora:     Maria Juliana Duran
# Dependencia: DCD
# Maintainer: 
# Dependencia: 
# Versión R:   4.3.0
# ============================================

# ----- setup
library(pacman)
pacman::p_load(dplyr, LCMCR, here, arrow, rlang, purrr, tidyr, verdata, stringr, ggplot2, argparse, readxl)

parser <- ArgumentParser()
parser$add_argument("--estimaciones",
                    default = here::here("input/estimaciones"))
parser$add_argument("--output",
                    default = here::here("output/"))

args <- parser$parse_args()

final <- read_parquet("~/Downloads/final.parquet")

final_arreglo <- final %>% 
  separate(stratum_name, into = c("quinquenio", "edad_categoria", "sexo", "dept_code_hecho"), 
           sep = "-", remove = FALSE, extra = "merge") %>% 
  mutate(edad_categoria = paste(edad_categoria, "-", sexo)) %>% 
  select(-sexo) %>% 
  separate(dept_code_hecho, c("sexo", "dpto"), sep = "-")

arreglo_dpto <- final_arreglo %>% 
  filter(is.na(dpto)) %>% 
  select(!dpto) %>% 
  rename(dpto = sexo) %>% 
  separate(edad_categoria, c("edad_categoria", "sexo"), sep = "- ") 

final <- rbind(final_arreglo, arreglo_dpto) %>% 
  filter(!is.na(dpto))
final$edad_categoria <- gsub(" ", "", final$edad_categoria)


writexl::write_xlsx(final, "~/Desktop/final.xlsx")

df <- as.data.frame(do.call(rbind, listas[["stratification_vars"]])) %>% 
  select(-replica) %>% 
  distinct() %>% 
  mutate(completo = "si") %>% 
  rename(dpto = dept_code_hecho)

df$dpto <- as.character(df$dpto)
df$sexo <- as.character(df$sexo)

joint <- left_join(df, final, by = c("quinquenio", "edad_categoria", "sexo", "dpto"))



faltantes <- joint %>% 
  filter(is.na(N_025)) %>% 
  mutate(stratum_name = paste(quinquenio,
                              edad_categoria,
                              sexo,
                              dpto,
                              sep = "-")) %>% 
  pull(stratum_name)


replicas <- verdata::read_replicates("~/Documents/verdata-parquet/homicidio",
                                     "homicidio", c(1:10))

replicas <- verdata::filter_standard_cev(replicas,
                                         "homicidio")


tabla_documentada <- verdata::summary_observed("homicidio",
                                               replicas, 
                                               strata_vars = c("quinquenio", "edad_categoria", "sexo", "dept_code_hecho"),
                                               conflict_filter = FALSE,
                                               forced_dis_filter = FALSE,
                                               edad_minors_filter = FALSE,
                                               include_props = TRUE)

tabla_combinada <- verdata::combine_replicates("homicidio",
                                               tabla_documentada,
                                               replicas, 
                                               strata_vars = c("quinquenio", "edad_categoria", "sexo", "dept_code_hecho"),
                                               conflict_filter = FALSE,
                                               forced_dis_filter = FALSE,
                                               edad_minors_filter = FALSE,
                                               include_props = TRUE) %>% 
  mutate(stratum_name = paste(quinquenio,
                              edad_categoria,
                              sexo,
                              dept_code_hecho,
                              sep = "-")) 

estimado <- joint %>% 
  filter(!is.na(N_025))

observado <- tabla_combinada %>% 
  mutate(esta = ifelse(stratum_name %in% faltantes, 1, 0)) %>% 
  filter(esta == 1) %>% 
  mutate(imp_lo = ifelse(is.na(imp_lo), imp_mean, imp_lo))

require(openxlsx)
list_of_datasets <- list("estimado" = estimado, "observado" = observado)
write.xlsx(list_of_datasets, file = "~/Desktop/estimacion_homicidios.xlsx")


xlsx::write.xlsx(estimado, file = "~/Desktop/estimacion_homicidios.xlsx", sheetName = "estimado", row.names=FALSE)
xlsx::write.xlsx(observado, file = "~/Desktop/estimacion_homicidios.xlsx", sheetName = "observado", append=TRUE, row.names=FALSE)






