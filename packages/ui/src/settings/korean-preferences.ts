/** 韩语实体键盘布局；缺字段或未来版本的未知值回退到两套式。 */
export type KoreanPreferences = {
  layout?: "dubeolsik" | "romaja";
};

export function resolveKoreanLayout(preferences?: KoreanPreferences) {
  return preferences?.layout === "romaja" ? "romaja" : "dubeolsik";
}

export const koreanLayoutDescription =
  "两套式按 두벌식 键位；罗马字用 x 输入声母 ㅇ（xa → 아，hangug → 한국），Shift+G/D/B/J/S 输入紧音，退格删除一个未上屏的拉丁按键，标点为半角";
