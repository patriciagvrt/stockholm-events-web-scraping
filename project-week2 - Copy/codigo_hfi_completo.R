# ============================================================
# Assignment 2 — Human Freedom Index
# Pergunta: Are personal freedom and economic freedom
# distinct dimensions, or do they move together?
# EDA: PCA + Clustering (HCPC)
# ============================================================

# PASSO 1: Instalar pacotes (so uma vez na vida)
# install.packages(c("FactoMineR", "factoextra", "tidyverse"))

# PASSO 2: Carregar pacotes (toda sessao)
library(FactoMineR)   # para rodar PCA e HCPC
library(factoextra)   # para visualizar PCA e clusters
library(tidyverse)    # para manipulacao de dados

# ============================================================
# PASSO 3: Carregar o dataset
# IMPORTANTE: coloque o arquivo hfi2008_2016.csv na mesma
# pasta do seu script R, ou ajuste o caminho abaixo
# ============================================================
hfi <- read.csv("hfi2008_2016.csv", stringsAsFactors = FALSE)

# Explorar o dataset
dim(hfi)       # deve mostrar 1458 linhas x 123 colunas
names(hfi)     # lista todas as colunas
head(hfi, 3)   # primeiras 3 linhas

# ============================================================
# PASSO 4: Filtrar apenas 2016
# Assim cada linha = um pais (sem repeticao)
# ============================================================
hfi_2016 <- hfi %>%
  filter(year == 2016)

# Verificar: deve ter 162 paises
nrow(hfi_2016)

# ============================================================
# PASSO 5: Selecionar as variaveis para o PCA
#
# Estrategia: usamos as 10 variaveis-resumo principais
# (scores agregados por dominio) em vez das 100+ variaveis
# detalhadas. Isso e mais interpretavel e tem menos NAs.
#
# pf_ = personal freedom (liberdade pessoal)
# ef_ = economic freedom (liberdade economica)
# ============================================================
hfi_pca_data <- hfi_2016 %>%
  select(
    countries, region,
    # Liberdade pessoal — 5 dominios
    pf_rol,          # rule of law (estado de direito)
    pf_ss,           # security & safety (seguranca)
    pf_movement,     # freedom of movement (liberdade de movimento)
    pf_religion,     # freedom of religion (liberdade de religiao)
    pf_expression,   # freedom of expression (liberdade de expressao)
    pf_identity,     # identity & relationships (identidade)
    # Liberdade economica — 5 dominios
    ef_government,   # government size (tamanho do governo)
    ef_legal,        # legal system & property rights (sistema legal)
    ef_money,        # sound money (moeda estavel)
    ef_trade,        # freedom to trade (liberdade de comercio)
    ef_regulation    # regulation (regulacao)
  )

# Remover linhas com NAs (PCA nao aceita valores ausentes)
hfi_clean <- hfi_pca_data %>%
  filter(complete.cases(.))

# Verificar quantos paises sobraram
nrow(hfi_clean)  # deve ser ~159-162 paises

# Salvar nomes e regioes para usar nos graficos
country_names <- hfi_clean$countries
country_regions <- hfi_clean$region

# Manter so as colunas numericas para o PCA
hfi_num <- hfi_clean %>%
  select(-countries, -region)

# Definir nomes dos paises como rownames
rownames(hfi_num) <- country_names

# Confirmar estrutura final
dim(hfi_num)      # deve ser ~159 x 10
head(hfi_num)

# ============================================================
# PASSO 6: Rodar o PCA
#
# scale.unit = TRUE: padroniza todas as variaveis
# Isso e OBRIGATORIO quando as variaveis tem escalas diferentes
# graph = FALSE: nao gera graficos automaticos
# ============================================================
pca_res <- PCA(
  hfi_num,
  scale.unit = TRUE,
  graph = FALSE
)

# Ver eigenvalues e variancia explicada
# Coluna 1: eigenvalue | Coluna 2: % variancia | Coluna 3: % acumulada
pca_res$eig

# Resumo completo
summary(pca_res)

# ============================================================
# PASSO 7: Scree plot
# Pergunta: quantos componentes reter?
# ============================================================
fviz_eig(
  pca_res,
  addlabels = TRUE,    # mostra % em cada barra
  ncp = 10,            # mostra todos os 10 componentes
  main = "Scree Plot — Human Freedom Index (2016)"
)
# INTERPRETE: onde esta o "cotovelo"?
# Se PC1 + PC2 explicam >60%, reter 2 componentes e razoavel.

# ============================================================
# PASSO 8: Mapa das variaveis — Correlation Circle
# Esta e a figura mais importante para a sua pergunta!
# ============================================================
fviz_pca_var(
  pca_res,
  col.var = "contrib",     # colorir por contribuicao ao PCA
  gradient.cols = c("grey70", "steelblue", "red"),
  repel = TRUE,            # evita sobreposicao de labels
  main = "Variable Factor Map — Personal vs Economic Freedom"
)
# INTERPRETE:
# Se pf_ e ef_ apontam em direcoes diferentes = dimensoes distintas
# Se pf_ e ef_ apontam juntas = andam correlacionadas

