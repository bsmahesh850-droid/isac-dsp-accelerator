# High-Performance 6G ISAC DSP Datapath Accelerator

An RTL implementation of an Integrated Sensing and Communication (ISAC) baseband and radar signal processing datapath, built with Verilog and standardized around the AMBA AXI-Stream protocol.

---

## 🏗️ System Architecture & Data Flow

Incoming raw In-phase/Quadrature (I/Q) radio frequency samples stream through a multi-stage hardware pipeline optimized for high throughput and low latency:

```text
[ Raw I/Q ADC Stream ] 
         │
         ▼
[ Dual AXI-Stream FIR Filters ] (High-frequency radar clutter & noise suppression)
         │
         ▼
[ Radix-2 FFT Butterfly Engine ] (Frequency-domain OFDM transformation)
         │
         ▼
[ Pipelined CORDIC Processor ] (Cartesian-to-Polar coordinate conversion)
         │
         ▼
[ Processed Magnitude & Phase Output ]
