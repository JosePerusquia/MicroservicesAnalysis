library(igraph)
library(fastDummies)
library(dplyr)
library(Matrix)

# Función para cargar las bases de datos desde una carpeta
base_de_datos <- function(nombre_carpeta) {
  # Obtener el directorio y los archivos dentro del mismo
  directorio <- nombre_carpeta 
  archivos <- list.files(directorio, full.names = TRUE)
  # Leer todos los archivos y almacenarlos en una lista
  datos_lista <- lapply(archivos, read.table, header = TRUE)
  return(datos_lista)
}

# Función principal para generar el reporte y las gráficas
report <- function(nombre_archivo_ejemplo, alpha = 0.95) {
  extension <- tools::file_ext(nombre_archivo_ejemplo)
  if (extension == "csv" || extension == "txt") {
    datos_lista <- base_de_datos("compose") # Eliminar carpeta, readme.txt, compose_AA170AA63ED6CFFD.txt
    services_sum <- unique(unlist(lapply(datos_lista, colnames)))
    
    # Asignar nombres de columnas como nombres de filas en cada matriz
    datos_lista <- lapply(datos_lista, function(matriz) {
      rownames(matriz) <- colnames(matriz)
      return(matriz)
    })
    
    # Crear una matriz de suma de datos
    matriz_suma <- matrix(0, nrow = length(services_sum), ncol = length(services_sum), dimnames = list(services_sum, services_sum))
    
    # Sumar los datos en matriz_suma
    for (nombre_fila in services_sum) {
      for (nombre_columna in services_sum) {
        suma_entradas <- sum(sapply(datos_lista, function(matriz) {
          if (nombre_fila %in% rownames(matriz) && nombre_columna %in% colnames(matriz)) {
            indice_fila <- which(rownames(matriz) == nombre_fila)
            indice_columna <- which(colnames(matriz) == nombre_columna)
            return(matriz[indice_fila, indice_columna])
          } else {
            return(0)
          }
        }))
        matriz_suma[nombre_fila, nombre_columna] <- suma_entradas
      }
    }
    
    # Procesar archivo CSV
    if (extension == "csv") {
      report <- read.csv(nombre_archivo_ejemplo)
      services <- unique(report$service)
      
      # Generar detalles del reporte con padres
      report_detailed1 <- merge(x = report[, c("id", "thread", "service", "parent1")],
                                y = report[, c("id", "thread", "service")],
                                by.x = "parent1",
                                by.y = "id",
                                suffixes = c("", "_parent"))
      
      report_detailed2 <- merge(x = report[, c("id", "thread", "service", "parent2")],
                                y = report[, c("id", "thread", "service")],
                                by.x = "parent2",
                                by.y = "id",
                                suffixes = c("", "_parent"))
      
      # Filtrar los detalles del reporte para remover hilos repetidos
      report_detailed1 <- report_detailed1[report_detailed1$thread != report_detailed1$thread_parent, ]
      report_detailed2 <- report_detailed2[report_detailed2$thread != report_detailed2$thread_parent, ]
      
      # Unir los detalles del reporte
      report_detailed <- rbind(report_detailed1[, c("id", "service", "service_parent")],
                               report_detailed2[, c("id", "service", "service_parent")])
      
      # Crear columnas dummy para matriz de adyacencia
      for_adjacency <- dummy_cols(report_detailed, select_columns = c("service_parent"))
      names(for_adjacency) <- sub("service_parent_", "", names(for_adjacency))
      
      # Generar la matriz de adyacencia
      adjacency <- for_adjacency %>% group_by(service) %>% summarise_if(is.numeric, sum)
      adjacency <- as.matrix(adjacency[, -1])
      
      # Crear una matriz cuadrada con ceros y pegar la matriz original
      matriz_cero <- matrix(0, nrow = length(services), ncol = length(services), dimnames = list(NULL, colnames(adjacency)))
      matriz_cero[1:nrow(adjacency), ] <- adjacency
      adjacency <- matriz_cero
      
      # Crear dataframe con tamaño de vertices
      services_size <- for_adjacency %>% group_by(service) %>% summarise(service_size = n())
      
    } else { # Procesar archivo TXT
      adjacency <- as.matrix(read.table(nombre_archivo_ejemplo, header = TRUE, sep = "\t"))
      row_sums <- rowSums(adjacency)
      services <- colnames(adjacency)
      services_size <- data.frame(service = services, service_size = row_sums)
    }
    
    # Configuración de las características del gráfico
    vertex_label_dist <- c() 
    self_edge_rotation <- c() 
    self_edge_rotation_sum <- c()
    self_edge_rotation_binom <- c()
    edge_label <- c() 
    edge_label_sum <- c()
    edge_label_prop <- c()
    edge_label_binom <- c()
    edge_curved_value <- c() 
    edge_curved_value_sum <- c()
    edge_curved_value_binom <- c()
    vertex_size <- as.matrix(services_size$service_size)[, 1] * 2
    rotation <- 0
    
    binom <- matrix(rep(colSums(adjacency), ncol(adjacency)), nrow = nrow(adjacency), byrow = TRUE)
    
    # Configuración de características de vértices y aristas
    for (i in 1:length(services)) {
      vertex_label_dist <- c(vertex_label_dist, 3 + 7 * vertex_size[i] / max(vertex_size))
      for (j in 1:length(services)) {
        if (adjacency[i, j] != 0) {
          if (i == j) {
            self_edge_rotation <- c(self_edge_rotation, - (i-1) * 2 * pi / length(services))
          } else {
            self_edge_rotation <- c(self_edge_rotation, 0)
          } 
          if (adjacency[i, j] > 1) {
            edge_curved_value <- c(edge_curved_value, 0.1)
            edge_label <- c(edge_label, adjacency[i, j])
          } else {
            edge_label <- c(edge_label, "")
            if (adjacency[j, i] > 1) {
              edge_curved_value <- c(edge_curved_value, 0.1)
            } else {
              edge_curved_value <- c(edge_curved_value, 0)
            }
          }
          adjacency_prop <- t(t(matriz_suma) / colSums(matriz_suma)) 
          adjacency_binom <- dbinom(adjacency, binom, adjacency_prop)
          edge_label_prop <- c(edge_label_prop, adjacency_prop[i, j])
        }
      }
    }
    
    # Configuración de la matriz de suma
    for (i in 1:length(services_sum)) {
      for (j in 1:length(services_sum)) {
        if (matriz_suma[i, j] != 0) {
          if (i == j) {
            self_edge_rotation_sum <- c(self_edge_rotation_sum, - (i-1) * 2 * pi / length(services_sum))
          } else {
            self_edge_rotation_sum <- c(self_edge_rotation_sum, 0)
          } 
          if (matriz_suma[i, j] > 1) {
            edge_curved_value_sum <- c(edge_curved_value_sum, 0.1)
            edge_label_sum <- c(edge_label_sum, matriz_suma[i, j])
          } else {
            edge_label_sum <- c(edge_label_sum, "")
            if (matriz_suma[j, i] > 1) {
              edge_curved_value_sum <- c(edge_curved_value_sum, 0.1)
            } else {
              edge_curved_value_sum <- c(edge_curved_value_sum, 0)
            }
          }
        }
      }
    }
    
    # Configuración de la matriz binomial
    for (i in 1:length(services_sum)) {
      for (j in 1:length(services_sum)) {
        if (i == j) {
          self_edge_rotation_binom <- c(self_edge_rotation_binom, - (i-1) * 2 * pi / length(services_sum))
        } else {
          self_edge_rotation_binom <- c(self_edge_rotation_binom, 0)
        }
        edge_curved_value_binom <- c(edge_curved_value_binom, 0.1)
        edge_label_binom <- c(edge_label_binom, adjacency_binom[i, j])
      }
    }
    
    # Función para rotar etiquetas de vértices
    radian.rescale <- function(x, start = 0, direction = 1) {
      c.rotate <- function(x) (x + start) %% (2 * pi) * direction
      c.rotate(scales::rescale(x, c(0, 2 * pi), range(x)))
    }
    
    lab.locs <- radian.rescale(x = 1:length(services), direction = -1, start = 0)
    
    binom_t <- t(binom)
    adjacency_prop_t <- t(adjacency_prop)
    adjacency_t <- t(adjacency)
    warn_low <- qbinom((1 - alpha) / 2, binom_t, adjacency_prop_t)
    warn_up <- qbinom((1 + alpha) / 2, binom_t, adjacency_prop_t)
    warn <- warn_low <= adjacency_t & adjacency_t <= warn_up
    
    # Generar gráfico con número de conexiones
    graph <- graph_from_adjacency_matrix(adjacency, mode = "directed", weighted = TRUE)
    plot(graph,
         vertex.size = vertex_size, 
         layout = layout.circle(graph),
         margin = 0, 
         edge.arrow.size = 0.15,
         edge.label.font = 2,
         edge.label.color = 'black',
         vertex.label.color = 'black',
         vertex.color = 'yellow',
         vertex.label.cex = 0.6,
         edge.label.cex = 0.7,
         vertex.label.dist = vertex_label_dist,
         edge.loop.angle = self_edge_rotation,
         edge.label = edge_label,
         edge.curved = edge_curved_value,
         vertex.label.degree = lab.locs,
         main = "Conexiones de los vértices",
         edge.color = ifelse(warn, "black", "red"))
    legend(-2.2, -0.7, legend = c("Anormal"), col = c("red"), lty = 1, lwd = 2, bty = "n")
    
    
    # Generar gráfico con probabilidades reales de conexión
    graph_prop <- graph_from_adjacency_matrix(adjacency_prop, mode = "directed", weighted = TRUE)
    plot(graph_prop,
         vertex.size = vertex_size, 
         layout = layout.circle(graph_prop),
         margin = 0, 
         edge.arrow.size = 0.15,
         edge.label.font = 2,
         edge.label.color = 'black',
         vertex.label.color = 'black',
         vertex.color = 'yellow',
         vertex.label.cex = 0.6,
         edge.label.cex = 0.7,
         vertex.label.dist = vertex_label_dist,
         edge.loop.angle = self_edge_rotation_sum,
         edge.label = round(edge_label_prop, 2),
         edge.curved = edge_curved_value_sum,
         vertex.label.degree = lab.locs,
         main = "Probabilidad real de éxito",
         edge.color = ifelse(warn, "black", "red"))
    par(plt = c(0.05, 0.9, 0.05, 0.8))
    mtext(paste("La probabilidad de este gráfico es de: (logarítmica)", sum(log(edge_label_prop))), side = 1, line = 0.8, adj = 0.5, cex = 0.8, font = 2)
    legend(-2.2, -0.7, legend = c("Anormal"), col = c("red"), lty = 1, lwd = 2, bty = "n")
    
    # Generar gráfico con probabilidades binomiales de conexión
    graph_binom <- graph_from_adjacency_matrix(adjacency_binom, mode = "directed", weighted = TRUE)
    color <- adjacency > 0
    plot(graph_binom,
         vertex.size = vertex_size, 
         layout = layout.circle(graph_binom),
         margin = 0, 
         edge.arrow.size = 0.15,
         edge.label.font = 2,
         edge.label.color = 'black',
         vertex.label.color = 'black',
         vertex.color = 'yellow',
         vertex.label.cex = 0.6,
         edge.label.cex = 0.7,
         vertex.label.dist = vertex_label_dist,
         edge.loop.angle = self_edge_rotation_binom,
         edge.label = round(edge_label_binom, 2),
         edge.curved = edge_curved_value_binom,
         vertex.label.degree = lab.locs,
         main = "Detector de anomalias por proba binomial",
         edge.color = ifelse(warn, ifelse(color,"blue","black"), "red"))
    par(plt = c(0.05, 0.9, 0.05, 0.8))
    mtext(paste("La probabilidad de este gráfico es de: (logarítmica)", sum(log(edge_label_binom))), side = 1, line = 0.8, adj = 0.5, cex = 0.8, font = 2)
    legend(-2.2, -0.7, legend = c("Anormal"), col = c("red"), lty = 1, lwd = 2, bty = "n")
    legend(-2.2, -0.9, legend = c("Conexión real"), col = c("blue"), lty = 1, lwd = 2, bty = "n")
    legend(-2.2, -1.1, legend = c("Conexión ficticia"), col = c("black"), lty = 1, lwd = 2, bty = "n")
    
    # Imprimir anomalías detectadas
    ubi_anomal <- which(!warn, arr.ind = TRUE)
    
    #Guardar anomalías
    detected_anomalies <- list()
    
    if (length(ubi_anomal) != 0) {
      x <- nrow(ubi_anomal)
      for (i in 1:x) {
        cat("La relación", services_sum[ubi_anomal[i, 1]], "->", services_sum[ubi_anomal[i, 2]], "es anormal, debería estar entre", warn_low[ubi_anomal[i, 1], ubi_anomal[i, 2]], "&", warn_up[ubi_anomal[i, 1], ubi_anomal[i, 2]], "relaciones pero tiene", adjacency[ubi_anomal[i, 1], ubi_anomal[i, 2]], "relaciones \n")
        detected_anomalies[[i]] <- c(services_sum[ubi_anomal[i, 1]], services_sum[ubi_anomal[i, 2]])
      }
    }
    return(detected_anomalies)
  } else {
    cat("Solo es compatible con archivos .csv y .txt")
  }
}

