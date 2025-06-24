#!/bin/bash

dir_backup="/home/devops/Obligatorio2025/BackupScripts" # Directorio donde guardar el backup.
nombreFileBackup="backup_SetUID_$(date +%Y%m%d_%H%M%S).tar.gz" # Nombre del archivo de backup. Formateado con fecha y hora.
logFile="log_$(date +%Y%m%d_%H%M%S).rep" #Nombre del archivo log.
directorio_utilizado="" #Inicializamos la variable del directorio vacia. dependiendo que se pase como parametro.
log_archivo=false # Condicion inciada en false para las opcion de guardar los caminos en el archivo log de getopts.
solo_bash=false # Condicion inciada en false para la condicion de busqueada solo de scripts de bash en getopts.


function backup {
    local directorio_used="$1"
    if [ -z "$directorio_used" ]; # El directorio es vacio usamos $HOME como variable para la variable local $directorio_used.
    then
        directorio_used="$HOME"
    fi
    # Buscamos solamente todos los directorios los cuales cumplan los requerimientos.
    # Que sean de tipo regular -type f asi podemos restringir la busqueda a solo estos archivos, luego adicionalmente filtramos que sea ejecutable para cualquiera de los usuarios.
    # Tar --null y - T, los cuales nos permiten delimitar la entrada por caracteres nulos pasadas a traves de find y ademas -T - indica que lea desde stdin(el resutlado de find) mediante un pipe.
    find "$directorio_used" -perm -4000 -type f -executable -print0 2>/dev/null | tar --null -T - -czf  "$dir_backup/$nombreFileBackup" 2>/dev/null  
}

# Utilizaremos el comando getopts ya que nos permite procesar los modificadores que queremos crear para las 2 opciones de la letra.
while getopts ":cb" flags;
do
    case $flags in
        c)
            # -c sera la opcion para procesar los caminos absolutos hacia el ejecutable encontrado. Por defecto la busqueda sera recursiva y para archivos regulares.
            log_archivo=true
        ;;
        b)
            # -b sera la opcion para almacenar solamente los ejecutables que sean scripts de bash.
            solo_bash=true
        ;;
        *)
            # Si la variable del modificador no es valida salimos con codigo 1.
            echo "El parametro "-$OPTARG" no es valido, por favor ingrese un parametro valido que sea -c o -s." >&2 
            exit 1
        ;;    
    esac
done
# Si la cantidad de parametros coincide con el siguiente parametro que procesara getopts, entonces el directorio es el parametro $OPTIND.
# Acomodamos la posicion del indice para que el mismo coincida con el directorio en $1. utilizando shift en $OPTIND - 1
shift $((OPTIND-1))

# Verificamos si el directorio existe, o si el parametro final es vacio.
if [ -z "$1" ]; then
    echo "No se ingreso un directorio, se tomara el directorio "$HOME" por defecto."
    directorio_utilizado="$HOME"
else
    if [ ! -d $1 ];
    then
        echo "El directorio "$1" no existe por favor indique uno que exista dentro del filesystem." >&2
        exit 3
    fi
    directorio_utilizado="$1"
fi

#Parametro -c, creamos el archivo log para los path absolutos hacia los ejecutables.
if [ "$log_archivo" = true ]; #Agregamos el path absoluto del directorio donde este presente el archivo ejecutable al archivo log.
then
# Explicacion de while con IFS= read -r -d $'\0', utilizamos esto ya que al imprimir un caracter con el caracter nulo queremos que el delimitador sea el mismo,
# esto por que queremos el path absoluto de la carpeta, asi podemos evitar no perder alguna carpeta que contenga un espacio dentro su nombre.
# Read estara delimitado con el caracter vacio, ya que, lo que es imprimimos al final del archivo encontrado para obtener la ruta absoluta del mismo. -print0.
# IFS sera el un caracter vacio, evitando que se separen las letras en la entrada de find.
    find "$directorio_utilizado" -perm -4000 -type f -executable -print0 2>/dev/null | while IFS= read -r -d $'\0' archivoEjecutable;do realpath "$archivoEjecutable" 
    done | sort > "$dir_backup/$logFile"
fi

#Parametro -b, Buscamos solamente archivos ejecutables de Bash. El incio del archivo debe ser: '^#!/bin/bash'.
if [ "$solo_bash" = true ];
then
    find "$directorio_utilizado" -perm -4000 -type f -executable -print0 2>/dev/null | while IFS= read -r -d $'\0' archivoEjecutable; # Repetimos la estructura de busqueda de archivos ejecutables.
    do 
        echo "$archivoEjecutable"
        if head -n 1 "$archivoEjecutable" 2>/dev/null | egrep -q '^#!/bin/bash'; # Buscamos en al 1er linea unicamente para corroborar que es un script de Bash.
        then
            backup "$directorio_utilizado"
        fi
    done
fi

# Si no se especifico ninguna opcion haremos solamente el backup del de los archivos ejecutables.
if [ "$log_archivo" = false ] && [ "$solo_bash" = false ];
then
    echo "No se ingreso ningun modificador (-c o -b), se procedera solamente a realizar el backup de los archivos."
    backup "$directorio_utilizado"
fi