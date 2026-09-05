import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export const DEFAULT_THEME_COLOR: string = '#51A775';
export const PINK_THEME_COLOR: string = '#FB7299';
export const BLUE_THEME_COLOR: string = '#00AEEC';

export function normalizeThemeColor(value: string): string {
  const normalized: string = value.trim().toUpperCase();
  const withHash: string = normalized.startsWith('#') ? normalized : `#${normalized}`;
  return /^#[0-9A-F]{6}$/.test(withHash) ? withHash : '';
}

export async function applySystemTheme(context: common.UIAbilityContext, value: string): Promise<void> {
  const color: string = normalizeThemeColor(value) || DEFAULT_THEME_COLOR;
  const mainWindow: window.Window = await window.getLastWindow(context);
  await mainWindow.setWindowSystemBarProperties({
    statusBarColor: color,
    statusBarContentColor: '#FFFFFF',
    navigationBarColor: color,
    navigationBarContentColor: '#FFFFFF'
  });
}
