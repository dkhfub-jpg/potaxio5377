#!/data/data/com.termux/files/usr/bin/bash

clear

####################################
# CONFIGURACIÓN
####################################
DOMAIN="dns.titopro.work.gd"
SERVER_STATUS="DESCONOCIDO"

LOG_DIR="$HOME/.slipstream"
LOG_FILE="$LOG_DIR/slip.log"
mkdir -p "$LOG_DIR"

DATA_SERVERS=(
"200.55.128.140:53"
"200.55.128.130:53"
"200.55.128.250:53"
"200.55.128.230:53"
)

WIFI_SERVERS=(
"181.225.231.120:53"
"181.225.231.110:53"
"181.225.233.40:53"
"181.225.233.30:53"
)

####################################
# COLORES
####################################
PURPLE="\e[38;5;93m"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
GRAY="\e[90m"
BOLD="\e[1m"
RESET="\e[0m"

separator() {
    echo -e "${CYAN}────────────────────────────────────────${RESET}"
}

####################################
# BANNER PRINCIPAL
####################################
banner() {
    printf "%35s${CYAN}Script TitoMX Unlock${RESET}\n"
}

####################################
# PANTALLA DE VERIFICACIÓN
####################################
checking_screen() {
    clear
    echo -e "${CYAN}"
    echo "════════════════════════════════════════"
    echo "               VERIFICANDO               "
    echo "════════════════════════════════════════"
    echo -e "${RESET}"
    echo
    echo -e "${CYAN}Espere unos segundos...${RESET}"
}

####################################
# LIMPIEZA
####################################
clean_slipstream() {
    pkill -f slipstream-client 2>/dev/null
    sleep 1
}

####################################
# CHEQUEO AUTOMÁTICO DEL SERVIDOR
####################################
check_server_on_start() {
    clean_slipstream
    > "$LOG_FILE"

    ./slipstream-client \
        --tcp-listen-port=8080 \
        --resolver=8.8.8.8 \
        --domain="$DOMAIN" \
        --keep-alive-interval=600 \
        --congestion-control=bbr \
        > "$LOG_FILE" 2>&1 &

    PID=$!
    SERVER_STATUS="INACTIVO"

    for i in {1..8}; do
        if grep -q "Connection confirmed" "$LOG_FILE"; then
            SERVER_STATUS="ACTIVO"
            break
        fi

        if grep -q "Connection closed" "$LOG_FILE"; then
            SERVER_STATUS="INACTIVO"
            break
        fi

        if kill -0 $PID 2>/dev/null && [ $i -ge 6 ]; then
            SERVER_STATUS="ACTIVO"
            break
        fi

        sleep 1
    done

    kill $PID 2>/dev/null
    clean_slipstream
}

####################################
# MOSTRAR ESTADO
####################################
show_server_status() {
    if [ "$SERVER_STATUS" = "ACTIVO" ]; then
        echo -e "${GREEN}${BOLD}✅ Estado del servidor: ACTIVO${RESET}"
    else
        echo -e "${RED}${BOLD}❌ Estado del servidor: INACTIVO${RESET}"
    fi
}

####################################
# INSTALAR SLIPSTREAM
####################################
install_slipstream() {
    clear
    rm -f setup.sh
    pkg install wget -y
    wget https://raw.githubusercontent.com/BoredBoy23/A-congelar-se-ha-dicho/main/setup.sh
    chmod +x setup.sh
    ./setup.sh
    read -p "ENTER para volver"
}

####################################
# CONEXIÓN
####################################
connect_auto() {
    local SERVERS=("$@")

    for SERVER in "${SERVERS[@]}"; do
        clean_slipstream
        > "$LOG_FILE"

        clear
        echo -e "${PURPLE}[*] Comprobando servidor:${RESET} $SERVER"
        separator

        ./slipstream-client \
            --tcp-listen-port=8080 \
            --resolver="$SERVER" \
            --domain="$DOMAIN" \
            --keep-alive-interval=300 \
            --congestion-control=bbr \
            --gso=true \
            > >(tee -a "$LOG_FILE") 2>&1 &

        PID=$!

        for i in {1..4}; do
            if grep -q "Connection confirmed" "$LOG_FILE"; then
                clear
                echo -e "${CYAN}${BOLD}DNS funcionando ✅${RESET}"
                echo -e "${CYAN}DNS activo:${RESET} ${YELLOW}$SERVER${RESET}"
                separator
                echo -e "${GRAY}Desactive los datos móviles/WiFi para desconectar${RESET}"
                wait $PID
                return
            fi
            sleep 1
        done

        clean_slipstream
    done

    echo -e "${RED}No se pudo conectar${RESET}"
    read -p "ENTER para volver"
}

####################################
# EJECUCIÓN INICIAL
####################################
sleep 1

####################################
# MENÚ
####################################
while true; do
    clear
    banner
    separator

    echo " 1) Conectar en Datos Móviles"
    echo " 2) Conectar en WiFi"
    echo " 3) Instalar slipstream-client"
    echo " 0) Salir"

    separator
    read -p "Selecciona una opción: " opt

    case $opt in
        1) connect_auto "${DATA_SERVERS[@]}" ;;
        2) connect_auto "${WIFI_SERVERS[@]}" ;;
        3) install_slipstream ;;
        0) clear; exit ;;
    esac
done
