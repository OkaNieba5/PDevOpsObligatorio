#!/bin/bash
dir_backup="$HOME/Camino_absoluto" # Directorio temporal donde guardar el backup 
nombreFileBackup="backup_SetUID_$(date +%Y%m%d_%H%M%S).tar.gz" # Nombre del archivo de backup. Formateado con fecha y hora.
logFile="log_$(date +%Y%m%d_%H%M%S).rep" #Nombre del archivo log.
directorio_utilizado="" #Inicializamos la variable del directorio vacia. dependiendo que se pase como parametro.
log_archivo=false # Condicion inciada en false para las opcion de guardar los caminos en el archivo log de getopts.
solo_bash=false # Condicion inciada en false para la condicion de busqueada solo de scripts de bash en getopts.

mkdir -p "$dir_backup" #Nos aseguramos que el directorio de backup exista y este creado.

function backup {
    local directorio_used="$1"
    # Caso 1 Parametro -b, Buscamos solamente archivos ejecutables de Bash. El incio del archivo debe ser: '^#!/bin/bash'.
    if [ "$solo_bash" = true ];
    then
        #Abrimos un bloque de comandos para agrupar la salida a la tuberia.
        {
            # Explicacion de while con IFS= read -r -d $'\0', y find. utilizamos esto ya que al imprimir un caracter con el caracter nulo queremos que el delimitador sea el mismo.
            # Esto por que queremos el path absoluto de la carpeta, asi podemos evitar no perder alguna carpeta que contenga un espacio dentro su nombre.
            # IFS sera el un caracter vacio, evitando que se separen las letras en la entrada de find.
            # Buscamos solamente todos los directorios los cuales cumplan los requerimientos.
            # Que sean de tipo regular -type f asi podemos restringir la busqueda a solo estos archivos, luego adicionalmente filtramos que sea ejecutable para cualquiera de los usuarios.
            # Read estara delimitado con el caracter vacio, ya que, lo que es imprimimos al final del archivo encontrado para obtener la ruta absoluta del mismo. -print0.
            find "$directorio_used" -perm -4000 -type f -executable -print0 2>/dev/null | 
            while IFS= read -r -d $'\0' archivoEjecutable;
            do
                if head -n 1 "$archivoEjecutable" 2>/dev/null | egrep -q '^#!/bin/bash'; # Buscamos en al 1er linea unicamente para corroborar que es un script de Bash.
                then
                   echo -e "${archivoEjecutable}\0" # Mandamos el archivo ejecutable a la salida con el final nulo para el tar -T -.
                fi
            done
            # Si el log fue generado con la opcion -c, debera inclusie en el backup
            if [ "$log_archivo" = true ] && [ -f "$dir_backup/$logfile" ];
            then
                echo -e "${dir_backup/logfile}\0" # Mandamos el path del archivo .rep (log) con un caracter nulo al final para tar -T
            fi
        } | tar --null -T - -czf "$nombreFileBackup" "$dir_backup" 2>/dev/null
        # En este caso el -T - va comprmir toda la salida completa dentro del bloque. Ya que viene de la stdin gracias al pipe.
        # Tar --null y - T, los cuales nos permiten delimitar la entrada por caracteres nulos pasadas a traves de find y ademas -T - indica que lea desde stdin(el resutlado de find) mediante un pipe.
    
    else # Caso 2 Opcion sin -b, solamente script ejecutables en general, cumpliendo la condicion del SetUID.
        { # Abrimos un bloque de comandos para redirigir la salida completa.
            find "$directorio_used" -perm -4000 -type f -executable -print0 2>/dev/null # Repetimos el bloque find de la busqueda anterior.
            if head -n 1 "$archivoEjecutable" 2>/dev/null | egrep -q '^#!/bin/bash'; # Buscamos en al 1er linea unicamente para corroborar que es un script de Bash.
            then
                echo -e "${archivoEjecutable}\0" # Mandamos el archivo ejecutable a la carpeta de backup(directorio de trabajo por defecto).
            fi
            # En este caso el tar va solamente recibir de la stdin el archivo ejecutable directamente para comprimir.
        } | tar --null -T - -czf "$dir_backup/$nombreFileBackup" 2>/dev/null # Repetimos mismo procedimiento que en el caso 1.
    fi
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
            # Si la variable del modificador no es valida salimos con codigo 1
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

# Modificador -c activado, guardamos el archivo .rep del log en el directorio de backups.
if [ "$log_archivo" = true ];
then
    if [ "$solo_bash" = true ]; # Caso 1.1, tenemos -b activado para que busque solo el path del archivo bash.
    then
        find "$directorio_utilizado" -perm -4000 -type f -executable -print0 2>/dev/null | 
        while IFS= read -r -d $'\0' archivoEjecutable; do
            if head -n 1 "$archivoEjecutable" 2>/dev/null | egrep -q '^#!/bin/bash'; # Si la 1er linea del archivo ejecutable es #!/bin/bash entonces es un script de bash.
            then
                realpath "$archivoEjecutable" # Si el archivo es encontrado luego de pipear la anterior busqueda mandamos el archivo a un pipe hacia el directorio de backup.
            fi
        done | sort > "$dir_backup/$logFile"
    else 
        # Caso 1.2, no tenemos -b activado.
        find "$directorio_utilizado" -perm -4000 -type f -executable -print0 2>/dev/null | while IFS= read -r -d $'\0' archivoEjecutable; do realpath "$archivoEjecutable" 
        done | sort > "$dir_backup/$logFile"
    fi
fi

#Inciamos el backup.
backup "$directorio_utilizado"
rm -r "$dir_backup" # Eliminamos el directorio temporal.

# Si no se especifico ninguna opcion haremos solamente el backup del de los archivos ejecutables.
if [ "$log_archivo" = false ] && [ "$solo_bash" = false ];
then
    echo "No se ingreso ningun modificador (-c o -b), se procedera solamente a realizar el backup de los archivos."
fi