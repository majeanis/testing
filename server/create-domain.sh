#! /bin/bash

#
# Nombre del archivo temporal con las Passwords
PASSWORD_FILE=/tmp/gf.pwd

#
# Nombre del JAR que corresponde al Driver JDBC
JDBC_DRIVER="ojdbc6.jar"

#
# Termina la ejecución del script con valor de retorno error
function terminarEjecucion {
   deletePasswordFile;
   exit 1;
}

#
# Termina la ejecución del script en con retorno exitoso
function salir {
   deletePasswordFile;
   exit 0;
}

#
# Termina la ejecución del script siembre y cuando no haya errores
function checkEjecucion {
   if [ "$?" != "0" ]; then
      deletePasswordFile;
      exit $?;
   fi;   
}

#
# Valide que el N° de Puerto de Administración no esté asociado a otro dominio
function validarAdminPort {
   local PORT=$1;
   local CHECK=`$AS_ADMIN list-domains --domaindir $DOMAIN_ROOT_DIR --long true --header false|grep -va "^$NOMBRE_DOMINIO\ "|awk '{print $3}'|grep $PORT`

   if [ -z $CHECK ]; then
      return;
   fi;

   echo "";
   echo "Error: Puerto $PORT ya está en uso"
   terminarEjecucion;
}

