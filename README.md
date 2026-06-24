# 基於 RISC-V 核心之可自訂數位倒數計時器

本專案實作於 Digilent Basys 3 開發板，結合開源 PicoRV32 處理器核心與自訂的外圍硬體電路（匯流排、計時器、顯示控制器），透過 C 語言編寫的有限狀態機（FSM）與 Memory-Mapped I/O（MMIO）機制，建構出一個具備高互動性的硬體倒數計時系統。

## 1. 專題名稱
基於 RISC-V 核心之可自訂數位倒數計時器

## 2. 使用開發板
* Digilent Basys 3 FPGA 開發板 (Xilinx Artix-7 XC7A35T-1CPG236C)

## 3. 使用工具版本
* **EDA 工具**: Xilinx Vivado 2025.2（負責硬體合成、佈線與 Bitstream 產生）
* **硬體核心**: PicoRV32 v1.0 (RV32I 處理器架構)
* **韌體編譯工具鏈**: xPack GNU RISC-V Embedded GCC v15.2.0-1 (riscv-none-elf-gcc)
* **映像檔轉換工具**: GNU objcopy

## 4. 專案資料夾結構
專案實體根目錄位於電腦的 `C:\Users\User\Desktop\riscv`。所有設計原始碼、約束檔與編譯韌體皆存放於該目錄下，結構如下：

```text
C:\Users\User\Desktop\riscv
├───basys3.xdc
│   top.v
│   timer.v
│   controller.v
│   main.c
│   main.elf
│   firmware.mem
│
└───picorv32
    └───picorv32.v

```

## 5. 如何產生 bitstream

1. 開啟 **Xilinx Vivado 2025.2** 並建立一個針對 Artix-7 XC7A35T-1CPG236C 晶片的全新專案。
2. 將 `C:\Users\User\Desktop\riscv` 底下的所有 Verilog 原始檔（`top.v`, `picorv32.v`, `timer.v`, `controller.v`）以及 `basys3.xdc` 約束檔匯入專案。
3. 將編譯好的記憶體映像檔 `C:\Users\User\Desktop\riscvfirmware.mem` 作為設計來源一同併入專案資料夾，以供 BRAM 在合成時自動初始化讀取。
4. 在 Vivado 的 Sources 介面中，選取 `top.v` 並點擊右鍵手動選擇 **Set as Top**（設為頂層模組），確保硬體管腳約束與實體腳位正確對接。
5. 點擊左側 Flow Navigator 中的 **Run Synthesis** 執行硬體邏輯合成，並檢查是否有語法或架構上的錯誤。
6. 合成通過後，點擊 **Run Implementation** 執行實體晶片佈線與時序驗證。
7. 最後點擊 **Generate Bitstream**，系統將於專案目錄下轉譯並打包出開發板可接收的位元流檔案（`.bit`）。

## 6. 如何載入或修改 RISC-V 程式

1. 進入 `C:\Users\User\Desktop\riscv` 目錄，根據需求修改 `main.c` 中的控制邏輯或狀態機（如自訂暫停行為或 BCD 轉換演算法）。
2. 開啟終端機，呼叫 **xPack GNU RISC-V Embedded GCC v15.2.0-1** 交叉編譯工具鏈，將高階 C 語言原始碼編譯為處理器架構專屬的機器碼（ELF 格式檔案）。
3. 使用隨附的 `objcopy` 工具，將機器碼中的二進位純代碼區段精準剝離，轉譯並輸出為符合 Verilog 區塊記憶體格式的純文字十六進位映像檔 `firmware.mem`。
4. 當重新執行 Vivado 的硬體合成（Run Synthesis）時，編譯引擎會自動抓取最新的 `firmware.mem` 並將其配置實體映射寫入 FPGA 內部的區塊記憶體（BRAM）中，實現軟體韌體更新。

## 7. 如何燒錄到 FPGA 開發板

1. 使用 Micro-USB 連接線將 Basys 3 開發板與電腦連接，並將板上的電源開關切換至 ON。
2. 在 Vivado 主介面下方點擊開啟 **Hardware Manager**。
3. 點擊頂部橫幅的 **Open Target** 並選取 **Auto Connect**，軟體將自動識別並與板載的 FPGA 晶片建立連線。
4. 識別成功後，選取晶片並點擊右鍵選擇 **Program Device**。
5. 在跳出的對話框中確認 Bitstream 檔案路徑指向先前產生的 `.bit` 檔，隨後點擊 **Program** 執行覆蓋寫入。

