import boto3
from datetime import datetime, timezone
import os # Importamos el modulo os para saber el nombre exacto  del file.
import glob # Modulo para realizar busquedas con patrones como *.

# Agarramos la hora exacta
fecha_actual = datetime.now()
fecha_formateada = fecha_actual.strftime("%d-%m-%Y")

# Inciamos cliente s3 en AWS
s3_client = boto3.client('s3')
archivo_buscar = os.path.expanduser("~/backup_SetUID_*") # Path completo hacia el archivo del script bash.

# Buscamos el archivo real mediante como fue escrito.
buscar_patron = glob.glob(archivo_buscar)
archivo_name = buscar_patron[0] # el modulo glob crea una lista la cual podemos iterar para buscar el patron que se agrego a la misma, por defecto es 1 solo entonces el indice es 0.
bucket_name = 'el-maligno-306798'
objecto_name = f"log_{fecha_formateada}" # Extraemos el nombre del archivo desde el directorio indicado.

# Creamos el bucket S3 con el nombre deseado de la letra.
boto3.client('s3').create_bucket(Bucket=bucket_name) # Asumimos que el bucket de S3 no esta creado aun.
print(f"El bucket {bucket_name} fue creado con el nombre {objecto_name}")
s3_client.upload_file(archivo_name, bucket_name, objecto_name) # Subimos los archivos al bucket de s3.
print(f"El archivo {archivo_name} fue subido a {bucket_name}/{objecto_name}, para leerlo en su equipo por favor cambiele la extension a .tar.gz")
