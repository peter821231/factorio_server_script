# 🚀 Factorio 伺服器與模組自動管理工具 / Factorio Server & Mod Auto Manager

本專案包含兩個實用的 Bash 腳本，可協助你自動化管理 Factorio 專用伺服器與 Mods 的下載、更新、備份與還原。  
This project includes two Bash scripts for automating Factorio headless server and mods management: download, update, backup and restore.

---

## 📁 專案內容 / Project Structure

| 檔案 | 說明 | Description |
|------|------|-------------|
| `update_mod.sh` | 管理與更新 Mods，包括備份與還原功能 | Manage and update mods, includes backup/restore |
| `update_server.sh` | 自動檢查與更新 Factorio Headless Server | Auto-check and update Factorio headless server |

---

## ⚙️ 安裝需求 / Requirements

請先安裝以下套件：  
Install required dependencies:

```bash
sudo apt install jq curl wget
```

---

## 📦 update_mod.sh 使用方式 / Mod Manager Usage

```bash
./update_mod.sh [options]
```

### 🔧 可用選項 / Options

| 選項 | 說明 | Option | Description |
|------|------|--------|-------------|
| `-s`, `--server-settings PATH` | `server-settings.json` 路徑 | Path to `server-settings.json` |
| `-u`, `--username USERNAME` | Factorio 帳號 | Factorio account |
| `-t`, `--token TOKEN` | Factorio token | Factorio token |
| `--mod-host SERVER` | Mods 主機（預設：mods.factorio.com） | Mods server (default: mods.factorio.com) |
| `-p`, `--path PATH` | Factorio 安裝根目錄 | Factorio base install path |
| `-m`, `--mods-path PATH` | Mods 資料夾路徑 | Mods folder path |
| `-e`, `--exclude-list FILE` | 排除更新的 mods 清單 | Exclude list file |
| `-n`, `--dry-run` | 模擬更新，不下載 | Check only, no download |
| `--backup` | 備份 mods 資料夾 | Backup mods folder |
| `--restore FILE` | 從備份檔還原 mods | Restore mods from backup file |
| `-h`, `--help` | 顯示說明 | Show help |

### 📌 使用範例 / Examples

#### 更新模組 / Update Mods
```bash
./update_mod.sh
```

#### 檢查是否需要更新模組(Dry Run) / Check Update Mods (Dry Run)
```bash
./update_mod.sh --dry-run
```

#### 備份模組 / Backup Mods
```bash
./update_mod.sh --backup
```

#### 還原備份模組 /Restore Mods From Backup
```bash
./update_mod.sh --restore /home/peter/factorio/mod_backup/mods_backup_20240529_120301.tar.gz
```

---

## 🔧 update_server.sh 使用方式 / Server Update Usage

```bash
./update_server.sh
```

此腳本會自動比對你目前的伺服器版本與官方最新版本，若有更新可選擇是否下載並覆蓋原伺服器。  
This script compares your local headless server version with the official latest version and lets you update automatically.

### 📝 更新流程 / Update Flow

1. 查詢官方版本與本地版本 / Check the latest official version and the local installed version
2. 若不同，詢問是否下載 / If they differ, prompt whether to download the update
3. 自動下載並解壓縮至安裝路徑 / Automatically download and extract to the installation directory

---

## 📁 建議資料夾結構 / Suggested Directory Layout

```
factorio/
├── mods/
│   └── *.zip
├── mod_backup/
│   └── mods_backup_*.tar.gz
├── data/
│   └── server-settings.json
├── bin/
│   └── x64/factorio
├── update_mod.sh
└── update_server.sh
```

---

## 🔐 server-settings.json 格式 / Format

若未手動輸入帳號與 token，請建立 `server-settings.json` 檔案，格式如下：  
If you don’t specify credentials directly, create `server-settings.json` like:

```json
{
  "username": "your_factorio_username",
  "token": "your_factorio_token"
}
```

---

## 🧠 注意事項 / Notes

- `update_mod.sh` 會排除內建模組 `base`、`space-age` 等，以避免破壞遊戲結構。 / update_mod.sh excludes built-in mods such as base, space-age, etc., to prevent breaking the game's core structure.
- 備份與還原僅針對 `mods/` 資料夾，不處理其他資料。 / The backup and restore functions only apply to the mods/ folder. Other data will not be included or restored.
- `update_server.sh` 會覆蓋安裝路徑中的可執行檔與資料，請事先備份。 / update_server.sh will overwrite executable files and data in the installation directory. Please back up your server before proceeding.

---
