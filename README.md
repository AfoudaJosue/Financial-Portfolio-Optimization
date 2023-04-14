# **Application web R Shiny pour l'Analyse et l'Optimisation d'un portefeuille boursier**

Cette application peut être utilisée par les sociétés d'investissement et particuliers ayant un portefeuille d'actions en bourse. Elle leur sera utile pour l'analyse et l'optimisation de leur portefeuille. Grâce à cette application, les Gestionnaires de Portefeuille d'une société d'investissement pourront analyser efficacement les données des actifs à leur charge et prendre ainsi des décisions éclairées concernant leurs investissements. De plus, avec cette application ils pourront mieux conseiller leurs clients actuels et futurs.

**Il s'agit d'une application performante, dynamique, simple d'utilisation et qui présente toutes les fonctionnalités nécessaires pour la création, l'analyse et l'optimisation de portefeuille**.

Lien de l'application :  https://afoudajosue.shinyapps.io/financial-portfolio-analysis/

## Fonctionnalités de l'application

L'application contient les fonctionnalités ci-dessous :

-   **Possibilité pour l'utilisateur de choisir n'importe quel indice boursier entre le CAC40, le S&P500, le DAX, le FTSE100 et le Nikkei225** ;

-   **Possibilité pour l'utilisateur de choisir le nombre d'actifs constituant le portefeuille ainsi que le poids de chaque actif** ;

-   **Récupération des prix journaliers de clôture des Actions sur une période donnée et possibilité de les sauvegarder au format CSV** ;

-   **Affichage des statistiques (moyenne, médiane, quartiles, etc.) sur les prix de clôture** ;

-   **Graphiques de visualisation des prix de clôture (Histogrammes, graphique linéaire de chaque actif)** ;

-   **Calcul des Rendements journaliers de chaque Action et possibilité de les sauvegarder au format CSV** ;

-   **Affichage des statistiques (moyenne, médiane, quartiles, etc.) des Rendements** ;

-   **Visualisation des Rendements (Histogrammes et Graphiques linéaires)** ;

