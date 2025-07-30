#!/bin/bash

# Arch Linux Hyprland Package Manager Script
# ใช้สำหรับจัดการแพ็กเกจใน Arch Linux Hyprland และอัพเดทสคริปต์จาก GitHub

# สีสำหรับการแสดงผล
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# URL ของ repository บน GitHub (เปลี่ยนเป็น URL ของ repository ของคุณ)
REPO_URL="https://github.com/YourUsername/YourRepo.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
TEMP_DIR="/tmp/hyprland-package-manager-update"
BACKUP_DIR="$SCRIPT_DIR/backup"
VERSION_FILE="VERSION"

# ฟังก์ชันแสดงหัวข้อ
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Arch Linux Hyprland Package Manager              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ฟังก์ชันแสดงเมนูหลัก
show_main_menu() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        เมนูหลัก                             ║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ 1.${NC} ติดตั้งแพ็กเกจที่แนะนำสำหรับ Hyprland                   ${BLUE}║${NC}"
    echo -e "${YELLOW}║ 2.${NC} ลบแพ็กเกจ (แสดงรายการให้เลือก)                        ${BLUE}║${NC}"
    echo -e "${PURPLE}║ 3.${NC} ตรวจสอบแพ็กเกจที่ติดตั้งแล้ว                          ${BLUE}║${NC}"
    echo -e "${CYAN}║ 4.${NC} อัพเดทระบบ                                             ${BLUE}║${NC}"
    echo -e "${CYAN}║ 5.${NC} อัพเดทสคริปต์จาก GitHub                               ${BLUE}║${NC}"
    echo -e "${RED}║ 0.${NC} ออกจากโปรแกรม                                          ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# รายการแพ็กเกจที่แนะนำ
declare -A recommended_packages=(
    ["hyprland"]="Hyprland Wayland Compositor"
    ["waybar"]="Highly customizable Wayland bar"
    ["wofi"]="Launcher/menu program for wlroots"
    ["mako"]="Lightweight notification daemon"
    ["swww"]="Efficient animated wallpaper daemon"
    ["grimblast-git"]="Screenshot tool for Hyprland"
    ["wl-clipboard"]="Command-line copy/paste utilities"
    ["pipewire"]="Low-latency audio/video router"
    ["pipewire-pulse"]="PulseAudio replacement"
    ["wireplumber"]="Session manager for PipeWire"
    ["kitty"]="Fast, feature-rich, GPU based terminal"
    ["thunar"]="Modern file manager"
    ["firefox"]="Web browser"
    ["code"]="Visual Studio Code"
    ["git"]="Version control system"
    ["neovim"]="Hyperextensible Vim-based text editor"
    ["htop"]="Interactive process viewer"
    ["fastfetch"]="System information tool"
    ["fish"]="Smart and user-friendly command line shell"
    ["starship"]="Cross-shell prompt"
    ["exa"]="Modern replacement for ls"
    ["bat"]="Cat clone with syntax highlighting"
    ["ripgrep"]="Line-oriented search tool"
    ["fd"]="Simple, fast alternative to find"
    ["fzf"]="Command-line fuzzy finder"
    ["zoxide"]="Smarter cd command"
    ["btop"]="Resource monitor"
    ["polkit-gnome"]="Authentication agent"
    ["xdg-desktop-portal-hyprland"]="Desktop portal for Hyprland"
    ["qt5-wayland"]="Qt5 Wayland support"
    ["qt6-wayland"]="Qt6 Wayland support"
    ["ufw"]="Uncomplicated Firewall - Easy to use firewall"
)

# ฟังก์ชันติดตั้งแพ็กเกจที่แนะนำ
install_recommended_packages() {
    show_header
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 ติดตั้งแพ็กเกจที่แนะนำ                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}แพ็กเกจที่จะติดตั้ง:${NC}"
    echo ""
    
    local counter=1
    for package in "${!recommended_packages[@]}"; do
        printf "${CYAN}%2d.${NC} %-25s - %s\n" $counter "$package" "${recommended_packages[$package]}"
        ((counter++))
    done
    
    echo ""
    echo -e "${YELLOW}คุณต้องการติดตั้งแพ็กเกจเหล่านี้หรือไม่? (y/N): ${NC}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}กำลังติดตั้งแพ็กเกจ...${NC}"
        
        package_list=""
        for package in "${!recommended_packages[@]}"; do
            package_list="$package_list $package"
        done
        
        if yay -S --needed --noconfirm $package_list; then
            echo -e "${GREEN}✓ ติดตั้งแพ็กเกจเสร็จสมบูรณ์!${NC}"
            setup_ufw
        else
            echo -e "${RED}✗ เกิดข้อผิดพลาดในการติดตั้งบางแพ็กเกจ${NC}"
        fi
    else
        echo -e "${YELLOW}ยกเลิกการติดตั้ง${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
    read
}

