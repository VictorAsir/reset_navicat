# reset_navicat

Used to reset the trial period of Navicat Premium, for macOS systems. The script cleans up the relevant hash files and preferences to achieve the purpose of unlimited trial. The script contains strict error handling and clear log output, suitable for technical learning purposes. Please note that the use of such scripts may violate the software license agreement and is for learning and research purposes only.

Assumptions and adaptations:
The script assumes that Navicat is installed in the default path /Applications/Navicat Premium.app. If the user installs it in a different path, you need to modify APP_PATH.
The cleanup logic for Navicat 16 is based on assumptions (new versions may store hash files in subdirectories). If the actual version behaves differently, you can further adjust the find parameters or paths.
How to use:
Save the script as reset_navicat.sh.
Give execution permission: chmod +x reset_navicat.sh.
Run the script: ./reset_navicat.sh.
The script will automatically detect the Navicat version and perform the corresponding cleanup operations.

假设与适配：
脚本假设 Navicat 安装在默认路径 /Applications/Navicat Premium.app。如果用户安装在其他路径，需修改 APP_PATH。
针对 Navicat 16 的清理逻辑基于假设（新版本可能在子目录存储哈希文件）。如果实际版本行为不同，可进一步调整 find 参数或路径。
使用方法：
保存脚本为 reset_navicat.sh。
赋予执行权限：chmod +x reset_navicat.sh。
运行脚本：./reset_navicat.sh。
脚本会自动检测 Navicat 版本并执行相应的清理操作。
