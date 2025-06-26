import boto3
import os
import mysql.connector

# Configuración de la base de datos RDS
rds_client = boto3.client('rds')

db_instance_identifier = 'Maligno-SRV'
db_instance_class = 'db.t3.medium'  # Cambiado a una clase soportada
engine = 'mysql'
engine_version = '8.4.5'  # Especifica una versión soportada de MariaDB
master_username = 'administrador'
master_user_password = open("pwdrds.txt", 'r').read().strip()  # Asegúrate de que el archivo password.txt contenga la contraseña
allocated_storage = int(os.environ.get('RDS_ALLOCATED_STORAGE', 20))
publicly_accessible = True
sql_filename = 'oblig.sql' # Nombre del archivo sql para los datos y crear todo lo necesario para la base de datos.

try: # Realizaos un try, except ante cualquier error que surja al crear un RDS client.
    response = rds_client.create_db_instance(
        DBInstanceIdentifier=db_instance_identifier,
        DBInstanceClass=db_instance_class,
        Engine=engine,
        EngineVersion=engine_version,
        MasterUsername=master_username,
        MasterUserPassword=master_user_password,
        AllocatedStorage=allocated_storage
    )
    print(f"Creando instancia de base de datos RDS: {db_instance_identifier}")
except Exception as e:
    print(f"Error al crear la instancia de base de datos: {e}")

# --- Obtener los detalles de la instancia para conectar ---
try:
    response = rds_client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
    db_instance = response['DBInstances'][0]
    db_endpoint = db_instance['Endpoint']['Address']
    db_port = db_instance['Endpoint']['Port']

    print(f"Endpoint de la base de datos: {db_endpoint}:{db_port}")

except Exception as e:
    print(f"Error al obtener el endpoint de la base de datos: {e}")
    exit(1)

print(f"\nIntentando conectar a MySQL y ejecutar '{sql_file_name}'...")
mysql_conn = None

try:
    # Intentar conexión
    mysql_conn = mysql.connector.connect(
        host=db_endpoint,
        port=db_port,
        user=master_username,
        password=master_user_password,
    )
    cursor = mysql_conn.cursor()
    # Conectar con MySQl y correr el archivo oblig.sql
    mysql_conn = None
    # Leer el archivo SQL
    with open(sql_filename, 'r') as f:
        sql_script = f.read()
    for statement in sql_script.split(';'):
            if statement.strip(): # Evita ejecutar sentencias vacías
                try:
                    cursor.execute(statement)
                    print(f"Ejecutado: {statement.strip()[:70]}...") # Imprime solo los primeros 70 caracteres
                except mysql.connector.Error as err:
                    print(f"Error al ejecutar sentencia SQL: {err}")
                    # Decide si quieres continuar a pesar de los errores o detenerte
                    # raise # Descomenta para detener la ejecución en el primer error

    mysql_conn.commit() # Confirmar los cambios si no estás en autocommit
    print(f"El archivo '{sql_filename}' fue ejecutado exitosamente en la base de datos empleados.")

except mysql.connector.Error as err:
    print (f"Error de conexion a la base de datos MySQL: {err}")