#!/bin/bash

# Script สำหรับเข้า BIOS/UEFI บน Arch Linux Hyprland
# ใช้งาน: ./bios.sh

# ฟังก์ชันแสดงข้อความสี
print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

# ตรวจสอบว่าเป็น UEFI system หรือไม่
check_uefi() {
    if [ -d "/sys/firmware/efi" ]; then
        return 0  # UEFI system
    else
        return 1  # Legacy BIOS system
    fi
}

# ฟังก์ชันเตรียมระบบก่อนรีสตาร์ท
prepare_system() {
    print_info "กำลังเตรียมระบบสำหรับการรีสตาร์ท..."
    
    # Sync filesystem เพื่อความปลอดภัย
    print_info "กำลัง sync filesystem..."
    sync
    
    # หยุด services ที่ไม่จำเป็นเพื่อเร่งกระบวนการ shutdown
    print_info "กำลังหยุด services ที่ไม่จำเป็น..."
    systemctl --no-block stop bluetooth.service 2>/dev/null || true
    systemctl --no-block stop NetworkManager.service 2>/dev/null || true
    
    # ให้เวลาระบบเตรียมตัว
    sleep 1
}

# ฟังก์ชันเตรียมระบบก่อนปิดเครื่อง
prepare_shutdown() {
    print_info "กำลังเตรียมระบบสำหรับการปิดเครื่อง..."
    
    # บันทึกข้อมูลทั้งหมด
    print_info "กำลัง sync filesystem..."
    sync
    
    # หยุด services ที่สำคัญเพื่อเตรียมปิดเครื่อง
    print_info "กำลังหยุด services..."
    systemctl --no-block stop bluetooth.service 2>/dev/null || true
    systemctl --no-block stop NetworkManager.service 2>/dev/null || true
    systemctl --no-block stop cups.service 2>/dev/null || true
    
    # ให้เวลาระบบเตรียมตัว
    sleep 2
}

# ฟังก์ชันปิดเครื่องแล้วไป BIOS เมื่อเปิดใหม่
shutdown_to_bios() {
    print_info "กำลังปิดเครื่องและตั้งค่าให้เข้า BIOS เมื่อเปิดเครื่องใหม่..."
    
    # เตรียมระบบ
    prepare_shutdown
    
    if check_uefi; then
        print_info "ตรวจพบระบบ UEFI - กำลังตั้งค่าให้เข้า UEFI setup"
        
        # ตั้งค่า UEFI ให้เข้า firmware setup ครั้งถัดไป
        if command -v efibootmgr >/dev/null 2>&1; then
            print_info "ใช้ efibootmgr เพื่อตั้งค่า BootNext เป็น firmware setup"
            efibootmgr --bootnext FFFF 2>/dev/null || true
            
            # ตั้งค่าเพิ่มเติมให้แน่ใจ
            print_info "กำลังตั้งค่า EFI variables..."
            
            # บางระบบต้องการตั้งค่า EFI variable โดยตรง
            if [ -w "/sys/firmware/efi/efivars" ]; then
                echo -ne '\x07\x00\x00\x00\x01' > /sys/firmware/efi/efivars/OsIndicationsSupported-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null || true
            fi
        fi
        
        print_success "ตั้งค่า UEFI เรียบร้อยแล้ว"
        
    else
        print_warning "ตรวจพบระบบ Legacy BIOS"
        print_info "สำหรับระบบ Legacy BIOS จะต้องกด Del, F2, F12 หรือ Esc ด้วยตนเองขณะเปิดเครื่อง"
    fi
    
    print_info "กำลังปิดเครื่อง..."
    print_warning "เมื่อเปิดเครื่องใหม่ ระบบจะเข้าหน้า BIOS/UEFI โดยอัตโนมัติ"
    
    # รอสักครู่เพื่อให้ผู้ใช้อ่านข้อความ
    sleep 2
    
    # ปิดเครื่องแบบ graceful shutdown
    sync
    systemctl poweroff --no-block
    
    # ถ้า systemctl ไม่ทำงาน ใช้วิธีอื่น
    sleep 3
    /sbin/poweroff || /sbin/halt -p
}