## 8. 如何操作與測試

* **系統啟動與初始化**: 燒錄完成後，頂層硬體模組會自動發送一次開機自動重置（Power-On Reset）訊號，系統直接跳過手動重置流程並即時讀取下方的 slide switch 開關。
* **自訂初始時間**: 透過撥動板上 16 個switch `SW[15:0]` 輸入目標秒數（採用二進位編碼），此時上方的七段顯示器會即時將其轉換為十進位制並顯示（最高支援 9999 秒）。
* **啟動計時**: 按下板上中央按鈕 `BTNC`，系統切換至 Countdown 狀態，七段顯示器上的秒數開始每秒精準遞減。
* **暫停計時**: 在倒數過程中再次按下 `BTNC`，狀態機會切換至 Pause 狀態並凍結當前殘餘時間，此時七段顯示器會規律閃爍，且外部的指撥開關輸入在此狀態下會被主動屏蔽，不影響殘餘數值；再次按下 `BTNC` 則繼續不突跳倒數。
* **手動重置**: 在任何運作狀態下按下下方按鈕 `BTND`，系統將立刻中斷當前任務，恢復至初始設定模式並動態重新載入指撥開關上的數值。
* **歸零警示**: 當時間計時歸零（顯示 `0000`）時，系統切換至 Done 狀態，板上 16 顆 LED 燈與七段顯示器會同步觸發規律閃爍警示，直到使用者按下 `BTND` 執行重置。

## 9. 已知問題

* **暫停時基不連貫**: 在倒數計時暫停後恢復倒數時，由於硬體的 1Hz 計時器在背景依然保持持續運作，導致在恢復計時的瞬間，首次變時可能會產生微小的時間精度不穩定（可能一按下便扣減或延遲至一秒才扣減）。未來規劃透過提升內部計時器的時基解析度至微秒級別來優化精度。
* **輪詢迴圈功耗代價**: 目前 1Hz 的硬體計時狀態抓取與按鈕偵測完全依賴 CPU 執行 Polling（輪詢）迴圈，導致處理器長時間處於滿載運作，增加了整體電路的運作功耗。未來改善方向為整合硬體 Interrupt（中斷）控制器，使處理器在閒置時進入低功耗休眠。

## 10. 外部來源與授權說明

* **PicoRV32 核心**: 本專案採用的開源 RISC-V 處理器核心來自 YosysHQ 團隊之 [PicoRV32 專案](https://github.com/YosysHQ/picorv32) (v1.0 版本)，該部分原始碼遵循 **ISC License** 授權。專案內保留其原始處理器架構，僅透過外部系統匯流排與自研硬體進行整合。
* **xPack GNU RISC-V Embedded GCC**: 專案韌體開發採用由 xPack 社群維護的[riscv-none-elf-gcc-xpack](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack) (v15.2.0-1 版本)，其組件基於 **GNU GPL** 等開源授權協議。
* **技術文件與參考來源**:
* [1] Kai-Chieh Hsu, *Verilog Programming Basic*, Course Slides, CS10014, National Yang Ming Chiao Tung University. URL: [people.cs.nycu.edu.tw/~ttyeh/course/2026_Spring/CS10014/slide/verilog.pdf](https://people.cs.nycu.edu.tw/~ttyeh/course/2026_Spring/CS10014/slide/verilog.pdf)
* [2] Digilent, *Basys 3 Reference Manual*, 官方硬體規格說明文件. URL: [digilent.com/reference/programmable-logic/basys-3/reference-manual](https://digilent.com/reference/programmable-logic/basys-3/reference-manual)
* [3] YosysHQ, *PicoRV32 - A Size-Optimized RISC-V CPU*. URL: [github.com/YosysHQ/picorv32](https://github.com/YosysHQ/picorv32)
* [4] xpack-dev-tools, *riscv-none-elf-gcc-xpack - A standalone, cross-platform binary distribution of GNU RISC-V Embedded GCC,*. URL: [github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack)
* [5] FPGA 開發社群相關設計討論與腳位例化慣例 (Reddit /r/FPGA). URL: [reddit.com/r/FPGA/comments/t6cvkk](https://www.reddit.com/r/FPGA/comments/t6cvkk/basys3_is_this_the_correct_way_to_instantiate_a/)
* [6] Avinashabroy, *Basys3 七段顯示器控制教學實作專案*. URL: [https://github.com/Avinashabroy/Seven_Segment_Display_FPGA_Project](https://github.com/Avinashabroy/Seven_Segment_Display_FPGA_Project)
