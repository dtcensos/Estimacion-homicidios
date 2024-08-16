

tabla <- read_excel("~/Downloads/observado.xlsx") %>% 
  rename(dpto = dept_code_hecho)

tabla <- tabla %>% 
  dplyr::mutate(quinquenio = dplyr::case_when(yy_hecho >= 1985 & yy_hecho <= 1989 ~ "1985_1989",
                                              yy_hecho >= 1990 & yy_hecho <= 1994 ~ "1990_1994",
                                              yy_hecho >= 1995 & yy_hecho <= 1999 ~ "1995_1999",
                                              yy_hecho >= 2000 & yy_hecho <= 2004 ~ "2000_2004",
                                              yy_hecho >= 2005 & yy_hecho <= 2009 ~ "2005_2009",
                                              yy_hecho >= 2010 & yy_hecho <= 2014 ~ "2010_2014",
                                              yy_hecho >= 2015 & yy_hecho <= 2019 ~ "2015_2019",
                                              TRUE ~ NA_character_)) %>%
  select(-observed, -imp_lo, -imp_hi) %>% 
  group_by(quinquenio, edad_categoria, sexo, dpto) %>% 
  mutate(total = sum(imp_mean)) %>% 
  mutate(pct = (imp_mean/total)*100)

estimacion <- read_excel("~/Downloads/estimacion_homicidios.xlsx")

final <- left_join(tabla, estimacion)

final <- final %>% 
  mutate(simple = round((N_mean*pct)/100,0)) %>% 
  mutate(n_025_simple = round((N_025*pct)/100,0)) %>% 
  mutate(n_975_simple = round((N_975*pct)/100,0)) %>% 
  filter(!is.na(sexo)) %>% 
  filter(!is.na(edad_categoria)) 

sin_na <- final %>% 
  filter(!is.na(simple))

con_na <- final %>% 
  filter(is.na(simple))

con_na <- con_na %>% 
  mutate(stratum_name = paste(yy_hecho,
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
                                               strata_vars = c("yy_hecho", "edad_categoria", "sexo", "dept_code_hecho"),
                                               conflict_filter = FALSE,
                                               forced_dis_filter = FALSE,
                                               edad_minors_filter = FALSE,
                                               include_props = FALSE)

tabla_combinada <- verdata::combine_replicates("homicidio",
                                               tabla_documentada,
                                               replicas, 
                                               strata_vars = c("yy_hecho", "edad_categoria", "sexo", "dept_code_hecho"),
                                               conflict_filter = FALSE,
                                               forced_dis_filter = FALSE,
                                               edad_minors_filter = FALSE,
                                               include_props = FALSE) %>% 
  mutate(stratum_name = paste(yy_hecho,
                              edad_categoria,
                              sexo,
                              dept_code_hecho,
                              sep = "-")) 

observado <- tabla_combinada %>% 
  filter(stratum_name %in% con_na) %>% 
  mutate(imp_lo = ifelse(is.na(imp_lo), imp_mean, imp_lo)) %>% 
  select(yy_hecho, edad_categoria, sexo, dept_code_hecho, imp_lo, imp_mean, imp_hi)

estimado <- sin_na %>% 
  select(yy_hecho, edad_categoria, sexo, dpto, n_025_simple, simple, n_975_simple) %>% 
  rename(N_025 = n_025_simple, N_mean = simple, N_975 = n_975_simple)

require(openxlsx)
list_of_datasets <- list("estimado" = estimado, "observado" = observado)
write.xlsx(list_of_datasets, file = "~/Desktop/estimacion_homicidios.xlsx")
  
  
  