# ฟังก์ชันแสดงรายการแพ็กเกจที่ติดตั้งแล้ว
show_installed_packages() {
    show_header
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                ลบแพ็กเกจที่ติดตั้งแล้ว                        ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}กำลังโหลดรายการแพ็กเกจที่ติดตั้งแล้ว...${NC}"
    
    mapfile -t installed_packages < <(pacman -Qqe | sort)
    
    if [ ${#installed_packages[@]} -eq 0 ]; then
        echo -e "${RED}ไม่พบแพ็กเกจที่ติดตั้งแล้ว${NC}"
        echo ""
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi
    
    local page_size=20
    local total_packages=${#installed_packages[@]}
    local current_page=0
    local max_page=$(( (total_packages - 1) / page_size ))
    
    while true; do
        clear
        show_header
        echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                ลบแพ็กเกจที่ติดตั้งแล้ว                        ║${NC}"
        echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        local start_index=$((current_page * page_size))
        local end_index=$((start_index + page_size - 1))
        
        if [ $end_index -ge $total_packages ]; then
            end_index=$((total_packages - 1))
        fi
        
        echo -e "${YELLOW}แพ็กเกจที่ติดตั้งแล้ว (หน้า $((current_page + 1))/$((max_page + 1))):${NC}"
        echo -e "${YELLOW}แสดง $((start_index + 1))-$((end_index + 1)) จาก $total_packages แพ็กเกจ${NC}"
        echo ""
        
        for ((i=start_index; i<=end_index; i++)); do
            local display_num=$((i + 1))
            echo -e "${CYAN}$display_num.${NC} ${installed_packages[$i]}"
        done
        
        echo ""
        echo -e "${GREEN}คำสั่ง:${NC}"
        echo -e "${CYAN}• พิมพ์ตัวเลข${NC} - เลือกแพ็กเกจที่จะลบ"
        echo -e "${CYAN}• n${NC} - หน้าถัดไป"
        echo -e "${CYAN}• p${NC} - หน้าก่อนหน้า"
        echo -e "${CYAN}• q${NC} - กลับสู่เมนูหลัก"
        echo ""
        echo -e "${YELLOW}เลือกคำสั่ง: ${NC}"
        read -r choice
        
        case $choice in
            "q"|"Q")
                return
                ;;
            "n"|"N")
                if [ $current_page -lt $max_page ]; then
                    ((current_page++))
                else
                    echo -e "${RED}อยู่หน้าสุดท้ายแล้ว${NC}"
                    sleep 1
                fi
                ;;
            "p"|"P")
                if [ $current_page -gt 0 ]; then
                    ((current_page--))
                else
                    echo -e "${RED}อยู่หน้าแรกแล้ว${NC}"
                    sleep 1
                fi
                ;;
            *)
                if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le $total_packages ]; then
                    local selected_package="${installed_packages[$((choice - 1))]}"
                    remove_package "$selected_package"
                    mapfile -t installed_packages < <(pacman -Qqe | sort)
                    total_packages=${#installed_packages[@]}
                    max_page=$(( (total_packages - 1) / page_size ))
                    if [ $current_page -gt $max_page ]; then
                        current_page=$max_page
                    fi
                else
                    echo -e "${RED}ตัวเลือกไม่ถูกต้อง${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# ฟังก์ชันลบแพ็กเกจ
remove_package() {
    local package_name="$1"
    
    echo ""
    echo -e "${RED}คุณต้องการลบแพ็กเกจ '${package_name}' หรือไม่?${NC}"
    echo -e "${YELLOW}(Y/n): ${NC}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$|^$ ]]; then
        echo -e "${YELLOW}กำลังลบแพ็กเกจ '${package_name}'...${NC}"
        
        if sudo pacman -Rs --noconfirm "$package_name"; then
            echo -e "${GREEN}✓ ลบแพ็กเกจ '${package_name}' เสร็จสมบูรณ์!${NC}"
        else
            echo -e "${RED}✗ เกิดข้อผิดพลาดในการลบแพ็กเกจ '${package_name}'${NC}"
        fi
    else
        echo -e "${YELLOW}ยกเลิกการลบแพ็กเกจ${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}กด Enter เพื่อดำเนินการต่อ...${NC}"
    read
}

# ฟังก์ชันตั้งค่า UFW Firewall
setup_ufw() {
    if pacman -Qi ufw &>/dev/null; then
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                   ตั้งค่า UFW Firewall                       ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${YELLOW}กำลังตั้งค่า UFW Firewall...${NC}"
        
        if sudo systemctl enable ufw; then
            echo -e "${GREEN}✓ เปิดใช้งาน UFW service แล้ว${NC}"
        else
            echo -e "${RED}✗ ไม่สามารถเปิดใช้งาน UFW service ได้${NC}"
            return
        fi
        
        echo -e "${YELLOW}กำลังตั้งค่า default rules...${NC}"
        sudo ufw --force default deny incoming
        sudo ufw --force default allow outgoing
        
        echo -e "${YELLOW}กำลังเปิดใช้งาน UFW...${NC}"
        if sudo ufw --force enable; then
            echo -e "${GREEN}✓ เปิดใช้งาน UFW Firewall เรียบร้อยแล้ว${NC}"
            echo ""
            echo -e "${CYAN}การตั้งค่า UFW ปัจจุบัน:${NC}"
            echo -e "${YELLOW}• Default incoming: DENY${NC}"
            echo -e "${YELLOW}• Default outgoing: ALLOW${NC}"
            echo -e "${YELLOW}• Status: ACTIVE${NC}"
            echo ""
            echo -e "${BLUE}หากต้องการเปิด port เพิ่มเติม ใช้คำสั่ง:${NC}"
            echo -e "${CYAN}sudo ufw allow [port]${NC}"
            echo -e "${CYAN}ตัวอย่าง: sudo ufw allow 22 (สำหรับ SSH)${NC}"
        else
            echo -e "${RED}✗ ไม่สามารถเปิดใช้งาน UFW ได้${NC}"
        fi
    fi
}

# ฟังก์ชันตรวจสอบแพ็กเกจที่ติดตั้งแล้ว
check_installed_packages() {
    show_header
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              ตรวจสอบแพ็กเกจที่ติดตั้งแล้ว                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}สถิติแพ็กเกจ:${NC}"
    echo -e "${CYAN}• แพ็กเกจทั้งหมด:${NC} $(pacman -Q | wc -l)"
    echo -e "${CYAN}• แพ็กเกจที่ติดตั้งจาก repository:${NC} $(pacman -Qn | wc -l)"
    echo -e "${CYAN}• แพ็กเกจจาก AUR:${NC} $(pacman -Qm | wc -l)"
    echo -e "${CYAN}• แพ็กเกจที่ติดตั้งโดยผู้ใช้:${NC} $(pacman -Qe | wc -l)"
    echo -e "${CYAN}• แพ็กเกจ dependencies:${NC} $(pacman -Qd | wc -l)"
    echo ""
    
    if pacman -Qi ufw &>/dev/null; then
        echo -e "${YELLOW}สถานะ UFW Firewall:${NC}"
        if sudo ufw status | grep -q "Status: active"; then
            echo -e "${GREEN}✓ UFW: เปิดใช้งานอยู่${NC}"
        else
            echo -e "${RED}✗ UFW: ปิดใช้งาน${NC}"
        fi
        echo ""
    fi
    
    echo -e "${YELLOW}แพ็กเกจที่แนะนำและสถานะการติดตั้ง:${NC}"
    echo ""
    
    for package in "${!recommended_packages[@]}"; do
        if pacman -Qi "$package" &>/dev/null; then
            echo -e "${GREEN}✓${NC} $package - ${recommended_packages[$package]}"
        else
            echo -e "${RED}✗${NC} $package - ${recommended_packages[$package]}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
    read
}