# ============================================================
# PASSO 9: Graficos de contribuicao
# Quais variaveis definem PC1 e PC2?
# ============================================================

# Contribuicoes para PC1
fviz_contrib(
  pca_res,
  choice = "var",
  axes = 1,
  main = "Contributions to PC1"
)
# Variaveis acima da linha tracejada sao as que definem PC1

# Contribuicoes para PC2
fviz_contrib(
  pca_res,
  choice = "var",
  axes = 2,
  main = "Contributions to PC2"
)

# ============================================================
# PASSO 10: Mapa dos paises
# Onde cada pais fica no espaco PCA
# ============================================================
fviz_pca_ind(
  pca_res,
  label = "all",
  repel = TRUE,
  col.ind = "cos2",        # colorir por qualidade de representacao
  gradient.cols = c("grey70", "steelblue", "red"),
  main = "Countries in PCA Space (2016)"
)
# INTERPRETE:
# Paises proximos = perfis similares de liberdade
# Paises nos cantos = casos extremos

# ============================================================
# PASSO 11: Mapa colorido por REGIAO (variavel suplementar)
# Mostra se regioes geograficas se agrupam no espaco PCA
# ============================================================

# Converter regiao em fator
region_factor <- as.factor(country_regions)

fviz_pca_ind(
  pca_res,
  label = "none",          # sem labels individuais (muitos paises)
  habillage = region_factor, # colorir por regiao
  addEllipses = TRUE,      # elipses ao redor de cada regiao
  ellipse.level = 0.68,
  main = "Countries by Region in PCA Space"
)
# INTERPRETE: regioes distintas ficam em areas distintas do mapa?

# ============================================================
# PASSO 12: Biplot — paises e variaveis juntos
# ============================================================
fviz_pca_biplot(
  pca_res,
  label = "var",
  col.ind = "steelblue",
  col.var = "red",
  repel = TRUE,
  main = "PCA Biplot — Human Freedom Index"
)

# ============================================================
# PASSO 13: Extrair loadings para interpretar os eixos
# ============================================================

# Coordenadas das variaveis nos componentes (= loadings)
loadings <- as.data.frame(pca_res$var$coord)
print(round(loadings, 3))

# Identificar quais variaveis sao pf_ e quais sao ef_
loadings$tipo <- ifelse(grepl("^pf_", rownames(loadings)), "Personal Freedom", "Economic Freedom")
print(loadings[, c("Dim.1", "Dim.2", "tipo")])

# ============================================================
# PASSO 14: Clustering com HCPC
# (Hierarchical Clustering on Principal Components)
# ============================================================

# HCPC roda clustering diretamente no espaco PCA
# nb.clust = -1: numero de clusters escolhido automaticamente
hcpc_res <- HCPC(
  pca_res,
  nb.clust = -1,
  graph = FALSE
)

# ============================================================
# PASSO 15: Visualizar clusters
# ============================================================

# Paises coloridos por cluster no espaco PCA
fviz_cluster(
  hcpc_res,
  repel = TRUE,
  show.clust.cent = TRUE,
  main = "Country Clusters — Human Freedom Index"
)

# ============================================================
# PASSO 16: Explorar os clusters
# ============================================================

# Ver quais paises estao em cada cluster
cluster_data <- hcpc_res$data.clust %>%
  rownames_to_column("country") %>%
  mutate(region = country_regions[match(country, country_names)]) %>%
  select(country, region, clust) %>%
  arrange(clust)

print(cluster_data)

# Contar paises por cluster
table(hcpc_res$data.clust$clust)

# Medias de cada variavel por cluster
# USE ISSO para caracterizar os clusters no paper
cluster_means <- hcpc_res$data.clust %>%
  group_by(clust) %>%
  summarise(across(where(is.numeric), ~round(mean(.x, na.rm=TRUE), 2)))

print(cluster_means)

# Distribuicao de regioes por cluster
cluster_data %>%
  count(clust, region) %>%
  arrange(clust, desc(n)) %>%
  print(n = 50)

# ============================================================
# PASSO 17: Salvar graficos (opcional)
# Para incluir no paper em alta qualidade
# ============================================================

# Exemplo de como salvar um grafico:
# png("correlation_circle.png", width=800, height=700, res=120)
# fviz_pca_var(pca_res, col.var="contrib",
#              gradient.cols=c("grey70","steelblue","red"),
#              repel=TRUE, main="Variable Factor Map")
# dev.off()

# Faca isso para cada grafico que quiser incluir no paper.

# ============================================================
# FIM DO CODIGO
# ============================================================
