# 韩语罗马字布局

Windows、macOS 和 Linux 的「输入设置 → 输入方案」中，选择韩语后可把「韩语布局」从默认的「两套式」改为「罗马字」。正在组字时切换布局，会在本次组字结束后生效。移动端保留该偏好，但仍使用两套式键面和规则。

键位参考文镜的现代韩语罗马字码表，不是语音转写或自动纠音。声母 ㅇ 必须显式输入 `x`，如 `xa → 아`；单独输入 `a` 得到 `ㅏ`。尾音按字母本身拼写，不按实际发音改写。

| 输入 | 结果 | 说明 |
| --- | --- | --- |
| `han`、`hangug`、`hangeul` | 한、한국、한글 | 自动组合音节，稳定的前缀逐步上屏 |
| `geo`、`geu`、`gwa` | 거、그、과 | `eo` 为 ㅓ，`eu` 为 ㅡ，`wa` 为 ㅘ |
| `gui`、`gwi` | 긔、귀 | `ui` 为 ㅢ，`wi` 为 ㅟ |
| `Ga`、`Da`、`Ba`、`Ja`、`Sa` | 까、따、빠、짜、싸 | Shift 加 `g/d/b/j/s` 输入紧音 |
| `bang`、`bangi`、`bangxi` | 방、반기、방이 | `ng` 后接元音时拆成 `n+g`；保留尾音 ㅇ 时，下一音节用 `x` 起头 |
| `dalg`、`xeobs` | 닭、없 | 复合收音仍按组成字母输入 |

元音支持 `a ae ya yae eo e yeo ye o wa wae oe yo u wo we wi yu eu ui i`，`eui` 也表示 ㅢ。别名包括 `l=r`、`y=i`、`w=u`、`f=p`、`c=ch`，以及 `ia/iae/ieo/ie/io/iu/ua/uae/uo/ue`。多字母编码取最长匹配，因此 `ui` 与 `wi` 的含义不同。

退格每次删除一个**尚未上屏的原始拉丁按键**，重新解释剩下的拼写：`bang → ban` 显示 `방 → 반`，`gwa → gw` 显示 `과 → 구`。这与文镜按韩文字母部件删除的方式不同。已上屏的前缀交由应用编辑。

汉字转换沿用现有韩语入口，只转换正在组字的单音节。标点沿用韩语半角规则。未定义的 `q/v/z`（含大写）会连同当前韩文直接上屏，保留字母原貌。

映射来源：[rime-mungyeong 固定版本的码表](https://github.com/rimeinn/rime-mungyeong/blob/34c1b1437824e1e619e7429fb5f461dc7e754939/mungyeong_romaja.dict.yaml)。该文件声明 public domain；本实现复用水杉的韩文组合规则，不引入 Rime 或 Lua。