# ฟังก์ชันปิดเครื่องแล้วไป BIOS แบบ Force
shutdown_to_bios_force() {
    print_info "กำลัง Force shutdown และตั้งค่าให้เข้า BIOS เมื่อเปิดเครื่องใหม่..."
    
    # บันทึกข้อมูลด่วน
    sync
    
    if check_uefi; then
        print_info "ตรวจพบระบบ UEFI - กำลังตั้งค่าให้เข้า UEFI setup"
        
        # ตั้งค่า UEFI ให้เข้า firmware setup
        if command -v efibootmgr >/dev/null 2>&1; then
            efibootmgr --bootnext FFFF 2>/dev/null || true
        fi
        
        # ตั้งค่า EFI variables ถ้าเป็นไปได้
        if [ -w "/sys/firmware/efi/efivars" ]; then
            echo -ne '\x07\x00\x00\x00\x01' > /sys/firmware/efi/efivars/OsIndicationsSupported-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null || true
        fi
        
    else
        print_warning "ตรวจพบระบบ Legacy BIOS"
        print_info "กรุณากด Del, F2, F12 หรือ Esc ขณะเปิดเครื่องใหม่"
    fi
    
    print_info "กำลัง force shutdown..."
    
    # เปิดใช้งาน SysRq
    echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true
    
    # Force shutdown ทันที
    {
        echo o > /proc/sysrq-trigger
    } 2>/dev/null || {
        /sbin/poweroff -f
    } || {
        systemctl poweroff --force --no-block
    }
    
    # ถ้าถึงจุดนี้แสดงว่า shutdown ไม่สำเร็จ
    sleep 2
    print_error "ไม่สามารถ force shutdown ได้ กรุณาลองปิดเครื่องด้วยตนเอง"
}

# ฟังก์ชันเข้า BIOS/UEFI แบบ Force
enter_bios_force() {
    print_info "กำลัง Force reboot เข้า BIOS/UEFI..."
    sync  # Sync ข้อมูลก่อน force reboot
    
    if check_uefi; then
        print_info "ตรวจพบระบบ UEFI - กำลัง force reboot เข้า UEFI setup"
        
        # ตั้งค่า UEFI ให้เข้า firmware setup
        if command -v efibootmgr >/dev/null 2>&1; then
            print_info "ใช้ efibootmgr เพื่อตั้งค่า boot-next"
            efibootmgr --bootnext FFFF 2>/dev/null || true
        fi
        
        # เปิดใช้งาน SysRq ก่อนใช้งาน
        echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true
        
        # Force reboot ทันทีด้วยวิธีต่างๆ
        print_info "กำลัง force reboot..."
        {
            echo b > /proc/sysrq-trigger
        } 2>/dev/null || {
            /sbin/reboot -f
        } || {
            systemctl reboot --firmware-setup --force --no-block
        }
        
    else
        print_warning "ตรวจพบระบบ Legacy BIOS - กำลัง force reboot"
        print_info "กรุณากด Del, F2, F12 หรือ Esc ขณะบูต"
        
        # เปิดใช้งาน SysRq
        echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true
        
        # Force reboot ทันที
        print_info "กำลัง force reboot..."
        {
            echo b > /proc/sysrq-trigger
        } 2>/dev/null || {
            /sbin/reboot -f
        } || {
            systemctl reboot --force --no-block
        }
    fi
    
    # ถ้าถึงจุดนี้แสดงว่า reboot ไม่สำเร็จ
    sleep 2
    print_error "ไม่สามารถ force reboot ได้ กรุณาลองรีสตาร์ทด้วยตนเอง"
}

# ฟังก์ชันเข้า BIOS/UEFI แบบปกติ
enter_bios() {
    print_info "กำลังเตรียมเข้า BIOS/UEFI..."
    
    # เตรียมระบบก่อน
    prepare_system
    
    if check_uefi; then
        print_info "ตรวจพบระบบ UEFI"
        print_info "กำลังตั้งค่าให้เข้า UEFI firmware setup..."
        
        # วิธีที่ 1: ใช้ efibootmgr (มีประสิทธิภาพดีที่สุด)
        if command -v efibootmgr >/dev/null 2>&1; then
            print_info "ใช้ efibootmgr เพื่อเข้า UEFI setup"
            efibootmgr --bootnext FFFF 2>/dev/null || true
            sleep 1
            # Force reboot โดยไม่รอ services
            print_info "กำลัง reboot เข้า UEFI..."
            systemctl reboot --firmware-setup --force --no-block || /sbin/reboot -f
        else
            print_info "ใช้ systemctl reboot --firmware-setup"
            # ถ้าไม่มี efibootmgr ใช้วิธีเดิม แต่ force
            systemctl reboot --firmware-setup --force --no-block
        fi
        
    else
        print_warning "ตรวจพบระบบ Legacy BIOS"
        print_info "สำหรับระบบ Legacy BIOS กรุณากด Del, F2, F12 หรือ Esc ขณะบูต"
        print_info "กำลัง reboot..."
        
        # Force reboot สำหรับ Legacy BIOS
        systemctl reboot --force --no-block || /sbin/reboot -f
    fi
    
    # รอสักครู่แล้วแสดงข้อความ
    sleep 3
    print_warning "หากระบบยังไม่รีสตาร์ท กรุณากด Ctrl+Alt+Delete หรือใช้ปุ่ม Power"
}

