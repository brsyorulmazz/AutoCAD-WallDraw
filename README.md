# AutoCAD Advanced Wall Drawing Tool

An automated AutoLISP tool for AutoCAD to streamline **architectural wall drafting**. This script allows you to draw walls with thickness, justification, and endcaps in a single workflow, supporting both linear and curved segments.

---

## Features
- **One-Key Toggle within Command:** Seamlessly switch between **Line** and **Arc** modes while drawing (press `A` for Arc, `L` for Line).
- **Dynamic Justification:** Align walls to the **Left, Center, or Right** of your cursor path.
- **Custom Endcaps:** Automatically closes wall ends with a specific **Extension (Endcap)** length that supports any architectural system.
- **Smart Loop Detection:** Automatically detects closed shapes (like a room) to omit unnecessary endcaps and create clean inner/outer boundaries.

---

## Installation

### 1. Save the Script
Download `WallDraw.lsp` and save it to a secure folder on your computer (e.g., `C:\AutoCAD_Tools\`).

### 2. Add to Startup Suite (Auto-Load)
To ensure the tool is available every time you open a new drawing:
1. Type `APPLOAD` in the command line and press **Enter**.
2. Click the **Contents...** button under the **Startup Suite** (briefcase icon).
3. Click **Add...**, select your `WallDraw.lsp` file, and close the windows.

---

## Commands
- `WALLDRAW`: Start the drafting process. 
  - Before the first point, use:
    - `T`: Define **Thickness**.
    - `E`: Define **Endcap** extension.
    - `J`: Define **Justification**.
  - During drafting, use:
    - `A`: Switch to **Arc** mode.
    - `L`: Switch back to **Line** mode.
    - `C`: **Close** the loop.

---

## Context
In architectural drafting, creating walls with thickness and proper caps is a repetitive task involving multiple `OFFSET` and `TRIM` operations. This tool automates the manual setup, allowing architects to focus on spatial design rather than technical drafting steps. It provides the fluid experience of professional plugins with the added benefit of native arc support.

---

### Author
**Barış Yorulmaz** 
Architecture Student @ Middle East Technical University (METU)

### License
This project is licensed under the **MIT License**.
