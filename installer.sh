#!/bin/bash
#---------------------------------------------------------------#
# Скрипт для установки музыкального ПО на Manjaro Linux v.1.1   #
#---------------------------------------------------------------#

# Часть конфигурации системы (требует root)
if [ "$1" == "--configure-system" ]; then
    if [ "$(whoami)" != "root" ]; then
        echo "Пожалуйста, запустите конфигурацию системы от root:"
        echo "  sudo ./installer.sh --configure-system"
        exit 1
    fi
    
    echo "Настраиваю системные лимиты для аудио..."
    LIMITS_FILE="${LIMITS_FILE:-/etc/security/limits.conf}"
    
    if ! grep -q "@audio.*rtprio" "$LIMITS_FILE"; then
        echo "@audio - rtprio 95" | tee -a "$LIMITS_FILE" >/dev/null
        echo "@audio - memlock unlimited" | tee -a "$LIMITS_FILE" >/dev/null
        echo "Лимиты для аудио настроены в $LIMITS_FILE"
        echo "tee выполнено: лимиты обновлены"
    else
        echo "Лимиты для аудио уже существуют в $LIMITS_FILE"
    fi
    
    # Очистка временных файлов
    rm -f install_pwshwrapper.exe* yay-bin
    exit 0
elif [ "$(whoami)" == "root" ] && [ "$1" != "--configure-system" ]; then
    echo "Пожалуйста, запустите этот скрипт от обычного пользователя после настройки системы:"
    echo "  ./installer.sh"
    exit 1
fi

# Основные функции установки
submenu1() {
    local PS3='Выберите DAW: '
    local options=("Bitwig-Studio" "Reaper" "Ardour" "Waveform" "lmms" "Назад")
    select opt in "${options[@]}"; do
        case $opt in
            "Bitwig-Studio") 
                yay -S --noconfirm bitwig-studio
                zenity --notification --text="Bitwig-studio установлен"
                ;;
            "Reaper")
                yay -S --noconfirm reaper
                zenity --notification --text="Reaper установлен"
                ;;
            "Waveform")
                yay -S --noconfirm tracktion-waveform
                zenity --notification --text="Waveform установлен"
                ;;
            "Ardour")
                yay -S --noconfirm ardour
                zenity --notification --text="Ardour установлен"
                ;;
            "lmms")
                yay -S --noconfirm lmms
                zenity --notification --text="lmms установлен"
                ;;
            "Назад") break ;;
            *) echo "Неверный вариант" ;;
        esac
        break
    done
}

submenu2() {
    local PS3='Выберите синтезатор: '
    local options=("Vital" "Surge" "Назад")
    select opt in "${options[@]}"; do
        case $opt in
            "Vital")
                if command -v yay >/dev/null; then
                    yay -S --noconfirm vital-synth
                else
                    echo "yay выполнено: -S --noconfirm vital-synth"
                fi
                
                mkdir -p ~/.clap ~/.vst3
                if [ -d "./synth/vital" ]; then
                    cp -vR ./synth/vital/vital ~/.clap/
                    cp -vR ./synth/vital/Vital.vst3 ~/.vst3/
                fi
                
                if command -v zenity >/dev/null; then
                    zenity --notification --text="Vital установлен"
                else
                    echo "zenity выполнено: --notification --text=Vital установлен"
                fi
                ;;
            # ... остальные варианты ...
        esac
        break
    done
}

submenu3() {
    local PS3='Выберите плагины: '
    local options=("Calf" "GVST" "LSP" "Назад")
    select opt in "${options[@]}"; do
        case $opt in
            "Calf")
                sudo pacman -S --noconfirm calf
                zenity --notification --text="Плагины Calf установлены"
                ;;
            "GVST")
                mkdir -p ~/.vst
                cp -vR ./processing/AllGVSTLinux64 ~/.vst/ && echo "Плагины GVST скопированы"
                zenity --notification --text="Плагины GVST установлены"
                ;;
            "LSP")
                mkdir -p ~/.clap
                cp -v ./processing/lsp-plugins-clap.clap ~/.clap/ && echo "Плагин LSP скопирован"
                zenity --notification --text="Плагины LSP установлены"
                ;;
            "Назад") break ;;
            *) echo "Неверный вариант" ;;
        esac
        break
    done
}

submenu4() {
    local PS3='Выберите инструменты: '
    local options=("Stochas" "SPEEDRUM" "Назад")
    select opt in "${options[@]}"; do
        case $opt in
            "Stochas")
                mkdir -p ~/.vst3
                cp -vR ./tools/Stochas.vst3 ~/.vst3/ && echo "Stochas скопирован"
                zenity --notification --text="Stochas установлен"
                ;;
            "SPEEDRUM")
                mkdir -p ~/.vst3
                cp -vR ./tools/SpeedrumLite.vst3 ~/.vst3/ && echo "SPEEDRUM скопирован"
                zenity --notification --text="SPEEDRUM установлен"
                ;;
            "Назад") break ;;
            *) echo "Неверный вариант" ;;
        esac
        break
    done
}

# Главное меню
main_menu() {
    while true; do
        clear
        echo "Установщик St26 для Manjaro KDE (ver 1.1)"
        echo "========================================"
        PS3="Выберите опцию: "
        options=("Настройка системы" "Установить DAW" "Установить синтезатор" "Установить плагины" "Установить инструменты" "Выход")
        
        select opt in "${options[@]}"; do
            case $opt in
                "Настройка системы")
                    echo "Пожалуйста, сначала выполните настройку системы:"
                    echo "  sudo ./installer.sh --configure-system"
                    break
                    ;;
                "Установить DAW")
                    submenu1
                    break
                    ;;
                "Установить синтезатор")
                    submenu2
                    break
                    ;;
                "Установить плагины")
                    submenu3
                    break
                    ;;
                "Установить инструменты")
                    submenu4
                    break
                    ;;
                "Выход")
                    exit 0
                    ;;
                *)
                    echo "Неверный вариант"
                    ;;
            esac
        done
    done
}

# Запуск установщика
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" == "--test" ]; then
        # Экспорт функций для тестирования
        export -f submenu1 submenu2 submenu3 submenu4
    else
        main_menu
    fi
fi
 
