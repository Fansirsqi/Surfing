#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "请设置以 Root 用户运行"
    exit 1
fi

BASE_URL="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
TEMP_FILE="/data/local/tmp/mihomo_latest.gz"
TEMP_DIR="/data/local/tmp/mihomo_update"
CORE_PATH="/data/adb/box_bll/bin/clash"
PANEL_DIR="/data/adb/box_bll/panel/"
META_DIR="${PANEL_DIR}Meta/"
META_URL="https://github.com/metacubex/metacubexd/archive/gh-pages.zip"
METAA_URL="https://api.github.com/repos/metacubex/metacubexd/releases/latest"
YACD_DIR="${PANEL_DIR}Yacd/"
YACD_URL="https://github.com/MetaCubeX/yacd/archive/gh-pages.zip"
YACDD_URL="https://api.github.com/repos/MetaCubeX/Yacd-meta/releases/latest"
TEMP_FILE="/data/local/tmp/ui_update.zip"
TEMP_DIR="/data/local/tmp/ui_update"
DB_PATH="/data/adb/box_bll/clash/cache.db"
SERVICE_SCRIPT="/data/adb/box_bll/scripts/box.service"
CLASH_RELOAD_URL="http://127.0.0.1:9090/configs"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
GEODATA_URL="https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest"
GEOIP_PATH="/data/adb/box_bll/clash/GeoIP.dat"
GEOSITE_PATH="/data/adb/box_bll/clash/GeoSite.dat"
RULES_PATH="/data/adb/box_bll/clash/rule/"
RULES_URL_PREFIX="https://raw.githubusercontent.com/MoGuangYu/rules/main/Home/"
RULES=("YouTube.yaml" "TikTok.yaml" "Telegram.yaml" "OpenAI.yaml" "Netflix.yaml" "Microsoft.yaml" "Google.yaml" "Facebook.yaml" "Discord.yaml" "Apple.yaml")

show_menu() {
    while true; do
        echo "=========="
        echo "请选择操作："
        echo ""
        echo "1. 清空数据库缓存"
        echo "2. 更新 Web 面板"
        echo "3. 更新 Geo 数据库"
        echo "4. 更新 Apps 路由规则"
        echo "5. 更新 Clash 核心"
        echo "6. Telegram 讨论组"
        echo "7. Web 面板访问入口"
        echo "8. 重载配置"
        echo "9. Exit"
        read -r choice

        case $choice in
            1)
                clear_cache
                ;;
            2)
                update_web_panel
                ;;
            3)
                update_geo_database
                ;;
            4)
                update_rules
                ;;
            5)
                update_core
                ;;
            6)
                open_telegram_group
                ;;
            7)
                show_web_panel_menu
                ;;
            8)
                reload_configuration
                ;;
            9)
                exit 0
                ;;
            *)
                echo "无效的选择！"
                ;;
        esac
    done

}

clear_cache() {
    echo "↴"
    echo "此操作会清空数据库缓存，是否清除？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "操作取消！"
        return
    fi
    if [ -f "$DB_PATH" ]; then
        rm "$DB_PATH"
        echo "已清空数据库缓存✓"
        touch "$DB_PATH"
    else
        echo "数据库文件不存在..."
        touch "$DB_PATH"
        echo "已创建新的空数据库文件"
    fi
    echo "重启模块服务中..."
    touch "/data/adb/modules/Surfing/disable"
    sleep 1.5
    rm -f "/data/adb/modules/Surfing/disable"
    sleep 1.5
    for i in 5 4 3 2 1
    do
        #echo "..."
        sleep 1
    done
    $SERVICE_SCRIPT status
    echo "ok"
    echo ""

}

update_geo_database() {
    echo "↴"
    echo "正在从 GitHub 获取中..."
    geo_release=$(curl -s "$GEODATA_URL")
    geo_version=$(echo "$geo_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$geo_version" ]; then
        echo "无法获取最新版本信息："
        echo "1h 内请求次数过多 / 网络不稳定"
        show_menu
    fi   
    echo "获取成功！"
    echo "当前最新版本号: $geo_version"
    echo "是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "操作取消！"
        return
    fi
    if [ -f "/data/adb/box_bll/clash/geosite.dat" ]; then
        rm "/data/adb/box_bll/clash/geosite.dat"
    fi
    if [ -f "/data/adb/box_bll/clash/geoip.dat" ]; then
        rm "/data/adb/box_bll/clash/geoip.dat"
    fi
    echo "正在更新中..."
    curl -o "$GEOIP_PATH" -L "$GEOIP_URL"
    if [ $? -ne 0 ]; then
        echo "下载 geoip.dat 失败！"
        return
    fi
    curl -o "$GEOSITE_PATH" -L "$GEOSITE_URL"
    if [ $? -ne 0 ]; then
        echo "下载 geosite.dat 失败！"
        return
    fi
    echo "更新成功✓"
    echo "建议重载配置..."
    chown root:net_admin "$GEOIP_PATH" "$GEOSITE_PATH"
    chmod 0644 "$GEOIP_PATH" "$GEOSITE_PATH"
    if [ $? -ne 0 ]; then
        echo "设置文件权限失败！"
        return
    fi
    for i in 3 2 1
    do
        echo "..."
        sleep 1
    done

}