#
# Lectura e inicialización de variables
function leerParametrosEntrada {
   #
   # Se pregunta por la opción que se ejecutará
   echo -n "Proceso que se ejecutará [create,recreate,setup]:"
   read OPCION;
   
   if [ -z $OPCION ]; then
      OPCION="create";
   fi;

   case "$OPCION" in
      "create" )
         ;;
      "recreate" )
         ;;
      
      "setup" )
         ;;

      * )
         echo "Debe indicar: create o recreate o setup";
         terminarEjecucion;
   esac;

   #
   # Se pregunta por el directorio de instalación  del GlassFish 
   HOME_GLASSFISH="/servers/glassfish4.1"
   
   echo -n "Directorio de instalación de GlassFish 4.1 [/servers/glassfish4.1]: "
   read HOME_GLASSFISH
   if [ -z $HOME_GLASSFISH ]; then
		HOME_GLASSFISH="/servers/glassfish4.1"
   fi;

   AS_INSTALL=$HOME_GLASSFISH/glassfish
   AS_ADMIN="$AS_INSTALL/bin/asadmin"
   


   #
   # Se valida que exista y sea ejecutable el utilitario "asadmin"
   if ! [ -x $AS_ADMIN ]; then
      echo "No se encuentra el utilitario: $AS_ADMIN"
      terminarEjecucion;
   fi;
   
   # Se pregunta la ubicacion del dominio
   echo -n "Ubicacion del Dominio [/apps/gf_domains]: ";
   read DOMAIN_ROOT_DIR;

   if [ -z $DOMAIN_ROOT_DIR ]; then
      DOMAIN_ROOT_DIR="/apps/gf_domains";
   fi;            
      
   #
   # Se pregunta el Nombre del Dominio
   echo -n "Nombre del Dominio [zsve]: ";
   read NOMBRE_DOMINIO;

   if [ -z $NOMBRE_DOMINIO ]; then
      NOMBRE_DOMINIO="zsve";
   fi;   
   
   #
   # Se pregunta el N° base para los puertos, solo si el proceso es: create o recreate
   if [ "$OPCION" == "create" ] || [ "$OPCION" == "recreate" ]; then
      echo -n "N° Base para la generación de los puertos [7000]: ";
      read PUERTO_BASE;

      if [ -z $PUERTO_BASE ]; then
         PUERTO_BASE=7000;
      fi;

      if [ -z `echo $PUERTO_BASE|grep "^[0-9]*$"` ]; then
         echo "El N° Base debe ser un valor numérico"
         terminarEjecucion;
      fi;
   fi;

   #
   # Se pregunta por el nombre del usuario ADMIN 
   echo -n "Usuario administrador de la consola [admin]: ";
   read ADMIN_USER;

   if [ -z $ADMIN_USER ]; then
      ADMIN_USER="admin";
   fi;
   
   #
   # Se pregunta por la contraseña del usuario ADMIN
   echo -n "Contraseña del usuario administrador [manager1]: ";
   read ADMIN_PASS;
   
   if [ -z $ADMIN_PASS ]; then
      ADMIN_PASS="manager1";
   fi;

   #
   # Se pregunta por el Servidor de BD
   echo -n "BD.ZSVE: Oracle Host [ryuho.zofri.cl]: ";
   read DB_ZSVE_HOST;
   
   if [ -z $DB_ZSVE_HOST ]; then
      DB_ZSVE_HOST="ryuho.zofri.cl";
   fi;

   #
   # Se pregunta por el puerto de comunicaciones
   echo -n "BD.ZSVE: Oracle PORT [1521]: ";
   read DB_ZSVE_PORT;
   
   if [ -z $DB_ZSVE_PORT ]; then
      DB_ZSVE_PORT=1521;
   fi;
   
   if [ -z `echo $DB_ZSVE_PORT|grep "^[0-9]*$"` ]; then
      echo "BD.ZSVE: Oracle PORT debe ser un valor numérico"
      terminarEjecucion;
   fi;
   
   #
   # Se pregunta por el SID de conexión a la BD
   echo -n "BD.ZSVE: Oracle SID [desa]: ";
   read DB_ZSVE_SID;
   
   if [ -z $DB_ZSVE_SID ]; then
      DB_ZSVE_SID="desa";
   fi;

   #
   # Se pregunta por el usuario de conexión a la BD
   echo -n "BD.ZSVE: Oracle Username [zsve]: ";
   read DB_ZSVE_USER;
   
   if [ -z $DB_ZSVE_USER ]; then
      DB_ZSVE_USER="zsve";
   fi;
   
   #
   # Se pregunta por la contraseña de conexión a la BD
   echo -n "BD.ZSVE: Oracle Password: ";
   read DB_ZSVE_PASS;
   
   if [ -z $DB_ZSVE_PASS ]; then
      DB_ZSVE_PASS="zsve";
   fi;

   #
   # Se determina el Puerto de Administración
   if [ "$OPCION" != "setup" ]; then
      ADMIN_PORT=$[$PUERTO_BASE + 48];
      validarAdminPort $ADMIN_PORT;

   else
      ADMIN_PORT=`$AS_ADMIN list-domains --domaindir $DOMAIN_ROOT_DIR --long true|grep "^$NOMBRE_DOMINIO\ "|awk '{print $3}'`
      if [ -z $ADMIN_PORT ]; then
         echo ""
         echo "Error: No se pudo determinar el N° de puerto de Administración de la consola"
         terminarEjecucion;
      fi;
   fi;

   echo ""
   echo "VALORES DE EJECUCION"
   echo "===================="
   echo "PROCESO         :" $OPCION
   echo "AS_INSTALL      :" $AS_INSTALL
   echo "AS_ADMIN        :" $AS_ADMIN
   echo "DOMINIO         :" $NOMBRE_DOMINIO
   echo "ADMIN PORT      :" $ADMIN_PORT
   echo "ADMIN USER      :" $ADMIN_USER
   echo "ADMIN PASSWORD  :" $ADMIN_PASS
   echo "DOMAIN ROOT     :" $DOMAIN_ROOT_DIR
   echo "DB.ZSVE HOST    :" $DB_ZSVE_HOST
   echo "DB.ZSVE PORT    :" $DB_ZSVE_PORT
   echo "DB.ZSVE SID     :" $DB_ZSVE_SID
   echo "DB.ZSVE USERNAME:" $DB_ZSVE_USER
   echo "DB.ZSVE PASSWORD:" $DB_ZSVE_PASS
   echo ""

   #
   # Se prepara variable con comando ASADMIN con autenticación
   AS_ADMIN_AUTH="$AS_ADMIN --user $ADMIN_USER --passwordfile $PASSWORD_FILE --port $ADMIN_PORT"
}

#
# Función que crea el archivo con la password del usuario "admin"
function createPasswordFile {
   echo "AS_ADMIN_PASSWORD="$ADMIN_PASS > $PASSWORD_FILE
   checkEjecucion;
}

#
# Elimina el archivo que contiene la password del usuario "admin"
function deletePasswordFile {
   rm -f $PASSWORD_FILE
}

