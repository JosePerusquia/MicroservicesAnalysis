library(igraph)
library(fastDummies)
library(dplyr)
library(Matrix)

report = read.csv("Documents/Servicio social/report.csv")

#----PRIMER PASO: OBTENER LOS DATOS

#todos los servicios del reporte
services = unique(report$service)

#para obtener cada id con su servicio y el servicio del (o los) parent(s)
report_detailed1 = merge(x = report[, c("id", "service", "parent1")],
                         y = report[, c("id", "service")],
                         by.x = "parent1",
                         by.y = "id",
                         suffixes = c("", "_parent"))
report_detailed2 = merge(x = report[, c("id", "service", "parent2")],
                         y = report[, c("id", "service")],
                         by.x = "parent2",
                         by.y = "id",
                         suffixes = c("", "_parent"))
report_detailed = rbind(report_detailed1[, c("id", "service", "service_parent")],
                        report_detailed2[, c("id", "service", "service_parent")])

#----SEGUNDO PASO: GENERAR LA MATRIZ DE ADYACENCIAS 

for_adjacency = dummy_cols(report_detailed,
                           select_columns = c("service_parent"))
names(for_adjacency) <- sub("service_parent_", "", names(for_adjacency))
adjacency = for_adjacency %>% group_by(service) %>% summarise_if(is.numeric, sum)
adjacency = as.matrix(adjacency[, -1]) 

#---- TERCER PASO: CARACTERÍSTICAS DE LA GRÁFICA

#tamaño de los vértices
services_size = for_adjacency %>% group_by(service) %>% summarise(service_size = n())
vertex_size = as.matrix(services_size$service_size)[, 1]

vertex_label_dist = c() #la separación de las etiquetas de los vértices
self_edge_rotation = c() #la rotación de las aristas que salen y caen en el mismo nodo
edge_label = c() #las etiquetas de las aristas (cuando son necesarias)
edge_curved_value = c() #la curvatura de las aristas (cuando es necesaria)
rotation = 0 #la rotación de las aristas propias es acumulativa, comienza en cero

#este proceso llena estratégicamente los arrays de valores
for(i in 1:length(services)){
  vertex_label_dist = c(vertex_label_dist, 6.5 + 6 * vertex_size[i] / max(vertex_size))
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

#----CUARTO PASO: GENERAR LA GRÁFICA ! 

graph = graph_from_adjacency_matrix(adjacency, mode = "directed", weighted = TRUE)

plot(graph,
     vertex.size = vertex_size / 3, 
     layout = layout.circle(graph),
     margin = 0, 
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