update_rules() {
    echo "↴"
    echo "此操作会从 GitHub 拉取最新全部规则，是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ];then
        echo "操作取消！"
        return
    fi
    if [ ! -d "$RULES_PATH" ];then
        echo "目录不存在，正在创建..."
        mkdir -p "$RULES_PATH"
        if [ $? -ne 0 ];then
            echo "创建规则目录失败，请检查权限！"
            return
        fi
    fi
    echo "正在更新中..."
    for rule in "${RULES[@]}"; do
        curl -o "${RULES_PATH}${rule}" -L "${RULES_URL_PREFIX}${rule}"
        if [ $? -ne 0 ];then
            echo "下载 ${rule} 失败！"
            return
        fi
    done
    echo "更新成功✓"
    echo "建议重载配置..."
    chown -R root:net_admin "$RULES_PATH"
    find "$RULES_PATH" -type d -exec chmod 0755 {} \;
    find "$RULES_PATH" -type f -exec chmod 0666 {} \;
    if [ $? -ne 0 ];then
        echo "设置文件权限失败！"
        return
    fi
    for i in 3 2 1
    do
        echo "..."
        sleep 1
    done

}

show_web_panel_menu() {
    while true; do
        echo "↴"
        echo "选择图形面板："
        echo "1. HTTPS Gui Meta"
        echo "2. HTTPS Gui Yacd"
        echo "3. 本地端口 >>> 127.0.0.1:9090/ui"
        echo "4. 返回上一级菜单"
        read -r web_choice
        case $web_choice in
            1)
                echo "↴"
                echo "正在跳转到 Gui Meta..."
                am start -a android.intent.action.VIEW -d "https://metacubex.github.io/metacubexd"
                echo "ok"
                ;;
            2)
                echo "↴"
                echo "正在跳转到 Gui Yacd..."
                am start -a android.intent.action.VIEW -d "https://yacd.metacubex.one/"
                echo "ok"
                ;;
            3)
                echo "↴"
                echo "正在跳转到本地端口..."
                am start -a android.intent.action.VIEW -d "http://127.0.0.1:9090/ui/#/"
                echo "ok"
                ;;
            4)
                return
                ;;
            *)
                echo "无效的选择！"
                ;;
        esac
    done
    for i in 3 2 1
    do
        echo "..."
        sleep 1
    done

}

open_telegram_group() {
    echo "↴"
    echo "正在跳转到 Telegram 聊天组..."
    am start -a android.intent.action.VIEW -d "https://t.me/+vvlXyWYl6HowMTBl"
    echo "ok"

}

