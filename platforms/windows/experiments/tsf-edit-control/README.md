# Controlled TSF edit control

This directory contains a small native Win32 editor host for repeatable Windows TSF checks. It builds a `msime-tsf-edit-control` library and a `msime-tsf-edit-control-demo` window that exercise Direct2D/DirectWrite rendering, pre-edit display attributes, candidate positioning, selection, caret movement, soft wrapping, mouse hit testing, and the production TSF service boundary from a controlled editor surface.

It is an experiment and a verification tool, not a product component: it ships in neither the installer nor any package, it does not register the IME, it does not start the production Server, and it does not replace checks in third-party editors. It exists because third-party editors differ in how they drive TSF, so a surface whose behaviour is fully known makes a regression attributable to the TIP rather than to the editor.

It is built with the rest of the platform under `if(WIN32)` and registers no CTest entry — it is driven by hand. Cross-building it confirms that it compiles and links; the interaction it is for happens on Windows.

The source was imported from `MSIME-Windows` commit `345cb87a3822f6ad7013bb29506fe3d856c1931a`.

## 韩语系统输入复现

使用已配置的原生构建目录编译 `msime-tsf-edit-control-demo`。完整输入验收需要先按正常安装流程注册本次构建的 TSF DLL，并运行同一构建的 Server；这个程序不负责安装或注册。

```powershell
cmake --build target/windows-full/x64 --config RelWithDebInfo --target msime-tsf-edit-control-demo
target/windows-full/x64/bin/msime-tsf-edit-control-demo.exe --activate-profile
```

`--activate-profile` 只为当前进程选择已注册的本版本输入源，并核对实际激活的 CLSID 和 profile GUID。窗口切到前台后，可以按 F12 再次选择，避免 Windows 恢复该应用此前的输入源。普通启动不主动切换输入源。默认英文模式下先按 Shift 进入韩语组字。

从 WinUI 设置选择韩语，保留默认两套式，输入 `gksrnr` 应显示 `한국`。点击保存罗马字布局后重新聚焦编辑框，输入 `hang` 应显示 `항`，继续 `ug` 应变为 `한국`；`bang` 后退格应从 `방` 回到 `반`。Escape 取消当前组字。Windows 的汉字键是右 Ctrl：输入 `han` 后按右 Ctrl，再按数字 1，应提交 `韓`。另检查 `xa`、Shift+G 后接 `a`、半角标点及 `q/v/z` 保留。

焦点验收要检查未完成文字留在原框、新框独立组字，以及候选窗跟随当前框。这个实验控件与系统记事本等实际应用须分别记录结果；预编辑或选择汉字通过，不能代替候选定位及跨应用验收。保留当前输入源、布局、构建提交、实际文字和界面截图；失败时不要将整套流程记作通过。
