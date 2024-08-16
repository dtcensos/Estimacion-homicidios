# ============================================
# Autora:     Maria Juliana Duran
# Dependencia: DCD
# Maintainer: 
# Dependencia: 
# Versión R:   4.3.0
# ============================================

# ----- setup
library(pacman)
pacman::p_load(here, dplyr, arrow, argparse, ggplot2, purrr)

parser <- ArgumentParser()
parser$add_argument("--estimaciones",
                    default = here::here("input/estimaciones"))
parser$add_argument("--output",
                    default = here::here("output/final.parquet"))

args <- parser$parse_args()

# ----------- main

estimacion <- read_parquet(args$estimaciones)

estimacion <- estimacion %>% 
  mutate(stratum_name = paste(pull(stratum_name, 1),
                              pull(stratum_name, 2),
                              pull(stratum_name, 3),
                              pull(stratum_name, 4),
                              pull(stratum_name, 5),
                              sep = "-")) %>% 
  separate(stratum_name, into = c("replica", "quinquenio", "edad_categoria", "sexo", "dept_code_hecho"), 
           sep = "-", remove = FALSE, extra = "merge") %>% 
  rename(replicate = replica) %>% 
  select(validated, N, valid_sources, n_obs, stratum_name, replicate, quinquenio, edad_categoria, sexo, dept_code_hecho)

arreglo <- estimacion %>% 
  mutate(edad_categoria = paste(edad_categoria, "-", sexo)) %>% 
  select(-sexo) %>% 
  separate(dept_code_hecho, c("sexo", "dpto"), sep = "-")

tabla_sampler <- arreglo %>%
  group_by(stratum_name, replicate) %>% 
  mutate(sample_number = glue::glue("sample_{row_number()}")) %>% 
  pivot_wider(id_cols = c("replicate", "stratum_name", "n_obs"),
              values_from = N,
              names_from = sample_number) 

grupo <- tabla_sampler %>%
  pivot_longer(starts_with("sample_"), 
               names_to = "replicate_num", 
               values_to = "N") %>%
  ungroup() %>%
  select(-replicate_num)

final_agrupacion <- grupo %>%
  group_by(stratum_name) 

estimates_tabla_sexo <- final_agrupacion %>%
  group_split() %>%
  map_dfr(.f = verdata::combine_estimates) %>% 
  mutate(est_lo_p = round(N_025/sum(N_mean), digits = 2)) %>%
  mutate(est_lo_p = ifelse(est_lo_p < 0, 0, est_lo_p)) %>%
  mutate(est_mn_p = round(N_mean/sum(N_mean), digits = 2)) %>%
  mutate(est_hi_p = round(N_975/sum(N_mean), digits = 2)) %>%
  mutate(est_hi_p = ifelse(est_hi_p > 1, 1, est_hi_p)) %>% 
  bind_cols(group_keys(final_agrupacion))

tabla_grafica <- arreglo %>% 
  filter(replicate == "R1") %>% 
  filter(stratum_name == "R1-1985_1989-0-4-HOMBRE-5") 

tabla_grafica %>% 
  ggplot() +
  geom_density(aes(x = N), color = "black") +
  theme_minimal() 

ggsave("~/Desktop/densidad.jpeg")