update_web_panel() {
    echo "↴"
    echo "正在从 GitHub 获取中..."
    meta_release=$(curl -s "$METAA_URL")
    meta_version=$(echo "$meta_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    yacd_release=$(curl -s "$YACDD_URL")
    yacd_version=$(echo "$yacd_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$meta_version" ] || [ -z "$yacd_version" ]; then
        echo "无法获取最新版本信息："
        echo "1h 内请求次数过多 / 网络不稳定"
        show_menu
    fi 
    echo "获取成功！"
    echo "Meta 当前最新版本号: $meta_version"
    echo "Yacd 当前最新版本号: $yacd_version"
    echo "是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "操作取消！"
        return
    fi   
    echo "↴"
    echo "Update Web panel：Meta"
    if [ ! -d "$META_DIR" ]; then
        echo "目录不存在，正在创建..."
        mkdir -p "$META_DIR"
        if [ $? -ne 0 ]; then
            echo "创建目录失败，请检查权限！"
            return
        fi
    fi
    echo "正在拉取最新的代码..."
    curl -L -o "$TEMP_FILE" "$META_URL"
    if [ $? -eq 0 ]; then
        echo "下载成功，正在效验文件..."
        if [ -s "$TEMP_FILE" ]; then
            echo "文件有效，开始进行更新..."
            unzip -q "$TEMP_FILE" -d "$TEMP_DIR"
            if [ $? -eq 0 ]; then
                rm -rf "${META_DIR:?}"/*
                if [ $? -ne 0 ]; then
                    echo "操作失败，请检查权限！"
                    return
                fi
                mv "$TEMP_DIR/metacubexd-gh-pages/"* "$META_DIR"
                rm -rf "$TEMP_DIR"
                rm "$TEMP_FILE"
                echo "更新成功✓"
                echo ""
            else
                echo "解压失败！"
            fi
        else
            echo "下载的文件为空或无效！"
        fi
    else
        echo "拉取下载失败！"
    fi
    echo "Update Web panel：Yacd"
    if [ ! -d "$YACD_DIR" ]; then
        echo "目录不存在，正在创建..."
        mkdir -p "$YACD_DIR"
        if [ $? -ne 0 ]; then
            echo "创建目录失败，请检查权限！"
            return
        fi
    fi
    echo "正在拉取最新的面板代码..."
    curl -L -o "$TEMP_FILE" "$YACD_URL"
    if [ $? -eq 0 ]; then
        echo "下载成功，正在效验文件..."
        if [ -s "$TEMP_FILE" ]; then
            echo "文件有效，开始进行更新..."
            unzip -q "$TEMP_FILE" -d "$TEMP_DIR"
            if [ $? -eq 0 ]; then
                rm -rf "${YACD_DIR:?}"/*
                if [ $? -ne 0 ]; then
                    echo "操作失败，请检查权限！"
                    return
                fi
                mv "$TEMP_DIR/Yacd-meta-gh-pages/"* "$YACD_DIR"
                rm -rf "$TEMP_DIR"
                rm "$TEMP_FILE"
                echo "更新成功✓"
                echo ""
                echo "建议重载配置..."
            else
                echo "解压失败！"
            fi
        else
            echo "下载的文件为空或无效！"
        fi
    else
        echo "拉取下载失败！"
    fi
    chown -R root:net_admin "$PANEL_DIR"
    find "$PANEL_DIR" -type d -exec chmod 0755 {} \;
    find "$PANEL_DIR" -type f -exec chmod 0666 {} \;
    if [ $? -ne 0 ]; then
        echo "设置文件权限失败！"
        return
    fi
    for i in 3 2 1; do
        echo "..."
        sleep 1
    done

}


reload_configuration() {
    echo "↴"
    echo "重载 Clash 配置..."
    curl -X PUT "$CLASH_RELOAD_URL" -d "{\"path\":\"/data/adb/box_bll/clash/config.yaml\"}"
    $SERVICE_SCRIPT status
    if [ $? -eq 0 ];then
        echo "重载成功✓"
    else
        echo "重载失败！"
    fi
    for i in 3 2 1
    do
        echo "..."
        sleep 1
    done

}

update_core() {
    echo "↴"
    echo "正在从 GitHub 获取中..."
    latest_release=$(curl -s "$BASE_URL")
    latest_version=$(echo "$latest_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$latest_version" ]; then
        echo "无法获取最新版本信息："
        echo "1h 内请求次数过多 / 网络不稳定"
        show_menu
    fi
    download_url="https://github.com/MetaCubeX/mihomo/releases/download/$latest_version/mihomo-android-arm64-v8-${latest_version}.gz"
    echo "获取成功！"
    echo "当前最新版本号: $latest_version"
    echo "是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "操作取消！"
        return
    fi    
    echo "正在下载更新中..."
    curl -L -o "$TEMP_FILE" "$download_url"
    if [ $? -ne 0 ]; then
        echo "下载失败，请检查网络连接和URL！"
        exit 1
    fi
    file_size=$(stat -c%s "$TEMP_FILE")
    if [ "$file_size" -le 100 ]; then
        echo "下载的文件大小异常，请检查下载链接是否正确！"
        exit 1
    fi
    echo "文件有效，开始进行更新..."
    mkdir -p "$TEMP_DIR"
    gunzip -c "$TEMP_FILE" > "$TEMP_DIR/clash"
    if [ $? -ne 0 ]; then
        echo "解压失败，请检查下载的文件！"
        exit 1
    fi
    chown root:net_admin "$TEMP_DIR/clash"
    chmod 0700 "$TEMP_DIR/clash"
    if [ -f "$CORE_PATH" ]; then
        mv "$CORE_PATH" "${CORE_PATH}.bak"
    fi
    mv "$TEMP_DIR/clash" "$CORE_PATH"
    rm -rf "$TEMP_FILE" "$TEMP_DIR"
    echo "更新成功✓"
    echo ""
    echo "重启模块服务中..."
    touch "/data/adb/modules/Surfing/disable"
    sleep 1.5
    rm -f "/data/adb/modules/Surfing/disable"
    sleep 1.5
    for i in 5 4 3 2 1
    do
        #echo "..."
        sleep 1
    done
    $SERVICE_SCRIPT status
    echo "ok"
    echo ""

}

show_menu