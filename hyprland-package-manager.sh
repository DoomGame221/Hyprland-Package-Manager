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
REPO_URL="https://github.com/DoomGame221/Hyprland-Package-Manager.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/hyprland-package-manager-update"

# ฟังก์ชันแสดงหัวข้อ
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Arch Linux Hyprland Package Manager              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ฟังก์ชันแสดงเมนูหลัก (ปรับปรุงโดยเพิ่มตัวเลือกอัพเดทสคริปต์)
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

# ฟังก์ชันอัพเดทสคริปต์จาก GitHub
update_script() {
    show_header
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   อัพเดทสคริปต์จาก GitHub                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}กำลังตรวจสอบการอัพเดทจาก ${REPO_URL}...${NC}"

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

    # สร้างไดเรกทอรีชั่วคราวสำหรับ clone repository
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    # Clone repository จาก GitHub
    if git clone "$REPO_URL" "$TEMP_DIR"; then
        echo -e "${GREEN}✓ ดึงข้อมูลจาก GitHub สำเร็จ${NC}"
    else
        echo -e "${RED}✗ ไม่สามารถ clone repository จาก ${REPO_URL} ได้${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # คัดลอกไฟล์สคริปต์ใหม่ไปยังตำแหน่งเดิม (สมมติว่าไฟล์ชื่อ `hyprland-package-manager.sh`)
    if cp "$TEMP_DIR/hyprland-package-manager.sh" "$SCRIPT_DIR/"; then
        echo -e "${GREEN}✓ อัพเดทสคริปต์เสร็จสมบูรณ์!${NC}"
        chmod +x "$SCRIPT_DIR/hyprland-package-manager.sh"
    else
        echo -e "${RED}✗ เกิดข้อผิดพลาดในการคัดลอกสคริปต์${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
        read
        return
    fi

    # ล้างไดเรกทอรีชั่วคราว
    rm -rf "$TEMP_DIR"

    echo -e "${YELLOW}สคริปต์ได้รับการอัพเดทแล้ว กรุณาเรียกใช้สคริปต์ใหม่เพื่อใช้เวอร์ชันล่าสุด${NC}"
    echo -e "${CYAN}กด Enter เพื่อกลับสู่เมนูหลัก...${NC}"
    read
}

# (ส่วนที่เหลือของโค้ดเดิม เช่น install_recommended_packages, show_installed_packages, remove_package, setup_ufw, check_installed_packages, update_system, check_yay คงเดิม)

# ฟังก์ชันหลัก (ปรับปรุงโดยเพิ่มตัวเลือก 5)
main() {
    # ตรวจสอบสิทธิ์ root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}กรุณาอย่าเรียกใช้สคริปต์นี้ด้วยสิทธิ์ root${NC}"
        exit 1
    fi
    
    # ตรวจสอบ yay
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

# เรียกใช้ฟังก์ชันหลัก
main