# ฟังก์ชันหลัก
main() {
    echo "=============================================="
    echo "    BIOS/UEFI Entry Script สำหรับ Arch Linux"
    echo "=============================================="
    echo
    
    # ตรวจสอบว่าเป็น root หรือไม่
    if [ "$EUID" -ne 0 ]; then
        print_info "ต้องการสิทธิ์ root เพื่อเข้า BIOS/UEFI"
        print_info "กำลังเข้าสู่ root mode..."
        
        # หา path เต็มของ script
        SCRIPT_PATH="$(realpath "$0")"
        
        # ตรวจสอบว่าไฟล์ script มีอยู่หรือไม่
        if [ ! -f "$SCRIPT_PATH" ]; then
            print_error "ไม่พบไฟล์ script: $SCRIPT_PATH"
            exit 1
        fi
        
        # เรียกใช้ script ด้วย sudo โดยใช้ path เต็ม
        exec sudo "$SCRIPT_PATH" "$@"
    fi
    
    print_info "ทำงานในฐานะ root แล้ว"
    echo
    
    # แสดงข้อมูลระบบ
    print_info "ข้อมูลระบบ:"
    echo "  - Hostname: $(cat /etc/hostname 2>/dev/null || echo 'Unknown')"
    echo "  - Kernel: $(uname -r)"
    echo "  - Uptime: $(cat /proc/uptime | awk '{printf "up %.0f minutes", $1/60}')"
    
    if check_uefi; then
        echo "  - Firmware: UEFI"
        if command -v efibootmgr >/dev/null 2>&1; then
            echo "  - efibootmgr: ✓ Available"
        else
            echo "  - efibootmgr: ✗ Not installed"
        fi
    else
        echo "  - Firmware: Legacy BIOS"
    fi
    echo
    
    # แสดงตัวเลือก
    print_warning "⚠️  การดำเนินการนี้จะทำให้ระบบรีสตาร์ทหรือปิดเครื่องทันที!"
    echo
    echo "เลือกการดำเนินการ:"
    echo "1) รีสตาร์ทเข้า BIOS (ปกติ)"
    echo "2) รีสตาร์ทเข้า BIOS (Force reboot)"
    echo "3) ปิดเครื่องแล้วเข้า BIOS เมื่อเปิดใหม่ (ปกติ)"
    echo "4) ปิดเครื่องแล้วเข้า BIOS เมื่อเปิดใหม่ (Force shutdown)"
    echo "5) ยกเลิก"
    echo
    read -p "เลือก (1/2/3/4/5): " -n 1 -r choice
    echo
    echo
    
    case $choice in
        1)
            print_info "เลือกรีสตาร์ทปกติ - เริ่มกระบวนการเข้า BIOS/UEFI..."
            ACTION_TYPE="reboot_normal"
            ;;
        2)
            print_info "เลือก Force Reboot - เริ่มกระบวนการเข้า BIOS/UEFI..."
            ACTION_TYPE="reboot_force"
            ;;
        3)
            print_info "เลือกปิดเครื่องปกติ - เริ่มกระบวนการตั้งค่าเข้า BIOS/UEFI..."
            ACTION_TYPE="shutdown_normal"
            ;;
        4)
            print_info "เลือก Force Shutdown - เริ่มกระบวนการตั้งค่าเข้า BIOS/UEFI..."
            ACTION_TYPE="shutdown_force"
            ;;
        5)
            print_info "ยกเลิกการเข้า BIOS/UEFI"
            echo "ขอบคุณที่ใช้งาน!"
            exit 0
            ;;
        *)
            print_info "ตัวเลือกไม่ถูกต้อง - ยกเลิกการทำงาน"
            echo "ขอบคุณที่ใช้งาน!"
            exit 0
            ;;
    esac
    
    # นับถอยหลัง
    for i in {5..1}; do
        case $ACTION_TYPE in
            "reboot_normal")
                print_warning "รีสตาร์ทใน $i วินาที... (กด Ctrl+C เพื่อยกเลิก)"
                ;;
            "reboot_force")
                print_warning "Force reboot ใน $i วินาที... (กด Ctrl+C เพื่อยกเลิก)"
                ;;
            "shutdown_normal")
                print_warning "ปิดเครื่องใน $i วินาที... (กด Ctrl+C เพื่อยกเลิก)"
                ;;
            "shutdown_force")
                print_warning "Force shutdown ใน $i วินาที... (กด Ctrl+C เพื่อยกเลิก)"
                ;;
        esac
        sleep 1
    done
    
    echo
    # ดำเนินการตามที่เลือก
    case $ACTION_TYPE in
        "reboot_normal")
            enter_bios
            ;;
        "reboot_force")
            enter_bios_force
            ;;
        "shutdown_normal")
            shutdown_to_bios
            ;;
        "shutdown_force")
            shutdown_to_bios_force
            ;;
    esac
}

# เรียกใช้ฟังก์ชันหลัก
main "$@"