# Ejemplo de archivo prueba
example_file <- as.matrix(read.table("archivo_prueba.txt", header = TRUE, sep = "\t"))

# Definir las anomalías conocidas
known_anomalies <- list(c("ComposePostService", "ComposePostService"))

# Función para evaluar la precisión
evaluate_precision <- function(known_anomalies) {
  tp <- 0
  fp <- 0
  fn <- 0
  
  detected_anomalies <- report("archivo_prueba.txt")
  
  for (anomaly in detected_anomalies) {
    if (any(sapply(known_anomalies, function(x) all(x == anomaly)))) {
      tp <- tp + 1
    } else {
      fp <- fp + 1
    }
  }
  
  for (anomaly in known_anomalies) {
    if (!any(sapply(detected_anomalies, function(x) all(x == anomaly)))) {
      fn <- fn + 1
    }
  }
  
  precision <- ifelse(tp + fp == 0, 0, tp / (tp + fp))
  recall <- ifelse(tp + fn == 0, 0, tp / (tp + fn))
  f1_score <- ifelse(precision + recall == 0, 0, 2 * (precision * recall) / (precision + recall))
  
  return(list(precision = precision, recall = recall, f1_score = f1_score))
}

# Evaluar la precisión
results <- evaluate_precision(known_anomalies)
print(results)

# Interpretación
# Precision y Recall en 1 (F1 Score en 1): El modelo es perfecto, detecta todas las anomalías reales sin ningún falso positivo ni falso negativo.
# Precision en 1 y Recall en 0: El modelo detecta solo las anomalías correctas, pero no detecta ninguna anomalía real.
# Precision en 0 y Recall en 1: El modelo detecta todas las anomalías reales, pero también clasifica erróneamente muchas otras instancias como anomalías.
# Precision y Recall en 0 (F1 Score en 0): El modelo no detecta ninguna anomalía correcta y no encuentra ninguna anomalía real.