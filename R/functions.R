library(igraph)
library(fastDummies)
library(dplyr)
library(Matrix)

report_adjacency_matrix <- function(report) {
  #----PRIMER PASO: TRANSFORMAR ADECUADAMENTE LOS DATOS
  
  #obtener todos los servicios del reporte
  services = unique(report$service)
  
  #obtener cada id con su servicio y el servicio del (o los) parent(s)
  report_detailed1 = merge(x = report[, c("id", "thread", "service", "parent1")],
                           y = report[, c("id", "thread", "service")],
                           by.x = "parent1",
                           by.y = "id",
                           suffixes = c("", "_parent"))
  report_detailed2 = merge(x = report[, c("id", "thread", "service", "parent2")],
                           y = report[, c("id", "thread", "service")],
                           by.x = "parent2",
                           by.y = "id",
                           suffixes = c("", "_parent"))
  report_detailed1 = report_detailed1[report_detailed1$thread != report_detailed1$thread_parent, ]
  report_detailed2 = report_detailed2[report_detailed2$thread != report_detailed2$thread_parent, ]
  report_detailed = rbind(report_detailed1[, c("id", "service", "service_parent")],
                          report_detailed2[, c("id", "service", "service_parent")])
  
  #dos casos problemáticos: servicios que no son parents o parents que no son servicios
  no_service = report_detailed$service_parent[!(report_detailed$service_parent %in% report_detailed$service)]
  no_service_parents = report_detailed$service[!(report_detailed$service %in% report_detailed$service_parent)]
  
  #si existen estos casos, con estos servicios deben hacerse ligeras modificaciones para no alterar la matriz de adyacencias
  for (service in no_service_parents) { #primer caso problemático: un servicio que no es parent
    report_detailed[nrow(report_detailed) + 1, ] = c("fake_id", service, service)
  }
  
  #----SEGUNDO PASO: GENERAR LA MATRIZ DE ADYACENCIAS 
  
  for_adjacency = dummy_cols(report_detailed,
                             select_columns = c("service_parent"))
  names(for_adjacency) <- sub("service_parent_", "", names(for_adjacency))
  
  #continuación del primer caso problemático
  for_adjacency[for_adjacency$id == "fake_id", 4:ncol(for_adjacency)] = matrix(0, sum(for_adjacency$id == 'fake_id'), ncol(for_adjacency) - 3)
  
  #obtener la matriz de adyacencias mediante agrupación de las dummy cols
  adjacency = as.data.frame(for_adjacency %>% group_by(service) %>% summarise_if(is.numeric, sum))
  
  #segundo caso problemático: un parent que no es servicio
  for (service in no_service){
    adjacency[nrow(adjacency) + 1, ] <- c(service, rep(0, ncol(adjacency) - 1))
  }
  
  #ordenar la matriz para que las filas coincidan con las columnas (es decir, asegurarse de que efectivamente es la matriz de adyacencias)
  adjacency = adjacency[, c(1, match(colnames(adjacency)[2:ncol(adjacency)], unique(adjacency$service)) + 1)]
  
  return(as.matrix(adjacency[, -1]))
}

report_directed_graph <- function(adjacency) {
  services = colnames(adjacency)
  vertex_size = colSums(adjacency) * 2 #tamaño de los vértices
  vertex_label_dist = c() #la separación de las etiquetas de los vértices
  self_edge_rotation = c() #la rotación de las aristas que salen y caen en el mismo nodo
  edge_label = c() #las etiquetas de las aristas (cuando son necesarias)
  edge_curved_value = c() #la curvatura de las aristas (cuando es necesaria)
  rotation = 0 #la rotación de las aristas propias es acumulativa, comienza en cero
  
  #este proceso llena estratégicamente los arrays de valores
  for(i in 1:length(services)){ 
    vertex_label_dist = c(vertex_label_dist, median(vertex_size) + (length(services) / 1.5) * vertex_size[i] / max(vertex_size))
    #para compose queda mejor dividir length(services) entre 1.5
    for(j in 1:length(services)){
      if(adjacency[i, j] != 0){
        if(i == j){
          self_edge_rotation = c(self_edge_rotation, - (i-1) * 2 * pi / length(services))
        }else{
          self_edge_rotation = c(self_edge_rotation, 0)
        } 
        if (adjacency[i, j] > 1) {
          edge_curved_value = c(edge_curved_value, 0.1)
          edge_label = c(edge_label, adjacency[i, j])
        } else{
          edge_label = c(edge_label, "")
          if (adjacency[j, i] > 1) {
            edge_curved_value = c(edge_curved_value, 0.1)
          } else {
            edge_curved_value = c(edge_curved_value, 0)
          }
        }
      }
    }
  }
  
  #función para la rotación de las etiquetas de vértices
  #este código salió de (colocar fuente)
  radian.rescale <- function(x, start=0, direction=1) {
    c.rotate <- function(x) (x + start) %% (2 * pi) * direction
    c.rotate(scales::rescale(x, c(0, 2 * pi), range(x)))
  }
  lab.locs <- radian.rescale(x=1:length(services), direction=-1, start=0)
  
  #generar la gráfica !
  graph = graph_from_adjacency_matrix(adjacency, mode = "directed", weighted = TRUE)
  
  plot(graph,
       vertex.size = vertex_size, 
       layout = layout.circle(graph),
       margin = 0.5, 
       edge.arrow.size = 0.15,
       edge.label.font = 2,
       edge.label.color = 'black',
       vertex.label.color = 'black',
       vertex.color = 'yellow',
       vertex.label.cex = 0.6,
       edge.label.cex = 0.6,
       vertex.label.dist = vertex_label_dist,
       edge.loop.angle = self_edge_rotation,
       edge.label = edge_label,
       edge.curved = edge_curved_value,
       vertex.label.degree = lab.locs)
}