# ฟังก์ชันอัพเดทระบบ
update_system() {
    show_header
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    อัพเดทระบบ                               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}กำลังตรวจสอบการอัพเดท...${NC}"
    
    if yay -Syu --noconfirm; then
        echo ""
        echo -e "${GREEN}✓ อัพเดทระบบเสร็จสมบูรณ์!${NC}"
    else
        echo ""
        echo -e "${RED}✗ เกิดข้อผิดพลาดในการอัพเดทระบบ${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
    read
}

# ฟังก์ชันตรวจสอบและติดตั้ง yay
check_yay() {
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ yay พร้อมใช้งานแล้ว${NC}"
        return
    fi

    echo -e "${YELLOW}ไม่พบ 'yay' AUR helper กำลังติดตั้ง...${NC}"

    # ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
    if ! ping -c 1 archlinux.org &> /dev/null; then
        echo -e "${RED}✗ ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อ${NC}"
        exit 1
    fi

    # ตรวจสอบและติดตั้งแพ็กเกจที่จำเป็น
    echo -e "${YELLOW}กำลังตรวจสอบและติดตั้งแพ็กเกจที่จำเป็นสำหรับ yay...${NC}"
    if ! sudo pacman -S --needed --noconfirm git base-devel go; then
        echo -e "${RED}✗ ไม่สามารถติดตั้งแพ็กเกจที่จำเป็น (git, base-devel, go) ได้${NC}"
        exit 1
    fi

    # ล้างไดเรกทอรีชั่วคราวก่อน
    rm -rf /tmp/yay
    mkdir -p /tmp/yay

    # Clone repository ของ yay
    echo -e "${YELLOW}กำลัง clone repository ของ yay...${NC}"
    if ! git clone https://aur.archlinux.org/yay.git /tmp/yay; then
        echo -e "${RED}✗ ไม่สามารถ clone repository ของ yay ได้ กรุณาตรวจสอบ URL หรือการเชื่อมต่อ${NC}"
        rm -rf /tmp/yay
        exit 1
    fi

    # เข้าไปในไดเรกทอรีและ build yay
    cd /tmp/yay || { echo -e "${RED}✗ ไม่สามารถเข้าสู่ไดเรกทอรี /tmp/yay${NC}"; exit 1; }
    echo -e "${YELLOW}กำลัง build และติดตั้ง yay...${NC}"
    if ! makepkg -si --noconfirm 2> /tmp/yay-install.log; then
        echo -e "${RED}✗ ไม่สามารถ build หรือติดตั้ง yay ได้ ดูข้อผิดพลาดใน /tmp/yay-install.log${NC}"
        cd -
        rm -rf /tmp/yay
        exit 1
    fi

    # กลับไปยังไดเรกทอรีเดิมและล้างไฟล์
    cd -
    rm -rf /tmp/yay

    # ตรวจสอบว่า yay ติดตั้งสำเร็จ
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ ติดตั้ง yay เสร็จสมบูรณ์!${NC}"
    else
        echo -e "${RED}✗ ไม่สามารถติดตั้ง yay ได้ ดูข้อผิดพลาดใน /tmp/yay-install.log${NC}"
        exit 1
    fi
}