#
# Función que inicia la ejecución de un Dominio
function startDomain {
   local CHECK_DOMINIO=`$AS_ADMIN list-domains --domaindir $DOMAIN_ROOT_DIR|grep "^$NOMBRE_DOMINIO\ "`
   
   if [ "$CHECK_DOMINIO" == "" ]; then
      echo "El Dominio $NOMBRE_DOMINIO no existe en el servidor";
      terminarEjecucion;
   fi;
   
   if [ "`echo $CHECK_DOMINIO|grep \"not running\"`" != "" ]; then
      echo ""
      echo "Iniciando Dominio" $NOMBRE_DOMINIO "..."
      $AS_ADMIN start-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
      checkEjecucion;
   fi;
}

#
# Functión que detiene la ejecución de un Dominio
function stopDomain {
   local CHECK_DOMINIO=`$AS_ADMIN list-domains --domaindir $DOMAIN_ROOT_DIR|grep "^$NOMBRE_DOMINIO\ "`
   
   if [ -z "$CHECK_DOMINIO" ]; then
      echo "El Dominio $NOMBRE_DOMINIO no existe en el servidor";
      terminarEjecucion;
   fi;
   
   #
   # Si el dominio no está en ejecución, entonces nada más que hacer
   if [ "`echo $CHECK_DOMINIO|grep \"not running\"`" != "" ]; then
      return;
   fi;
   
   echo ""
   echo "Deteniendo Dominio" $NOMBRE_DOMINIO "..."
   $AS_ADMIN stop-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
   checkEjecucion;
}

#
# Función que elimina el Dominio
function deleteDomain {
   #
   # Nos aseguramos que el dominio no esté en ejecución
   stopDomain;

   #
   # Eliminación del Dominio
   echo ""
   echo "Eliminación del Dominio:" $NOMBRE_DOMINIO "..."
   $AS_ADMIN delete-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
   checkEjecucion;
}

#
# Función que crea el Dominio
function createDomain {
   #
   # Nos aseguramos que exista el directorio de destino
   if ! [ -d $DOMAIN_ROOT_DIR ]; then
      mkdir -p $DOMAIN_ROOT_DIR
      terminarEjecucion;
   fi;

   local CHECK_DOMINIO=`$AS_ADMIN list-domains --domaindir $DOMAIN_ROOT_DIR|grep "^$NOMBRE_DOMINIO\ "`

   #
   # Primero se valida que el dominio no exista
   if [ "$CHECK_DOMINIO" != "" ]; then
      echo "El Dominio $NOMBRE_DOMINIO ya existe en este servidor";
      terminarEjecucion;
   fi;

   #
   # Creación de archivo con la password
   createPasswordFile;

   #
   # Creación del Dominio
   $AS_ADMIN --user $ADMIN_USER --passwordfile $PASSWORD_FILE \
             create-domain --savemasterpassword=false \
                           --domaindir $DOMAIN_ROOT_DIR \
                           --portbase $PUERTO_BASE \
                           $NOMBRE_DOMINIO
   checkEjecucion;

   #
   # Nos aseguramos de copiar el driver JDBC de Oracle
   cp libs/$JDBC_DRIVER $DOMAIN_ROOT_DIR/$NOMBRE_DOMINIO/lib/ext

   #
   # Se habilita la administración por Consola de manera segura
   echo ""
   echo "Habilitando administración segura..."   
   $AS_ADMIN start-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
   checkEjecucion;

   #
   # Para habilitar la administración segura es preciso
   # autenticarse en la consola del dominio
   $AS_ADMIN_AUTH enable-secure-admin
   checkEjecucion;

   echo ""
   echo "Reiniciando el dominio:" $NOMBRE_DOMINIO "..."
   $AS_ADMIN restart-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
   checkEjecucion;
   
   #
   # Se eliminan valores por defecto del Dominio
   echo ""
   echo "Eliminación de valores por defecto de Dominio:" $NOMBRE_DOMINIO "..."
   for jdbc in `$AS_ADMIN_AUTH list-jdbc-resources server|grep -va successfully`; do
      $AS_ADMIN_AUTH delete-jdbc-resource $jdbc;
      checkEjecucion;
   done;
   
   for pool in `$AS_ADMIN_AUTH list-jdbc-connection-pools|grep -va successfully|grep -va target`; do
      $AS_ADMIN_AUTH delete-jdbc-connection-pool $pool;
      checkEjecucion;
   done;
}

