#!/bin/bash

path_por_defecto=$HOME #Si el usuario no ingresa ningun directorio como parametro se envia el directorio corriente de trabajo.
dir_backup="/home/devops/Obligatorio2025/BackupScripts/" # Directorio donde guardar el backup.
nombreFileBackup="backup_SetUID_$(date +%Y%m%d_%H%M%S).tar.gz" # Nombre del archivo de backup. Formateado con fecha y hora.
logFile="log_$(date +%Y%m%d_%H%M%S).rep" #Nombre del archivo log.

#Chequearemos las opciones con errores primero

if [ -d "$1" ]
then
    echo "El directorio existe..."
else
    echo "El directorio no existe, por favor ingrese uno correcto." >&2
    exit 1
fi

if [ ]

# Utilizaremos el comando getopts ya que nos permite procesar las flags que queremos crear para las 2 opciones de la letra.
# -c sera la opcion para procesar los caminos absolutos hacia el ejecutable encontrado. Por defecto la busqueda sera recursiva y para archivos regulares.
# -s sera la opcion para almacenar en el archivo log los ejecutables que sean scripts de bash.
while getopts ":cs" flags
do
    case $flags in
        c)
            #Agregamos el path relativo hacia el directorio en el archivo log.
            realpath "$1" | sort > "$dir_backup/$logFile"
        ;;
        s)
            #Buscamos unicamente los archivos que contengan #!/bin/bash
            if [ "$1" != "" ]
            then
            ( 
                # Abriremos una subshell para poder pasar todo el resultado a un solo archivo mediante un pipe.
                # Find para los permiso SetUID del usuario Root.
                # Utilizaremos en find la opcion -print0 para que imprima un caracter nulo asi si existe un nombre que contenga espacios para el path, luego no tendremos problema con la sustitucion de la shell.
                # Find de por si buscara de forma recursiva asi que no hara falta de indicar alguna expresion regular para buscar archivos ocultos.
                # Usaremos -type f para que busque solamente archivos regulares, asi restringimos la busqueda.
                # Utilizaremos tambien la expresion regular con grep -E '^#!/bin/bash' para indicar que solamente buscaremos los archivos que comiencen con esas lineas.
                find "$1" -user root -perm -4000 -type f -exec grep -E '^#!/bin/bash' -print0 2>/dev/null
                # Find para los permisos SetUID y Ejecuccion para los usuarios restantes.
                find "$1" ! -user root -perm -4000 -perm -111 -type f -exec grep -E '^#!/bin/bash' -print0 2>/dev/null
                # Utilizaremos un Sort para los dos casos con las opciones -z, -u para que ordene, elimine entradas repetidas y nulas (-print0).
            ) | sort -zu | tar -czf "$dir_backup/$nombreFileBackup" -T --null  --absolute-names
                else
            # Haremos exactamente la misma accion pero en caso de que el directorio pasado por la stdin este vacio.
            (
                find "$path_por_defecto" -user root -perm -4000 -type f -print0 2>/dev/null
                find "$path_por_defecto" ! -user root -perm -4000 -perm -111 -type f -print0 2>/dev/null
            ) | sort -zu | tar -czf "$dir_backup/$nombreFileBackup" -T --null  --absolute-names
            fi
        ;;
        *)
            echo "El modificador "-$flag" no existe, solo se aceptan -s y -c debera volver a ingresar las opciones correctamente." >&2
            exit 3
        ;;    
    esac
    if [ "$1" != "" ]
    then
    ( 
        # Abriremos una subshell para poder pasar todo el resultado a un solo archivo mediante un pipe.
        # Find para los permiso SetUID del usuario Root.
        # Utilizaremos en find la opcion -print0 para que imprima un caracter nulo asi si existe un nombre que contenga espacios para el path, luego no tendremos problema con la sustitucion de la shell.
        # Find de por si buscara de forma recursiva asi que no hara falta de indicar alguna expresion regular para buscar archivos ocultos.
        # Usaremos -type f para que busque solamente archivos regulares, asi restringimos la busqueda.
        find "$1" -user root -perm -4000 -type f -print0 2>/dev/null
        # Find para los permisos SetUID y Ejecuccion para los usuarios restantes.
        find "$1" ! -user root -perm -4000 -perm -111 -type f -print0 2>/dev/null
        # Utilizaremos un Sort para los dos casos con las opciones -z, -u para que ordene, elimine entradas repetidas y nulas (-print0).
    ) | sort -zu | tar -czf "$dir_backup/$nombreFileBackup" -T --null  --absolute-names
    else
    # Haremos exactamente la misma accion pero en caso de que el directorio pasado por la stdin este vacio.
    (
        find "$path_por_defecto" -user root -perm -4000 -type f -print0 2>/dev/null
        find "$path_por_defecto" ! -user root -perm -4000 -perm -111 -type f -print0 2>/dev/null
    ) | sort -zu | tar -czf "$dir_backup/$nombreFileBackup" -T --null  --absolute-names
    fi
done