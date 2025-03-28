#!/usr/bin/env bats

setup() {
    export TEMP_DIR=$(mktemp -d)
    export HOME="$TEMP_DIR"
    export LIMITS_FILE="$TEMP_DIR/limits.conf"
    
    # Создаем тестовую структуру папок
    mkdir -p "$TEMP_DIR/synth/vital"
    touch "$TEMP_DIR/synth/vital/vital"
    touch "$TEMP_DIR/synth/vital/Vital.vst3"
    
    # Копируем скрипт во временную директорию
    cp installer.sh "$TEMP_DIR/"
    chmod +x "$TEMP_DIR/installer.sh"
}

teardown() {
    rm -rf "$TEMP_DIR"
}

@test "Конфигурация системы требует прав root" {
    run "$TEMP_DIR/installer.sh" --configure-system
    [ "$status" -eq 1 ]
    [[ "$output" == *"Пожалуйста, запустите"* ]]
}

@test "Конфигурация системы устанавливает аудио лимиты" {
    function whoami() { echo "root"; }
    export -f whoami
    
    run bash -c "LIMITS_FILE='$LIMITS_FILE' '$TEMP_DIR/installer.sh' --configure-system"
    [ "$status" -eq 0 ]
    grep -q "@audio - rtprio 95" "$LIMITS_FILE"
    grep -q "@audio - memlock unlimited" "$LIMITS_FILE"
}

@test "Конфигурация обнаруживает существующие лимиты" {
    function whoami() { echo "root"; }
    export -f whoami
    
    echo "@audio - rtprio 95" > "$LIMITS_FILE"
    echo "@audio - memlock unlimited" >> "$LIMITS_FILE"
    
    run bash -c "LIMITS_FILE='$LIMITS_FILE' '$TEMP_DIR/installer.sh' --configure-system"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Лимиты для аудио уже существуют"* ]]
}

@test "Меню DAW устанавливает Bitwig" {
    function yay() { echo "yay $@"; }
    function zenity() { echo "zenity $@"; }
    export -f yay zenity
    
    run bash -c "
        cd '$TEMP_DIR'
        source '$TEMP_DIR/installer.sh' --test
        submenu1 <<< \$'1\n6'
    "
    echo "$output"  # Для отладки
    [[ "$output" == *"yay -S --noconfirm bitwig-studio"* ]]
    [[ "$output" == *"zenity --notification --text=Bitwig-studio установлен"* ]]
}

@test "Меню синтезаторов устанавливает Vital" {
    function yay() { echo "yay $@"; }
    function zenity() { echo "zenity $@"; }
    function cp() { echo "cp $@"; }
    export -f yay zenity cp
    
    run bash -c "
        cd '$TEMP_DIR'
        source '$TEMP_DIR/installer.sh' --test
        submenu2 <<< \$'1\n3'
    "
    echo "$output"  # Для отладки
    [[ "$output" == *"yay -S --noconfirm vital-synth"* ]]
    [[ "$output" == *"cp -vR ./synth/vital/vital $HOME/.clap/"* ]]
    [[ "$output" == *"cp -vR ./synth/vital/Vital.vst3 $HOME/.vst3/"* ]]
    [[ "$output" == *"zenity --notification --text=Vital установлен"* ]]
}

@test "Установка плагинов Calf" {
    function sudo() { echo "sudo $@"; }
    function zenity() { echo "zenity $@"; }
    export -f sudo zenity
    
    run bash -c "
        cd '$TEMP_DIR'
        source '$TEMP_DIR/installer.sh' --test
        submenu3 <<< \$'1\n4'
    "
    echo "$output"  # Для отладки
    [[ "$output" == *"sudo pacman -S --noconfirm calf"* ]]
    [[ "$output" == *"zenity --notification --text=Плагины Calf установлены"* ]]
}

@test "Создаются директории для плагинов" {
    function zenity() { :; }
    export -f zenity
    
    run bash -c "
        cd '$TEMP_DIR'
        source '$TEMP_DIR/installer.sh' --test
        submenu3 <<< \$'2\n4'
    "
    [ -d "$TEMP_DIR/.vst" ]
}

@test "Скрипт отказывается работать от root в обычном режиме" {
    function whoami() { echo "root"; }
    export -f whoami
    
    run "$TEMP_DIR/installer.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"от обычного пользователя"* ]]
}
