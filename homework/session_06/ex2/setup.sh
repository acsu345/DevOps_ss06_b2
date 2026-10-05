#!/bin/bash
# ==============================================================================
# Script: setup.sh
# Mo ta: Cau hinh phan quyen Nhom devops-admin va sudoers khong dung mat khau cho deployer
# Duong dan: homework/session_06/ex2/setup.sh
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== [BUOC 1] TAO NHOM DEVOPS-ADMIN VA USER DEPLOYER ===${NC}"

# 1. Tao nhom devops-admin neu chua ton tai
if ! getent group devops-admin > /dev/null 2>&1; then
    sudo groupadd devops-admin
    echo "[OK] Da tao group 'devops-admin'"
else
    echo "[INFO] Group 'devops-admin' da ton tai."
fi

# 2. Tao user deployer neu chua ton tai
if ! id -u deployer > /dev/null 2>&1; then
    sudo useradd -m -s /bin/bash -g devops-admin deployer
    echo "[OK] Da tao user 'deployer' thuoc primary group 'devops-admin'"
else
    sudo usermod -aG devops-admin deployer
    echo "[OK] Da them user 'deployer' va group 'devops-admin'"
fi

echo -e "\n${BLUE}=== [BUOC 2] CAU HINH SUDOERS VOI QUY TAC NOPASSWD FOR SYSTEMCTL ===${NC}"

# Su dụng thu muc /etc/sudoers.d/ de dam bao tinh modular va an toan (Best Practice)
SUDOERS_FILE="/etc/sudoers.d/devops-admin"

# Tim duong dan chinh xac cua systemctl Tren he thong (/usr/bin/systemctl hoac /bin/systemctl)
SYSTEMCTL_PATH=$(which systemctl || echo "/usr/bin/systemctl")

RULE_CONTENT="%devops-admin ALL=(ALL) NOPASSWD: ${SYSTEMCTL_PATH} start *, ${SYSTEMCTL_PATH} stop *, ${SYSTEMCTL_PATH} restart *, ${SYSTEMCTL_PATH} status *"

# Ghi quy tac va kiem tra cu phap an toan voi visudo -c
echo "$RULE_CONTENT" | sudo tee $SUDOERS_FILE > /dev/null
sudo chmod 0440 $SUDOERS_FILE

if sudo visudo -c > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] Cau hinh sudoers hop le va da duoc kieu tra an toan (visudo -c)!${NC}"
else
    echo -e "${YELLOW}[ERROR] Cau hinh sudoers khong hop le! Dang khoi phục...${NC}"
    sudo rm -f $SUDOERS_FILE
    exit 1
fi

echo -e "\n${BLUE}=== [BUOC 3] KIEM TRA DAC QUYEN USER DEPLOYER ===${NC}"
sudo -u deployer sudo -l

echo -e "\n${BLUE}=== [BUOC 4] THUC HANH RESTART DICH VU CRON ===${NC}"
sudo -u deployer sudo ${SYSTEMCTL_PATH} restart cron
echo -e "${GREEN}[OK] Lanh 'sudo systemctl restart cron' chay thanh cong khong can mat khau!${NC}"

echo -e "\n${GREEN}=== HOAN THANH HOAN HAO BÀI 2! ===${NC}"
