#!/bin/bash

echo -e "\033[0;32m>>> 正在部署 RL Swarm 节点（Linux + CPU 模式）\033[0m"

# 安装依赖
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip curl

# 创建并激活虚拟环境
python3 -m venv venv
source venv/bin/activate

# 克隆项目
if [ ! -d "rl-swarm" ]; then
    git clone https://github.com/gensyn-ai/rl-swarm.git
else
    echo -e "\033[0;34m>>> 已有 rl-swarm 文件夹，跳过克隆\033[0m"
fi

cd rl-swarm

# 安装依赖
pip install --upgrade pip
pip install -r requirements.txt

# 修复 protobuf 版本冲突（强制降级）
pip install "protobuf<5.28.0,>=3.12.2" --force-reinstall

# 检测 CPU 核心数
CPU_CORES=$(nproc)
DEFAULT_THREADS=$((CPU_CORES / 2))
echo ""
echo -e "\033[0;36m检测到你有 $CPU_CORES 个 CPU 核心。\033[0m"
read -p "请输入你想分配给 RL Swarm 的线程数（建议：$DEFAULT_THREADS）: " USER_THREADS

# 如果用户没输入，就用默认值
if [ -z "$USER_THREADS" ]; then
    USER_THREADS=$DEFAULT_THREADS
fi

export OMP_NUM_THREADS=$USER_THREADS
echo -e "\033[0;33m已设置 OMP_NUM_THREADS=$OMP_NUM_THREADS\033[0m"

# 启动节点
if [ -f "./run_rl_swarm.sh" ]; then
    chmod +x run_rl_swarm.sh
    ./run_rl_swarm.sh
else
    python main.py
fi

# 检测 modal-login 实际端口（如已启用）
sleep 3
NEXT_PORT=$(ss -tuln | grep LISTEN | grep 127.0.0.1 | grep -E ':30[0-9]{2}' | awk '{print $5}' | cut -d':' -f2 | sort | uniq)

if [ -n "$NEXT_PORT" ]; then
    SERVER_IP=$(curl -s ifconfig.me)
    echo ""
    echo -e "\033[0;32m>>> 检测到 modal-login 页面监听在端口：$NEXT_PORT\033[0m"
    echo -e "\033[0;36m>>> 请在本地电脑运行以下命令建立访问通道：\033[0m"
    echo -e "\033[1mssh -L $NEXT_PORT:localhost:$NEXT_PORT root@$SERVER_IP\033[0m"
    echo -e "\033[0;36m>>> 然后在浏览器访问：\033[1mhttp://localhost:$NEXT_PORT\033[0m"
    echo ""
else
    echo -e "\033[0;31m>>> 未检测到监听中的 modal-login 端口，请确认 yarn dev 是否成功启动\033[0m"
fi