#
# Función que crea un JDBC
function createJdbc {
   local NAME=$1
   local DB_HOST=$2
   local DB_PORT=$3
   local DB_SID=$4
   local DB_USER=$5
   local DB_PASS=$6
   
   local POOL_NAME="$NAME""Pool"
   local JNDI_NAME="jdbc/$NAME"
   local JDBC_URL="jdbc\:oracle\:thin\:@$DB_HOST\:$DB_PORT\:$DB_SID"
   local CHECK_POOL=`$AS_ADMIN_AUTH list-jdbc-connection-pools|grep $POOL_NAME`
      
   #
   # Eliminamos la configuración actual
   if [ "$CHECK_POOL" != "" ]; then
      $AS_ADMIN_AUTH delete-jdbc-connection-pool --cascade true $POOL_NAME
      checkEjecucion;
   fi;

   #
   # Nos aseguramos que el driver JDBC exista en el servidor
   if [ ! -f $DOMAIN_ROOT_DIR/$NOMBRE_DOMINIO/lib/ext/$JDBC_DRIVER ]; then
      echo "Copiando driver JDBC...";

      cp libs/$JDBC_DRIVER $DOMAIN_ROOT_DIR/$NOMBRE_DOMINIO/lib/ext;
      checkEjecucion;
      
      $AS_ADMIN restart-domain $NOMBRE_DOMINIO;
      checkEjecucion;
   fi;
   
   #
   # Creación del Pool JDBC
   $AS_ADMIN_AUTH create-jdbc-connection-pool \
                  --restype javax.sql.ConnectionPoolDataSource \
                  --datasourceclassname oracle.jdbc.pool.OracleConnectionPoolDataSource \
                  --ping true \
                  --steadypoolsize 8 \
                  --maxpoolsize 32 \
                  --property URL="$JDBC_URL":user=$DB_USER:password=$DB_PASS \
                  $POOL_NAME
   checkEjecucion;

   #
   # Creación del DataSource
   $AS_ADMIN_AUTH create-jdbc-resource \
                  --enabled true \
                  --connectionpoolid $POOL_NAME \
                  $JNDI_NAME
}

#
# Función que configura el JDBC para acceso a BD del zSVE
function setupJdbcZsve {
   createJdbc "zsve" "$DB_ZSVE_HOST" "$DB_ZSVE_PORT" "$DB_ZSVE_SID" "$DB_ZSVE_USER" "$DB_ZSVE_PASS"
}

#
# Crea la Factory de JMSs
function setupJmsFactory {
   local JMS_FACTORY=$1
   local CHECK_FACTORY="`$AS_ADMIN_AUTH list-jms-resources|grep $JMS_FACTORY`"
   
   if [ "$CHECK_FACTORY" != "" ]; then
      $AS_ADMIN_AUTH delete-jms-resource $JMS_FACTORY
      checkEjecucion;
   fi;
   
   $AS_ADMIN_AUTH create-jms-resource --restype javax.jms.QueueConnectionFactory \
                                      --enabled true \
                                      --property steady-pool-size=20:max-pool-size=250 \
                                      $JMS_FACTORY
   checkEjecucion;
}

#
# Creación de una Cola JMS dada como parámetro
function setupJmsQueue {
   local QUEUE_NAME=$1
   local JNDI_NAME="jms/$1"
   local CHECK_QUEUE=`$AS_ADMIN_AUTH list-jms-resources --restype javax.jms.Queue|grep $JNDI_NAME`
   
   if [ "$CHECK_QUEUE" != "" ]; then
      return;
   fi;
   
   #
   # Creación de la Queue
   $AS_ADMIN_AUTH create-jms-resource --restype javax.jms.Queue \
                                      --enabled true \
                                      --property Name=$QUEUE_NAME \
                                      $JNDI_NAME
   checkEjecucion;
}

#
# Función que configura las Sesiones JavaMail
function setupJavaMail {
   local MAIL_FROM="$1@zofri.cl"
   local JNDI_NAME="email/$1"

   local CHECK_MAIL=`$AS_ADMIN_AUTH list-javamail-resources|grep $JNDI_NAME`

   if [ "$CHECK_MAIL" != "" ]; then
      $AS_ADMIN_AUTH delete-javamail-resource $JNDI_NAME
      checkEjecucion;
   fi;

   $AS_ADMIN_AUTH create-javamail-resource --mailhost smtp2.zofri.cl \
                                           --mailuser sve \
                                           --fromaddress $MAIL_FROM \
                                           --enabled true \
                                           --property mail.smtp.port=25 \
                                           $JNDI_NAME
   checkEjecucion;
}