-   **Calcul et visualisation des corrélations (corrélation entre chaque paire d'actifs)** ;

-   **Graphiques de visualisation de l'évolution des paramètres *Beginning of Period* et *End of Period*** ;

-   **Agrégation des Rendements journaliers pour obtenir les Rendements moyens annuels, trimestriels, mensuels ou hebdomadaires et possibilité de les sauvegarder au format CSV** ;

-   **Calcul des rendements moyens annualisés mobiles, des volatilités annualisées mobiles, des ratio de sharpe annualisés mobiles et visualisation de leur évolution (l'utilisateur doit avoir la possibilité de choisir la taille de la fenêtre mobile. Cette taille sera exprimée en nombre de mois)** ;

-   **Calcul et Visualisation des *Drawdowns* (pertes potentielles)** ;

-   **Optimisation de portefeuille par différentes méthodes (*Mean-Variance Efficient* et *Imposing Constraints*)** ;

-   **Evaluation de l'optimisation**.

Pour réaliser cette application, je me suis basé sur mes connaissances du Trading ainsi que sur la documentation du package [PerformanceAnalytics](https://www.rdocumentation.org/packages/PerformanceAnalytics) de R.

**N.B : Le package *PerformanceAnalytics* a été créé par deux célèbres Analystes quantitatifs américains [Peter Carl](https://scholar.google.com/citations?user=GL56hbwAAAAJ&hl=en) et [Brian Peterson](https://scholar.google.com/citations?user=A7qyE_IAAAAJ&hl=fr)**.

Dans les lignes qui suivent, je vous explique les différentes phases ayant conduit à la création de l'application.

# Analyse de Portefeuille avec R

Cette section est capitale pour la création de l'application. En effet, après avoir lu cette section, vous serez capables :

-   de récupérer des données boursières sur Yahoo Finance (<https://fr.finance.yahoo.com>) ;

-   d'analyser ces données (Statistiques et Visualisation) ;

-   de calculer les rendements, de les analyser (statistiques et visualisation) et de les agréger ;

-   de réaliser une analyse de performance d'un portefeuille ;

-   de réaliser une optimisation de portefeuille ;

-   d'évaluer votre optimisation.

Importons d'abord les packages nécessaires :

```{r}
library(PerformanceAnalytics)
library(quantmod)
library(tseries)
```

## Importation et analyse des données boursières dans R

### Importation des données

Avant de faire n'importe quelle analyse, il faut forcément importer préalablement les données. Ce paragraphe est basé sur ma vidéo YouTube ci-contre : <https://www.youtube.com/watch?v=Kbk5Ivrlh2g>

Ci-dessous le code pour récupérer par exemple les prix de clôture de Google, Amazon, Apple, Microsoft et IBM pour la période allant du 1er janvier 2015 au 1er janvier 2020 :

```{r}
# Importation des données de plusieurs titres

stocks <- new.env()

stocks_names <- c("GOOG", "AMZN", "AAPL", "MSFT", "IBM")

getSymbols(stocks_names, 
           env = stocks, 
           from = as.Date('2015-01-01'), 
           to = as.Date('2020-01-01'))

# Extraction des prix de clôture de chaque titre pour en former un seul ensemble de données au format xts

close_prices <- do.call(merge, lapply(stocks, Cl))

# Affichage des premières observations

head(close_prices)
```

### Statistiques et Histogrammes des prix de clôture

Vous pouvez aussi calculer des statistiques récapitulatives et tracer des graphiques.

```{r}
# Statistiques des prix de clôture

summary(close_prices)
```

Voyons maintenant comment construire les histogrammes des prix de clôture de chaque actif. Vous connaissez certainement plusieurs manières plus ou moins simples pour construire un histogramme dans R. Je vais vous montrer comment utiliser la fonction [chart.Histogram](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/1.5.2/topics/chart.Histogram) pour contruire un histogramme :

```{r}
# Construction de l'histogramme des prix de clôture de Microsoft

chart.Histogram(close_prices[, 'MSFT.Close'], 
                xlab = 'Prix de clôture',
                main = 'Histogramme des prix de clôture de Microsoft')
```

Avec une boucle *for*, construisons les histogrammes des prix de clôture pour tous les stocks.

```{r histograms prices all stocks}
# Histogrammes des prix de tous les stocks

par(mfrow = c(2, 3))

for (i in 1:ncol(close_prices)) {
  chart.Histogram(close_prices[, i], 
                  xlab = 'Prix de clôture')
}
```

### Evolution des prix de clôture au cours du temps

Traçons maintenant un graphique représentant l'évolution des prix de clôture. Vous pouvez le faire simplement en utilisant la fonction [plot.zoo](https://www.rdocumentation.org/packages/zoo/versions/1.8-8/topics/plot.zoo) :

```{r}
# Prix de clôture au cours du temps

plot.zoo(close_prices, 
         main = 'Evolution des prix de clôture', 
         col = 1:ncol(close_prices))
```

## Rendements

### Calcul des rendements journaliers

Il existe plusieurs types de rendements et donc plusieurs façons de les calculer. L'objectif ici n'est pas de vous gaver de toutes les théories relatives au concept de rendement. Pour faire simple, pour calculer le rendement d'un actif entre hier et aujourd'hui, il faut faire le prix d'aujourd'hui moins le prix d'hier divisé par le prix d'hier. La fonction [Return.calculate](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/2.0.4/topics/Return.calculate) vous permet de calculer facilement les rendements :

```{r}
# Calcul des rendements journaliers de chaque stock

stocks_daily_returns <- Return.calculate(close_prices)

head(stocks_daily_returns)
```

Vous remarquez que la première ligne des données obtenues consiste en des valeurs manquantes (*NA*). Ceci est tout à fait normal (voir définition du rendement ci-dessus) car pour la première date, il n'y a pas de prix antérieur disponible à comparer avec le prix actuel. Nous pouvons donc supprimer cette première ligne.

```{r}
# Suppression de la première ligne

stocks_daily_returns <- stocks_daily_returns[-1]

head(stocks_daily_returns)
```

### Création d'un portefeuille et calcul de ses rendements

Supposons qu'on veuille créer un portefeuille à pondération égale c'est-à-dire que tous les actifs ont le même poids. Sachant qu'il y a 5 actifs (Google, Amazon, Apple, Microsoft et IBM), le poids d'un actif sera égal à `1/5`.

Vous pouvez calculer les rendements journaliers de ce portefeuille en utilisant la fonction [Return.portfolio](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/2.0.4/topics/Return.portfolio) :

```{r}
# Calcul des rendements du portefeuille à pondération égale

portfolio <- Return.portfolio(stocks_daily_returns, 
                             weights = c(1/5, 1/5, 1/5, 1/5, 1/5), 
                             rebalance_on = NA, 
                             verbose = TRUE)

# Affichage

head(portfolio$returns)
```

En mettant `verbose = TRUE`, cela vous permet d'avoir une liste `portfolio` de plusieurs résultats dont les rendements du portefeuille (`portfolio$returns`).

L'argument `rebalance_on` est très important car il permet de définir à quelle fréquence le portefeuille sera rééquilibré. **Au niveau de l'application, l'utilisateur doit avoir le contrôle sur cet argument**.

Fusionnons les objets `stocks_daily_returns` et `portfolio$returns` pour en former un seul objet `returns` :

```{r}
# Fusion des rendements de stocks et du portefeuille

returns <- merge(stocks_daily_returns, portfolio$returns)

head(returns)
```

### Statistiques et Histogrammes des rendements

```{r}
# Résumé statistique des rendements

summary(returns)
```

Avec une boucle *for*, construisons les histogrammes des rendements des stocks et de ceux du portefeuille :

```{r}
# Histogramme des rendements des stocks et de ceux du portefeuille

par(mfrow = c(2, 3))

for (i in 1:ncol(returns)) {
  
  chart.Histogram(returns[, i])
  
}
```

### Evolution des rendements

Construisons un graphique montrant l'évolution des rendements des actifs et ceux du portefeuille :

```{r}
# Evolution des rendements des stocks et ceux du portefeuille

plot.zoo(returns, 
         main = 'Rendements des Stocks et du Portefeuille', 
         col = 1:ncol(returns) + 1)
```

### *Beginning of Period (BOP)* et *End of Period (EOP)*

-   ***Beginning of Period (BOP)*** : c'est le poids de début de période pour chaque actif. Le poids BOP d'un actif est calculé en utilisant les poids d'entrée (ou les poids supposés) et les paramètres de rééquilibrage donnés. Le poids BOP de la période suivante est soit les poids EOP (voir ci-dessous) de la période précédente, soit les poids d'entrée donnés sur une période de rééquilibrage.

-   ***End of Period (EOP)*** : c'est le poids de fin de période pour chaque actif. La valeur BOP de chaque actif est la valeur EOP de l'actif de la période précédente, sauf en cas de rééquilibrage. En cas d'événement de rééquilibrage, la valeur BOP de l'actif correspond au poids de rééquilibrage multiplié par la valeur EOP du portefeuille. Cela fournit effectivement un changement de coût de transaction nulle aux valeurs de position à compter de cette date pour refléter le rééquilibrage. Notez que la somme des valeurs BOP des actifs est la même que la valeur du portefeuille EOP de la période précédente.

Ci-dessous, comment calculer ces deux paramètres :

```{r}
# Evolution des BOP

plot.zoo(portfolio$BOP.Weight, 
         main = 'BOP.Weight', 
         col = 1:ncol(stocks_daily_returns))
```

```{r}
# Evolution des EOP

plot.zoo(portfolio$EOP.Weight, 
         main = 'EOP.Weight', 
         col = 1:ncol(stocks_daily_returns))
```

### Rendements moyens agrégés

Les fonctions [apply.yearly](https://www.rdocumentation.org/packages/rts/versions/1.0-49/topics/apply.monthly), [apply.quarterly](https://www.rdocumentation.org/packages/rts/versions/1.0-49/topics/apply.monthly), [apply.monthly](https://www.rdocumentation.org/packages/rts/versions/1.0-49/topics/apply.monthly) et [apply.weekly](https://www.rdocumentation.org/packages/rts/versions/1.0-49/topics/apply.monthly) permettent d'agréger les données.

Par exemple, pour calculer les rendements moyens mensuels du portefeuille :

```{r}
# Rendements moyens mensuels du portefeuille

pf_monthly_returns <- apply.monthly(portfolio$returns, mean)

head(pf_monthly_returns)
```

```{r}
# Evolution au cours du temps des rendements moyens mensuels

plot(pf_monthly_returns, 
     main = "Rendements moyens mensuels du portefeuille")

addLegend("topleft", on=1, lty = 1, 
          legend.names = colnames(pf_monthly_returns))
```

Vous pouvez de la même manière calculer et visualiser les rendement moyens agrégés mensuellement, trimestriellement et hebdomadaires.

## Analyse de performance

### Corrélation entre les rendements des actifs

La corrélation entre les actifs est très importante et a des conséquences importantes sur la performance globale du portefeuille.

Vous pouvez calculer et visualiser les corrélations entre actifs en utilisant la fonction [chart.Correlation](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/2.0.4/topics/chart.Correlation).

```{r}
# Corrélation entre les rendements des actifs

chart.Correlation(stocks_daily_returns, 
                  histogram = FALSE)
```

### Moyenne, Ecart-type et Ratio de Sharpe annualisés mobiles des rendements

Toujours dans le cadre de l'analyse de la performance du portefeuille, vous devez calculer la moyenne annualisée mobile des rendements sur une période ainsi que l'écart-type (qui représente la volatilité) et le ratio de sharpe annualisés mobiles des rendements du portefeuille sur cette même période en utilisant la fonction [chart.RollingPerformance](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/2.0.4/topics/chart.RollingPerformance). Par exemple, pour une fenêtre de 12 mois :

```{r}
# Rendements moyens annualisés mobiles sur 12 mois

chart.RollingPerformance(R = pf_monthly_returns, 
                         width = 12,
                         FUN = "Return.annualized")
```

```{r}
# Ecart-type des Rendements annualisés mobiles sur 12 mois

chart.RollingPerformance(R = pf_monthly_returns, 
                         width = 12,
                         FUN = "StdDev.annualized")
```

```{r}
# Ratio de sharpe annualisés mobiles sur 12 mois

chart.RollingPerformance(R = pf_monthly_returns, 
                         width = 12,
                         FUN = "SharpeRatio.annualized")
```

### Calcul des pertes potentielles (*drawdowns*)

L'écart-type ou la variance mesure tous les écarts à la moyenne, aussi bien ceux à la hausse que ceux à la baisse. Mais ce qui inquiète les investisseurs, ce sont les pertes (rendements négatifs). Une bonne mesure du risque devrait donc se concentrer sur les pertes potentielles (*drawdowns*).

Vous pouvez visualiser l'évolution des *drawdowns* en utilisant la fonction [chart.Drawdown](https://www.rdocumentation.org/packages/PerformanceAnalytics/versions/1.5.2/topics/chart.Drawdown) :

```{r}
# Pertes potentielles du portefeuille

chart.Drawdown(pf_monthly_returns, 
               main = "Evolution des pertes potentielles du portefeuille")
```

## Optimisation du portefeuille

Il existe plusieurs méthodes de détermination des poids optimaux des actifs constituants un portefeuille.

### Portefeuille efficace de moyenne-variance

Un portefeuille efficace de moyenne-variance peut être obtenu comme solution de minimisation de la variance du portefeuille sous la contrainte que le rendement attendu du portefeuille est égal à un rendement cible. La fonction [portfolio.optim](https://www.rdocumentation.org/packages/tseries/versions/0.10-48/topics/portfolio.optim) permet de calculer les poids optimaux.

```{r}
# Portefeuille efficace de moyenne-variance

opt1 <- portfolio.optim(
  apply.monthly(stocks_daily_returns, mean)
  )

# Poids optimaux du portefeuille de moyenne-variance

w <- opt1$pw

names(w) <- colnames(stocks_daily_returns)

print(w)

# Diagramme à barre montrant les poids optimaux

barplot(w)
```

### Portefeuille à contraintes sur les poids

Les investisseurs sont souvent contraints par les valeurs maximales autorisées pour les pondérations du portefeuille. Ces contraintes peuvent en fait être un avantage. L'avantage d'une contrainte de pondération maximale est que le portefeuille ultérieur sera moins concentré sur certains actifs. Il y a cependant un inconvénient à cela. L'inconvénient est que le même rendement cible peut ne plus être possible ou sera obtenu au détriment d'une volatilité plus élevée.

Dans notre cas ici, le portefeuille est constitué de 5 *stocks*. Le gestionnaire peut décider que le poids d'un stock ne doit pas dépasser 0,3. Voici comment vous pouvez calculer ce portefeuille :

```{r}
# Vecteur de poids maximum

max_w <- rep(0.3, ncol(stocks_daily_returns))

# Portefeuille à contrainte sur les poids

opt2 <- portfolio.optim(
  apply.monthly(stocks_daily_returns, mean), 
  reshigh = max_w
  )

# Récupération des poids

w2 <- opt2$pw

names(w2) <- colnames(stocks_daily_returns)

w2

# Diagramme à barre montrant les poids optimaux

barplot(w2)
```

**Au niveau de l'application, j'ai donné le contrôle au gestionnaire de choisir la valeur maximale que doit avoir le poids d'un actif dans le portefeuille**.

### Echantillon d'estimation et Echantillon d'évaluation (*Backtest*)

A présent, je vais vous apprendre à utiliser l'analyse d'échantillons fractionnés pour évaluer de manière objective ce que pourraient être les performances futures du portefeuille optimisé. L'analyse par échantillon fractionné consiste à diviser l'échantillon de rendements historiques en deux parties : la première partie s'appelle échantillon d'estimation et la deuxième partie est l'échantillon d'évaluation (comme le *train/test* split en *Machine Learning*).

```{r}
# Echantillon d'estimation

returns_estim <- window(
  apply.monthly(stocks_daily_returns, mean), 
  start = '2015-01-01', 
  end = '2017-12-31'
  )

# Portefeuille calculé avec l'échantillon d'estimation

pf_estim <- portfolio.optim(returns_estim)

# Echantillon d'évaluation

returns_eval <- window(
  apply.monthly(stocks_daily_returns, mean), 
  start = '2018-01-31', 
  end = '2020-01-01'
  )

# Portefeuille calculé avec l'échantillon d'évaluation

pf_eval <- portfolio.optim(returns_eval)

# Visualisation de l'évaluation

plot(pf_estim$pw, pf_eval$pw, 
     xlab = "estimation portfolio weights", 
     ylab = "evaluation portfolio weights",
     main = 'Evaluation portfolio weights VS Estimation portfolio weights')

abline(a = 0, b = 1, lty = 3)
```

Si les pondérations des 2 portefeuilles (estimation et évaluation) sont identiques, elles doivent être sur la ligne de 45 degrés.

![](https://github.com/AfoudaJosue/Portfolio-R-Markdown/raw/main/images/mon_logo.jpg)

N'hésitez pas à me contacter pour vos projets en Data Science. Je me ferai le plaisir de vous accompagner : afouda.josue@gmail.com

Si vous voulez apprendre à développer aussi des applications web R Shiny, vous pouvez : 

* acheter mon livre intitulé [Développement Web en Data Science avec R Shiny sans HTML, CSS, PHP ni JavaScript](https://www.amazon.fr/gp/product/B095Q5HCTW/ref=dbs_a_def_rwt_hsch_vapi_tu00_p1_i3) disponible en version papier et format Kindle sur [Amazon](https://www.amazon.fr/Josu%25C3%25A9-AFOUDA/e/B08F17S1V8?ref=dbs_a_def_rwt_hsch_vu00_tkin_p1_i0)

* Lire gratuitement la version [html](https://rpubs.com/Josue90/RShiny_Afouda) de ce livre sur [RPubs](https://rpubs.com/Josue90/RShiny_Afouda)

* Regarder ma vidéo [YouTube](https://youtu.be/4XGI_ye0y4M) : [Formation R Shiny pour les débutants](https://youtu.be/4XGI_ye0y4M)
