# Estimación de homicidios en el marco del conflicto armado
El objetivo de este repositorio es la estimación del subregistro de víctimas de homicidio en el marco del conflicto armado para su uso en el proyecto de conciliación censal. 
Para esto, se hace uso de los datos derivados del proyecto conjunto JEP-CEV-HRDAG, que el DANE [publicó](https://microdatos.dane.gov.co/index.php/catalog/795/get-microdata). 

Las tareas de este repositorio deberían ejecutarse en el siguiente orden:
## 1. Estimación
Esta tarea estartifica y estima los estratos acordados con el consultor. 
El input son los datos de homicidio que se enucentran en [este enlace](https://microdatos.dane.gov.co/index.php/catalog/795/get-microdata).

## 2. Posterior
Esta tarea hace una revisión de la distribución posterior de las estimaciones para asegurar que la estratificación fue adecuada

## 3. Combinación 
Esta tarea combina las estimaciones de la tarea de `estimacion`
El input es el output de `estimacion`

## 4. Combinación 
De esta tarea resulta un documento resúmen del proceso y sus resultados. 
  
  
  
  

### Responsables: 
María Juliana Durán: mjduranf@dane.gov.co  
Sergio Esteban Gordillo: segordilloa@dane.gov.co  
Edwan Gabriel Vera: egveram@dane.gov.co  