#
# Función que permite eliminar una opción desde la JVM
function deleteJvmOption {
   local JVM_OPTION=$1
   local CHECK_JVM_OPTION=`$AS_ADMIN_AUTH list-jvm-options|grep "\-$JVM_OPTION"`

   if [ "$CHECK_JVM_OPTION" != "" ]; then
      echo "Eliminando: -$JVM_OPTION"
      $AS_ADMIN_AUTH delete-jvm-options "-$JVM_OPTION"
      checkEjecucion;
   fi;
}

#
# Función que permite agregar una opción en la JVM
function createJvmOption {
   local JVM_OPTION=$1
   local CHECK_JVM_OPTION=`$AS_ADMIN_AUTH list-jvm-options|grep "\-$JVM_OPTION"`

   echo "Creando: -$JVM_OPTION"
   if [ "$CHECK_JVM_OPTION" != "" ]; then
      return;
   fi;
   
   $AS_ADMIN_AUTH create-jvm-options "-$JVM_OPTION"
   checkEjecucion;
}

#
# Función que configura los parámetros de ejecución de la JVM
function setupJVM {
   deleteJvmOption "client"
   deleteJvmOption "Xmx512m"
   deleteJvmOption "XX\:MaxPermSize=192m"
   createJvmOption "server"
   createJvmOption "Xmx1024m"
   createJvmOption "Xms1024m"
   createJvmOption "verbose\:gc"
   createJvmOption "XX\:MaxPermSize=256m"
   createJvmOption "XX\:+PrintGCDateStamps"
   createJvmOption "XX\:+PrintGCDetails"
   createJvmOption "XX\:-HeapDumpOnOutOfMemoryError"
   createJvmOption "XX\:HeapDumpPath=\${com.sun.aas.instanceRoot}/logs/glassfish.hprof"
   createJvmOption "Xloggc\:\${com.sun.aas.instanceRoot}/logs/gc.log"
}

#
# Configura el Dominio
function setupDomain {
   #
   # Nos aseguramos que el Dominio esté iniciado
   startDomain;

   #
   # Nos aseguramos que exista el archivo con la password del ADMIN
   createPasswordFile;

   #
   # Se copian los JARs esenciales del Dominio
   echo ""
   echo "Copiando archivos JARs en LIB del Dominio..."
   for f in `ls libs/*.jar|grep -va $JDBC_DRIVER`; do
      cp $f $DOMAIN_ROOT_DIR/$NOMBRE_DOMINIO/lib
   done;
   
   #
   # Configuración de las colas JMSs
   echo ""
   echo "Configurando servidor JMS..."

   setupJmsFactory "jms/ZsveConnectionFactory";

   for queue in EmailQueue Guardar101Queue Guardar201Queue Guardar203Queue Guardar202Queue Guardar301Queue Guardar302Queue; do
      setupJmsQueue $queue
   done;

   #
   # Configuración de la cola de Correos
   echo ""
   echo "Configurando servidor JavaMail..."
   setupJavaMail "sve";

   #
   # Configuración del Pool a la Base Datos
   echo ""
   echo "Configurando Data Source JDBC - zSVE..."
   setupJdbcZsve;

   #
   # Configuración de la VM
   echo ""
   echo "Configurando parámetros de la JVM..."
   setupJVM;
   
   #
   # Finalmente se reinicia el Dominio para que se apliquen las configuraciones
   echo ""
   echo "Reiniciando el dominio:" $NOMBRE_DOMINIO "..."
   $AS_ADMIN restart-domain --domaindir $DOMAIN_ROOT_DIR $NOMBRE_DOMINIO
   checkEjecucion;
}

#
# Se leen por pantalla las variables de ambiente
leerParametrosEntrada;

case $OPCION in
   'create' )
      createDomain;
      setupDomain;
      salir;
      ;;
   
   'recreate' )
      deleteDomain;
      createDomain;
      setupDomain;
      salir;
      ;;

   'setup'  )
      setupDomain;
      salir;
      ;;
esac;