# ฟังก์ชันอัพเดทสคริปต์จาก GitHub
update_script() {
    show_header
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   อัพเดทสคริปต์จาก GitHub                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}คุณต้องการอัพเดทสคริปต์จาก ${REPO_URL} หรือไม่? (y/N): ${NC}"
    read -r confirm

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}ยกเลิกการอัพเดทสคริปต์${NC}"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    echo -e "${YELLOW}กำลังตรวจสอบการอัพเดท...${NC}"

    # ตรวจสอบว่า git ติดตั้งแล้วหรือไม่
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ ไม่พบ 'git' ในระบบ${NC}"
        echo -e "${YELLOW}กำลังติดตั้ง git...${NC}"
        if sudo pacman -S --noconfirm git; then
            echo -e "${GREEN}✓ ติดตั้ง git เสร็จสมบูรณ์!${NC}"
        else
            echo -e "${RED}✗ ไม่สามารถติดตั้ง git ได้${NC}"
            echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
            read
            return
        fi
    fi

    # สร้างไดเรกทอรีสำรอง
    mkdir -p "$BACKUP_DIR"

    # สำรองไฟล์สคริปต์ปัจจุบัน
    local timestamp=$(date +%Y%m%d_%H%M%S)
    if cp "$SCRIPT_DIR/$SCRIPT_NAME" "$BACKUP_DIR/${SCRIPT_NAME}.bak.$timestamp"; then
        echo -e "${GREEN}✓ สำรองไฟล์สคริปต์ไปที่ ${BACKUP_DIR}/${SCRIPT_NAME}.bak.${timestamp}${NC}"
    else
        echo -e "${RED}✗ ไม่สามารถสำรองไฟล์สคริปต์ได้${NC}"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # ล้างและสร้างไดเรกทอรีชั่วคราว
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    # Clone repository
    if git clone --depth 1 "$REPO_URL" "$TEMP_DIR"; then
        echo -e "${GREEN}✓ ดึงข้อมูลจาก GitHub สำเร็จ${NC}"
    else
        echo -e "${RED}✗ ไม่สามารถ clone repository จาก ${REPO_URL} ได้${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # ตรวจสอบว่าไฟล์สคริปต์มีอยู่ใน repository
    if [ ! -f "$TEMP_DIR/$SCRIPT_NAME" ]; then
        echo -e "${RED}✗ ไม่พบไฟล์ ${SCRIPT_NAME} ใน repository${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # ตรวจสอบเวอร์ชัน (ถ้ามีไฟล์ VERSION)
    local current_version="unknown"
    local remote_version="unknown"
    if [ -f "$SCRIPT_DIR/$VERSION_FILE" ]; then
        current_version=$(cat "$SCRIPT_DIR/$VERSION_FILE")
    fi
    if [ -f "$TEMP_DIR/$VERSION_FILE" ]; then
        remote_version=$(cat "$TEMP_DIR/$VERSION_FILE")
    fi

    echo -e "${CYAN}เวอร์ชันปัจจุบัน: $current_version${NC}"
    echo -e "${CYAN}เวอร์ชันจาก GitHub: $remote_version${NC}"

    if [ "$current_version" = "$remote_version" ] && [ "$current_version" != "unknown" ]; then
        echo -e "${YELLOW}สคริปต์เป็นเวอร์ชันล่าสุดแล้ว${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # คัดลอกไฟล์สคริปต์ใหม่
    if cp "$TEMP_DIR/$SCRIPT_NAME" "$SCRIPT_DIR/$SCRIPT_NAME"; then
        echo -e "${GREEN}✓ อัพเดทสคริปต์เสร็จสมบูรณ์!${NC}"
        chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
        # คัดลอกไฟล์ VERSION ถ้ามี
        if [ -f "$TEMP_DIR/$VERSION_FILE" ]; then
            cp "$TEMP_DIR/$VERSION_FILE" "$SCRIPT_DIR/$VERSION_FILE"
        fi
    else
        echo -e "${RED}✗ เกิดข้อผิดพลาดในการคัดลอกสคริปต์${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # ล้างไดเรกทอรีชั่วคราว
    rm -rf "$TEMP_DIR"

    echo -e "${YELLOW}สคริปต์ได้รับการอัพเดทเป็นเวอร์ชัน $remote_version${NC}"
    echo -e "${CYAN}กรุณาเรียกใช้สคริปต์ใหม่เพื่อใช้เวอร์ชันล่าสุด${NC}"
    echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
    read
}

# ฟังก์ชันหลัก
main() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}กรุณาอย่าเรียกใช้สคริปต์นี้ด้วยสิทธิ์ root${NC}"
        exit 1
    fi
    
    check_yay
    
    while true; do
        show_header
        show_main_menu
        
        echo -e -n "${YELLOW}เลือกตัวเลือก (0-5): ${NC}"
        read -r choice
        
        case $choice in
            1)
                install_recommended_packages
                ;;
            2)
                show_installed_packages
                ;;
            3)
                check_installed_packages
                ;;
            4)
                update_system
                ;;
            5)
                update_script
                ;;
            0)
                echo -e "${GREEN}ขอบคุณที่ใช้บริการ!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}ตัวเลือกไม่ถูกต้อง กรุณาเลือกใหม่${NC}"
                sleep 2
                ;;
        esac
    done
}

main
